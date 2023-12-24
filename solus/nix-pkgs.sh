#!/usr/bin/env bash
# tolga erok

# setup nix pkgs on solus

sh <(curl -L https://nixos.org/nix/install) --no-daemon
. /home/@USER/.nix-profile/etc/profile.d/nix.sh
nix --version
export PATH="$HOME/.nix-profile/bin:$PATH"
#nix-shell
nix --version
nix-env -iA nixpkgs.nixpkgs-fmt
nixpkgs-fmt --version
nix-shell -p espeak-classic
espeak -v en+m7 -s 165 "Welcome! This script will! initiate! the! basic! setup! for your system. Thank you for using! my configuration." --punct=","
