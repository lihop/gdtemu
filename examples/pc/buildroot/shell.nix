{ pkgs ? import <nixpkgs> {} }:

(pkgs.buildFHSUserEnv {
  name = "buildroot-env";
  targetPkgs = pkgs: (with pkgs; [
    bc
    binutils
    cpio
    elfutils.dev
    file
    flock
    gcc
    openssl.dev
    ncurses.dev
    perl
    rsync
    unzip
    wget
    which
  ]);
}).env
