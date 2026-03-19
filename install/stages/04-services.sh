#!/usr/bin/env bash
# Stage 4: Enable systemd services

info "=== Stage 4: Services ==="

# System services
enable_system_service() {
    local service="$1"
    if systemctl is-enabled "$service" &>/dev/null; then
        success "Already enabled: $service"
    else
        info "Enabling: $service"
        run sudo systemctl enable "$service"
    fi
}

enable_system_service NetworkManager

if pacman -Qq bluez &>/dev/null; then
    enable_system_service bluetooth
else
    info "bluez not installed, skipping bluetooth service"
fi

# User services
enable_user_service() {
    local service="$1"
    if systemctl --user is-enabled "$service" &>/dev/null; then
        success "Already enabled (user): $service"
    else
        info "Enabling user service: $service"
        if ! run systemctl --user enable "$service"; then
            warn "Could not enable $service — may need an active user session"
        fi
    fi
}

enable_user_service pipewire
enable_user_service pipewire-pulse
enable_user_service wireplumber

success "=== Stage 4: Complete ==="
