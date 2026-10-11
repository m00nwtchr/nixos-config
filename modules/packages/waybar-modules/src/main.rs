mod modules;
mod output;

use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(version, about = "Custom Waybar modules")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// Current bonded network status
    Network,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli = Cli::parse();

    let status = match cli.command {
        Command::Network => modules::network::status()?,
    };

    println!("{}", serde_json::to_string(&status)?);

    Ok(())
}
