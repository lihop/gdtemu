{ pkgs ? import <nixpkgs> {} }:

(pkgs.buildFHSUserEnv {
  name = "buildroot-env";
  targetPkgs = pkgs: (with pkgs; [
    bc
    binutils
    cpio
    file
    flock
    gcc
    lzma.dev
    ncurses.dev
    perl
    rsync
    unzip
    wget
    which
  ]);
}).env
