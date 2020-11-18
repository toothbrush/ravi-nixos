# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let
  compiledDefaultLayout = pkgs.runCommand "keyboard-layout" { } ''
    ${pkgs.xorg.xkbcomp}/bin/xkbcomp ${./keyboard/default-layout.xkb} $out
  '';
  compiledInternalLayout = pkgs.runCommand "keyboard-layout" { } ''
    ${pkgs.xorg.xkbcomp}/bin/xkbcomp -I${./keyboard} ${./keyboard/internal-layout.xkb} $out
  '';
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # Split out file with long list of system-wide packages.
    ./installed-packages.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # screen locker
  programs.xss-lock.enable = true;
  programs.zsh =
    {
      enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
    };

  security.pam.services = {
    lightdm.enableGnomeKeyring = true;
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # GRUB configuration
  boot.loader.grub = {
    enable = true;
    version = 2;
    efiSupport = true;
    enableCryptodisk = true;
    device = "nodev";
  };

  # Linux Unified Key Setup
  boot.initrd.luks.devices = {
    crypted = {
      device = "/dev/disk/by-uuid/88983b84-491b-4efb-939d-28722b11c87e";
      preLVM = true;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];

  # reference documentation:
  # https://download.nvidia.com/XFree86/Linux-x86_64/435.21/README/dynamicpowermanagement.html
  # and discussion:
  # https://discourse.nixos.org/t/how-to-use-nvidia-prime-offload-to-run-the-x-server-on-the-integrated-board/9091/14
  boot.extraModprobeConfig = "options nvidia \"NVreg_DynamicPowerManagement=0x02\"\n";

  networking.hostName = "ravi"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s31f6.useDHCP = false;
  networking.interfaces.wlp0s20f3.useDHCP = false;

  networking.networkmanager.enable = true;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" "8.8.4.4" ];

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  # Set your time zone.
  time.timeZone = "Australia/Darwin";

  environment.homeBinInPath = true;

  fonts.fonts = with pkgs; [
    emojione
    noto-fonts
    noto-fonts-emoji
    hack-font
    terminus_font
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "gtk2";
  };

  programs.ssh.startAgent = true;

  # List services that you want to enable:

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  services.mpd = {
    enable = true;
    user = "paul";
    musicDirectory = "/home/paul/Music";
    extraConfig = ''
      audio_output {
        type    "pulse"
        name    "mpd"
        server  "127.0.0.1"
      }
      auto_update "yes"
    '';
  };

  virtualisation.docker.enable = true;

  # Enable sound.
  sound.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.tlp = {
    enable = true;
    ## Default charging thresholds are 96/100%. See https://linrunner.de/tlp/settings/battery.html
    settings = {
      START_CHARGE_THRESH_BAT0 = 80;
      STOP_CHARGE_THRESH_BAT0 = 95;
      DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wwan";
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      RUNTIME_PM_DRIVER_BLACKLIST = "mei_me";
    };
  };
  # Has to be enabled for gnome applications settings to work
  services.dbus.packages = with pkgs; [
    gnome3.dconf
    gnome3.gnome-keyring
    dunst
  ];
  systemd.packages = [ pkgs.dunst ];
  programs.dconf.enable = true;
  programs.seahorse.enable = true;

  services.gnome3 = {
    gnome-keyring.enable = true;
    at-spi2-core.enable = true;
  };

  services.udev = {
    extraRules = ''
      ACTION=="change", KERNEL=="card1", SUBSYSTEM=="drm", RUN+="${pkgs.systemd}/bin/systemctl --no-block start resetDisplayPanel.service"

      # Remove NVIDIA USB xHCI Host Controller devices, if present
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{remove}="1"

      # Remove NVIDIA USB Type-C UCSI devices, if present
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{remove}="1"

      # Remove NVIDIA Audio devices, if present
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"

      # Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind
      ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
      ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"

      # Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind
      ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
      ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
    '';
  };
  # Turning it into user service would make it less brittle!  However,
  # triggering a user service from udev rule doesn't seem trivial.
  # Presumably it's looking in /root's services.  We could also use
  # User=.. in the service definition, but i'd be surprised if that
  # gives access to the necessary $DISPLAY and $XAUTHORITY values.
  systemd.services."resetDisplayPanel" = {
    environment = {
      XAUTHORITY = "/home/paul/.Xauthority";
      DISPLAY = ":0";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.xorg.xrandr}/bin/xrandr \
          --output eDP1 --primary --mode 1920x1080 --pos 0x0 --rotate normal \
          --output DP1 --off \
          --output DP2 --off \
          --output HDMI1 --off \
          --output HDMI2 --off \
          --output VIRTUAL1 --off
      '';
    };
  };

  # Enable PostgresQL for local Rails development.
  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_12;
  # Find available postgresql plugins with:
  # $ nix repl '<nixpkgs>'
  # nixpkgs> postgresql_12.pkgs.<TAB><TAB>
  services.postgresql.extraPlugins = with pkgs.postgresql_12.pkgs; [
    postgis
  ];
  # Wow, terrible hack to make authentication on localhost work.
  # Anyway, once all this is installed one still needs to create users
  # and databases.
  # $ sudo -u postgres psql
  # postgres=# create database mydb;
  # postgres=# create user myuser;
  # .. or if you need a password for some reason ..
  # postgres=# create user myuser with encrypted password 'mypass';
  # postgres=# grant all privileges on database mydb to myuser;
  services.postgresql.authentication = lib.mkForce ''
    # Generated file; do not edit!
    # TYPE  DATABASE        USER            ADDRESS                 METHOD
    local   all             all                                     trust
    host    all             all             127.0.0.1/32            trust
    host    all             all             ::1/128                 trust
  '';

  # Trim journald history a little.
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    MaxFileSec=7day
  '';
  services.logind.extraConfig = ''
    IdleActionSec=300min
  '';

  # Remap caps->ctrl in console ttys
  services.xserver.xkbOptions = "ctrl:nocaps";
  console.useXkbConfig = true;

  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xkbcomp}/bin/xkbcomp ${compiledDefaultLayout} $DISPLAY
    export THINKPAD_KBD_ID=$(xinput list --id-only 'AT Translated Set 2 keyboard')
    ${pkgs.xorg.xkbcomp}/bin/xkbcomp -i $THINKPAD_KBD_ID ${compiledInternalLayout} $DISPLAY
    ${pkgs.xorg.xinput} --set-prop 'SynPS/2 Synaptics TouchPad' 'libinput Accel Speed' 0.6
    ${pkgs.xorg.xinput} --set-prop 'TPPS/2 Elan TrackPoint' 'libinput Accel Speed' -0.5
    ${pkgs.xcalib} ${./LG_Display___LP140WFA_SPD1.icm}
  '';

  # Enable touchpad support.
  services.xserver.libinput.enable = true;
  services.xserver.libinput.naturalScrolling = true;
  services.xserver.libinput.clickMethod = "clickfinger";

  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      dmenu
      i3status
      i3lock
      # See note about i3blocks if it doesn't work: https://nixos.wiki/wiki/I3#i3blocks
      i3blocks
    ];
  };
  services.xserver.windowManager.dwm.enable = true;
  services.xserver.desktopManager.wallpaper.mode = "fill";
  services.xserver.videoDrivers = [ "intel" "nvidia" ];

  hardware = {
    bluetooth.enable = false;
    cpu.intel.updateMicrocode = true;
    pulseaudio.enable = true;
    pulseaudio.extraConfig = ''
      load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1
    ''; # Needed by mpd to be able to use Pulseaudio = true;

    # false is default, but i'm putting the note here anyway.
    nvidia.modesetting.enable = false;
    nvidia.prime = {
      offload.enable = true;
      # Bus ID of the Intel GPU. You can find it using lspci, either under 3D or VGA
      intelBusId = "PCI:0:2:0";

      # Bus ID of the NVIDIA GPU. You can find it using lspci, either under 3D or VGA
      nvidiaBusId = "PCI:60:0:0";
    };
  };
  powerManagement.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.paul = {
    isNormalUser = true;
    extraGroups = [
      "docker"
      "wheel" # Enable ‘sudo’ for the user.
      "networkmanager"
    ];
    shell = pkgs.zsh;
  };

  # GNOME Keyring D-BUS activation is somehow broken. Or maybe D-BUS
  # activation in NixOS is in general somehow broken because also KBDD D-BUS
  # activation is broken. Whenever org.freedesktop.secrets D-BUS is needed,
  # the first attempt fails but the corresponding process starts. Then, the
  # next D-BUS attempt works. This service is a workaround: we poke the D-BUS
  # before any other process so it gets activated and then other processes can
  # use it successfully. This service just pokes some endpoint, doesn't really
  # matter what.
  #
  # TODO: Add D-BUS activation support to GNOME Keyring.
  #
  # This hack courtesy of https://github.com/jluttine/NiDE/blob/0a1db599df236559dcb639b57d895d0798262c8b/src/keyring.nix#L78
  # -- Paul, 17/Sep/2020
  systemd.user.services.gnome-keyring-secrets-init = {
    description = "org.freedesktop.secrets initialization";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
      ExecStart =
        let
          dbus-send = "${pkgs.dbus}/bin/dbus-send";
        in
        "${dbus-send} --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.StartServiceByName string:org.freedesktop.secrets uint32:0";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}
