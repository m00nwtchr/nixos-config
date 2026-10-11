use crate::output::Status;
use netlink_wi::NlSocket;
use nix::ifaddrs::getifaddrs;
use std::{error::Error, fs};

const BOND: &str = "bond0";
const WIFI: &str = "wlan0";

fn read(path: &str) -> Option<String> {
    fs::read_to_string(path)
        .ok()
        .map(|s| s.trim().to_owned())
}

fn disconnected() -> Status {
    Status::new("disconnected", "Disconnected ⚠", "Disconnected")
}

fn ipv4_address(interface: &str) -> Result<Option<String>, Box<dyn Error>> {
    Ok(getifaddrs()?
        .filter(|addr| addr.interface_name == interface)
        .find_map(|addr| {
            let address = addr.address?.as_sockaddr_in()?.ip();
            let mask = addr.netmask?.as_sockaddr_in()?.ip();
            let prefix = u32::from(mask).count_ones();

            Some(format!("{address}/{prefix}"))
        }))
}

fn wifi_status(ip: &str) -> Result<Status, Box<dyn Error>> {
    let socket = NlSocket::connect()?;

    let Some(interface) = socket
        .list_interfaces()?
        .into_iter()
        .find(|interface| interface.name == WIFI)
    else {
        return Ok(disconnected());
    };

    let Some(ssid) = interface.ssid else {
        return Ok(disconnected());
    };

    let Some(station) = socket
        .list_stations(interface.interface_index)?
        .into_iter()
        .next()
    else {
        return Ok(disconnected());
    };

    // nl80211 represents signed dBm values in an unsigned byte.
    let Some(dbm) = station.signal.map(|signal| (signal as i8) as i32)
    else {
        return Ok(Status::new(
            "wifi",
            "  Connected",
            format!("{ip}\n{ssid} (signal unavailable)"),
        ));
    };

    let percentage = ((dbm + 90) * 100 / 60).clamp(0, 100) as u8;

    let mut status = Status::new(
        "wifi",
        format!("  {percentage}%"),
        format!("{ip}\n{ssid} ({dbm} dBm)"),
    );

    status.percentage = Some(percentage);

    Ok(status)
}

pub fn status() -> Result<Status, Box<dyn Error>> {
    let base = format!("/sys/class/net/{BOND}");

    if read(&format!("{base}/operstate")).as_deref() != Some("up") {
        return Ok(disconnected());
    }

    let Some(slave) = read(&format!("{base}/bonding/active_slave")) else {
        return Ok(disconnected());
    };

    if slave.is_empty() || slave == "None" {
        return Ok(disconnected());
    }

    let ip = ipv4_address(BOND)?.unwrap_or_default();

    if slave == WIFI {
        wifi_status(&ip)
    } else {
        Ok(Status::new("ethernet", "󰈁 Connected", ip))
    }
}
