{ pkgs, ... }:

{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages =
    with pkgs; [
      arandr
      arc-theme
      aspell
      aspellDicts.en
      aspellDicts.fr
      aspellDicts.nl
      autojump
      aws-vault
      awscli
      bc
      binutils # for `ar' command.
      brightnessctl
      cargo
      coreutils
      direnv
      discount # for markdown
      dmenu
      dnsutils
      dunst
      dwm
      emacs
      evince
      firefox
      flameshot
      fzf
      gcc10
      gimp
      git
      glxinfo
      gnucash
      gnumake
      gnupg
      go
      gopls
      htop
      i3lock
      inetutils
      irssi
      isync
      jq
      mu
      ncdu
      ncmpcpp
      nixpkgs-fmt
      openvpn
      paper-icon-theme
      pass
      pavucontrol
      pciutils
      perl
      pinentry-gtk2
      pkgconfig
      powertop
      pqiv
      restic
      (rofi.override {
        plugins = [
          rofi-calc
          rofi-emoji
          rofi-file-browser
        ];
      })
      rsync
      rust-analyzer
      rustc
      rustfmt
      rxvt-unicode
      screen
      shellcheck
      signal-desktop
      silver-searcher
      spotify
      st
      stow
      tree
      unzip
      vimHugeX
      virt-manager
      vlc
      w3m
      wget
      xclip
      xdotool
      xorg.xev
      xorg.xkbcomp
      xorg.xrandr
      youtube-dl
      zsh-history-substring-search
      zsh-syntax-highlighting
    ];
}
