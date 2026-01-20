#!/usr/bin/env sh
meson setup build -Dprefix=$HOME/.spacemacs.d/lib/c -Dlibdir=bootstrap
meson compile -C build
meson install -C build
