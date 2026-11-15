# Framework arrival checklist

Work through this on the machine after the first boot. Each verified item becomes one small commit
that uncomments a line, fixes a value or adds a drop-in in `machines/framework/` (for example
`set the framework panel scale`, `match the real framework product name`). The values marked VERIFY
in `hypr.lua` and the commented candidates in `packages.txt`, `services` and `grub` are the starting
points.

Battery life is the first priority on this machine; the power items here are the baseline for the
separate power-management investigation, not its result.

## 1. Identity

- [ ] `cat /sys/class/dmi/id/{sys_vendor,product_name,product_version,product_family}`
- [ ] `./install.sh --print-profile` says `framework dmi`; `laptop battery` or `framework pinned`
      means the index missed: put the real product_name into `machines/index`, rerun
      `./install.sh --profile auto` (it removes the pin and converges), then check that
      `--print-profile` now says `framework dmi`
- [ ] `hostnamectl` shows `tf`

## 2. Kernel and firmware

- [ ] `uname -r` and `journalctl -b -p warning -k` (missing firmware, i915/xe errors)
- [ ] `fwupdmgr refresh && fwupdmgr get-updates` (BIOS and EC); note the BIOS version
- [ ] `framework_tool --versions` works (framework-system package)

## 3. Display and scale

- [ ] `hyprctl monitors` lists eDP-1 with the 2880x1920 mode and its refresh rates
- [ ] pick the scale (1.6 to start; 1.5 and 2 also divide evenly) and set it in `hypr.lua`
- [ ] XWayland apps (Steam, Discord) are sharp with `xwayland.force_zero_scaling`; decide
      `GDK_SCALE` and the cursor size for this machine only
- [ ] ghostty font size reads well at the chosen scale

## 4. Battery and power baseline

- [ ] `ls /sys/class/power_supply` (BAT0 or BAT1; the waybar module must show it)
- [ ] `powerprofilesctl get` works and the three profiles switch
- [ ] idle baseline on battery, screen on, nothing running: `upower -i $(upower -e | grep BAT)`
      energy rate, and `sudo powertop` for 5 minutes; note the watts
- [ ] video playback baseline (1080p in Zen with hardware decode)
- [ ] charge limit through the EC: `framework_tool --charge-limit` (80 percent is the usual choice)

## 5. Suspend and hibernate

- [ ] `cat /sys/power/mem_sleep` (s2idle expected); suspend from the lid and from `systemctl suspend`
- [ ] overnight drain in percent per hour; if it is bad, a btrfs swapfile inside LUKS for
      suspend-then-hibernate (no repartition needed)
- [ ] resume brings back Wi-Fi, Bluetooth, audio and the panel at the right scale

## 6. Devices

- [ ] audio: `wpctl status` lists the SOF card's sinks and sources, speakers and the headphone jack work, mic records
- [ ] Wi-Fi: `iw dev`, roaming between 2.4 and 5 GHz, no stalls over an hour
- [ ] Bluetooth: the XM5 pairs and plays LDAC; the Keychron reconnects after suspend
- [ ] VA-API: `vainfo` lists the iHD driver; Zen `about:support` shows hardware decode
- [ ] fingerprint: `fprintd-enroll`; adding it to hyprlock and sudo is its own change
- [ ] touchpad: tap to click, disable while typing, three-finger workspace swipe
- [ ] `sudo pacman -S --needed wev` (only for this check; dots-prune offers it for removal later),
      then `wev`: which key the display key (F8 area) sends; rebind SUPER+P in this profile only if it
      collides

## 7. Lid, idle and docks

- [ ] lid switch name from `hyprctl devices` (for the docked lid handling in `hypr.lua`)
- [ ] idle: dim, display off, then suspend on battery only
- [ ] each dock or external monitor: `hyprctl monitors` description, then a `desc:` rule in
      `hypr.lua` (connector names on USB-C change between ports)
