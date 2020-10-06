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
      dunst
      dwm
      emacs
      firefox
      flameshot
      fzf
      gcc
      git
      glxinfo
      gnucash
      gnumake
      gnupg
      go
      gopls
      htop
      i3lock
      irssi
      isync
      jq
      mu
      ncdu
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
      restic
      rofi
      rsync
      rust-analyzer
      rustc
      rustfmt
      rxvt-unicode
      shellcheck
      signal-desktop
      silver-searcher
      spotify
      st
      stow
      tree
      unzip
      vimHugeX
      vlc
      w3m
      wget
      xclip
      xdotool
      xmobar
      xmonad-with-packages
      xorg.xev
      xorg.xkbcomp
      xorg.xrandr
      youtube-dl
      zsh-history-substring-search
      zsh-syntax-highlighting
    ];
}
