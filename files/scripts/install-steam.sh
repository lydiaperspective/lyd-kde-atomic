#!/usr/bin/env bash
set -euo pipefail

# Steam's 32-bit PipeWire dependency needs the 32-bit FDK-AAC library.
# The NVIDIA base ships RPM Fusion's libfdk-aac, which obsoletes Fedora's
# fdk-aac-free package. Replace the codec in the same DNF transaction as
# Steam so dependent desktop packages are not removed in a separate step.
dnf5 install --assumeyes --allowerasing \
  fdk-aac-free.x86_64 \
  fdk-aac-free.i686 \
  steam \
  steam-devices \
  gamemode \
  mangohud \
  gamescope
