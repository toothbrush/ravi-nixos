# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
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

  networking.hostName = "ravi"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s31f6.useDHCP = true;
  networking.interfaces.wlp0s20f3.useDHCP = true;

  networking.networkmanager.enable = true;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" "8.8.4.4" ];

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = [ nvidia-offload ] ++ (
    with pkgs; [
      arandr
      aspell
      aspellDicts.en
      aspellDicts.fr
      aspellDicts.nl
      autojump
      bc
      brightnessctl
      cargo
      discount # for markdown
      dmenu
      dwm
      emacs
      firefox
      flameshot
      fzf
      gcc
      git
      glxinfo
      gnumake
      gnupg
      go
      gopls
      htop
      i3lock
      irssi
      isync
      mu
      ncdu
      nixpkgs-fmt
      pass
      pavucontrol
      pciutils
      perl
      pinentry-gtk2
      powertop
      rsync
      rustc
      rustfmt
      rust-analyzer
      rxvt-unicode
      shellcheck
      signal-desktop
      silver-searcher
      spotify
      st
      stow
      tree
      vim
      vlc
      w3m
      wget
      xcape
      xdotool
      xmobar
      xmonad-with-packages
      xorg.xkbcomp
      xorg.xev
      youtube-dl
      zsh-history-substring-search
      zsh-syntax-highlighting
    ]
  );

  fonts.fonts = with pkgs; [
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

  # Enable sound.
  sound.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 65;
      STOP_CHARGE_THRESH_BAT0 = 80;
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
  '';

  # Enable touchpad support.
  services.xserver.libinput.enable = true;
  services.xserver.libinput.naturalScrolling = true;

  services.xserver.windowManager.xmonad.enable = true;
  services.xserver.windowManager.dwm.enable = true;
  services.xserver.videoDrivers = [ "intel" "modesetting" "nvidia" ];

  hardware = {
    bluetooth.enable = false;
    cpu.intel.updateMicrocode = true;
    pulseaudio.enable = true;

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
      "wheel" # Enable ‘sudo’ for the user.
      "networkmanager"
    ];
    shell = pkgs.zsh;
  };

  systemd.user.services."xcape" = {
    enable = true;
    description = "xcape to use Super_L as Compose when pressed alone";
    wantedBy = [ "default.target" ];
    serviceConfig.Type = "forking";
    serviceConfig.Restart = "always";
    serviceConfig.RestartSec = 2;
    serviceConfig.ExecStart = ''${pkgs.xcape}/bin/xcape -e "Super_L=Multi_key"'';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}
