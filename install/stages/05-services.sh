#!/usr/bin/env bash
# Stage 5: Enable systemd services

info "=== Stage 5: Services ==="

# System services
enable_system_service NetworkManager
enable_system_service sshd
enable_system_service systemd-timesyncd
enable_system_service fstrim.timer

if has_pkg bluez; then
    enable_system_service bluetooth
fi
if has_pkg tailscale; then
    enable_system_service tailscaled
fi
if has_pkg valkey; then
    enable_system_service valkey
fi

# postgresql needs an initialised cluster before the service can start
if has_pkg postgresql; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        dry "initdb the postgresql cluster when /var/lib/postgres/data is empty"
    elif ! sudo test -f /var/lib/postgres/data/PG_VERSION; then
        info "Initialising postgresql cluster..."
        run sudo -u postgres initdb --locale=C.UTF-8 -E UTF8 -D /var/lib/postgres/data
    fi
    enable_system_service postgresql
fi

# docker is started on demand, only the group membership is permanent
if has_pkg docker; then
    if id -nG "$USER" | grep -w docker >/dev/null; then
        success "$USER is in the docker group"
    else
        info "Adding $USER to the docker group (takes effect at next login)"
        run sudo usermod -aG docker "$USER"
    fi
fi

# Machine profile services (machines/<layer>/services: one system unit per line, # comments)
mapfile -t service_lists < <(profile_files services)
for list in "${service_lists[@]}"; do
    mapfile -t units < <(parse_package_list "$list")
    for unit in "${units[@]}"; do
        enable_system_service "$unit"
    done
done

# User services: pipewire is socket-activated, the sockets are what Arch enables globally
enable_user_service pipewire.socket
enable_user_service pipewire-pulse.socket
enable_user_service wireplumber.service

success "=== Stage 5: Complete ==="
