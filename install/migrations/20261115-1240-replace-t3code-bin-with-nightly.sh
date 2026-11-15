#!/usr/bin/env bash
# Replace the AUR t3code-bin with t3code-nightly-bin, the build the lists install
#
# install/packages/aur.txt moved from t3code-bin to t3code-nightly-bin on 2026-09-26 (9681baa).
# When stage 1 could install the nightly next to the old package, only the old one is removed.

swap_package t3code-bin t3code-nightly-bin aur
