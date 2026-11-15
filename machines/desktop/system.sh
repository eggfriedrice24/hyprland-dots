#!/usr/bin/env bash
# Desktop profile hook, sourced at the end of stage 6 with the installer's helpers (run, info, ...).
# Copy to another profile only if its Bluetooth reconnects slowly (question B5 in the plan).

# Bluetooth: advertise as fast-connectable (quicker headphone and keyboard reconnects, costs power).
# The key lives in [General]; a main.conf without even the commented default gets it appended there.
bt_conf=/etc/bluetooth/main.conf
fc_active='^[[:space:]]*FastConnectable[[:space:]]*='
fc_commented='^#[[:space:]]*FastConnectable[[:space:]]*='
if [[ -f "$bt_conf" ]]; then
    if grep -Eq "${fc_active}[[:space:]]*true[[:space:]]*$" "$bt_conf"; then
        success "bluetooth FastConnectable already on"
    else
        info "Enabling bluetooth FastConnectable..."
        if grep -Eq "$fc_active" "$bt_conf"; then
            run sudo sed -i -E "s/${fc_active}.*/FastConnectable = true/" "$bt_conf"
        elif grep -Eq "$fc_commented" "$bt_conf"; then
            # uncomment only the first commented default
            run sudo sed -i -E "0,/${fc_commented}/ s/${fc_commented}.*/FastConnectable = true/" "$bt_conf"
        elif grep -q '^\[General\]' "$bt_conf"; then
            run sudo sed -i '0,/^\[General\]/ s/^\[General\].*/&\nFastConnectable = true/' "$bt_conf"
        else
            run sudo sed -i '$a [General]\nFastConnectable = true' "$bt_conf"
        fi
    fi
fi
