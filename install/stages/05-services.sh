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

# postgresql needs an initialised cluster before the service can start. An enabled unit had its
# cluster initialised before it was enabled, so the root-only data dir is not even looked at then.
if has_pkg postgresql; then
    if systemctl is-enabled postgresql &>/dev/null; then
        : # enable_system_service below reports it
    elif [[ "${DRY_RUN:-0}" == "1" ]]; then
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
        note relogin "$USER was added to the docker group"
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

# ssh-agent: openssh's socket-activated agent, one per user session; session.zsh points
# SSH_AUTH_SOCK at it and AddKeysToAgent in ~/.ssh/config loads a key on first use
if has_pkg openssh; then
    agent_was_enabled=0
    systemctl --user is-enabled ssh-agent.socket &>/dev/null && agent_was_enabled=1
    enable_user_service ssh-agent.socket
    if (( ! agent_was_enabled )); then
        note relogin "ssh-agent.socket starts with the next session; until then shells point SSH_AUTH_SOCK at a socket nothing listens on"
    fi
fi

success "=== Stage 5: Complete ==="
