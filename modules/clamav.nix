{
  pkgs,
  config,
  lib,
  ...
}: let
  virusEvent = pkgs.writeShellScript "virus-event.bash" ''
    #!/bin/bash
    PATH=/usr/bin
    ALERT="Signature detected by clamav: $CLAM_VIRUSEVENT_VIRUSNAME in $CLAM_VIRUSEVENT_FILENAME"

    # Send an alert to all graphical users.
    for ADDRESS in /run/user/*; do
        USERID=$${ADDRESS#/run/user/}
        /usr/bin/sudo -u "#$USERID" DBUS_SESSION_BUS_ADDRESS="unix:path=$ADDRESS/bus" PATH=$${PATH} \
            ${pkgs.libnotify}/bin/notify-send -w -u critical -i dialog-warning "Virus found!" "$ALERT"
    done
  '';
in {
  environment.systemPackages = with pkgs; [
    clamav
  ];

  services.clamav = {
    daemon = {
      enable = true;
      settings = {
        VirusEvent = virusEvent;

        LogTime = true;
        ExtendedDetectionInfo = true;
        MaxDirectoryRecursion = 20;

        DetectPUA = true;
        HeuristicAlerts = true;
        ScanPE = true;
        ScanELF = true;
        ScanOLE2 = true;
        ScanPDF = true;
        ScanSWF = true;
        ScanXMLDOCS = true;
        ScanHWP3 = true;
        ScanOneNote = true;
        ScanMail = true;
        ScanHTML = true;
        ScanArchive = true;
        Bytecode = true;
        AlertBrokenExecutables = true;
        AlertBrokenMedia = true;
        AlertEncrypted = true;
        AlertEncryptedArchive = true;
        AlertEncryptedDoc = true;
        AlertOLE2Macros = true;
        AlertPartitionIntersection = true;
      };
    };
    scanner.enable = true;
    updater.enable = true;
    fangfrisch.enable = true;
  };
}
