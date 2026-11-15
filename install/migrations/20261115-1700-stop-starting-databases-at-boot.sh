#!/usr/bin/env bash
# Stop starting postgresql and valkey at boot: they run on demand now (dbup / dbdown)
#
# Stage 5 enabled both until 2026-11-15; two database servers running from boot cost battery on the
# laptops for nothing. This only disables them: a server running now keeps running until it is
# stopped (dbdown) or the machine reboots, so no work in progress is cut off. The data stays.

for unit in postgresql valkey; do
    if systemctl is-enabled "$unit" &>/dev/null; then
        info "Disabling $unit at boot (start it with dbup when a project needs it)"
        run as_root systemctl disable "$unit"
    else
        success "Not started at boot: $unit"
    fi
done
