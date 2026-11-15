-- Which machine is this? Returns the merged profile from machines/<name>/hypr.lua and the layers
-- it extends, with .name, .source, .dir and .layers added. Resolution mirrors install/machine.sh:
--   1. pin: ~/.config/dotfiles/profile (written by install.sh --profile <name>)
--   2. DMI strings against machines/index
--   3. a BAT* battery means "laptop", anything else is "generic"
-- A profile that is missing falls back to generic, so the session always starts.
--
-- A profile file returns a table with any of:
--   monitors  list of hl.monitor specs; a later layer replaces an earlier one's rule for the same output
--   config    table for hl.config, applied after the shared config (base layer first)
--   setup     function run last (base layer first), for binds, devices and event handlers
--   hypridle  hypridle config file, relative to that profile's directory
-- machines/<name>/extends names the layer it builds on (thinkpad and framework extend laptop).

local function first_line(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local line = f:read("l")
	f:close()
	if line then
		line = line:gsub("^%s+", ""):gsub("%s+$", "")
	end
	if line == "" then
		return nil
	end
	return line
end

local function readable(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

-- literal compare; a trailing * turns the pattern into a prefix match, an empty pattern matches anything
local function field_matches(value, pattern)
	if pattern == nil or pattern == "" then
		return true
	end
	if pattern:sub(-1) == "*" then
		local prefix = pattern:sub(1, -2)
		return value:sub(1, #prefix) == prefix
	end
	return value == pattern
end

local function split_fields(line)
	local fields = {}
	for field in (line .. "|"):gmatch("([^|]*)|") do
		fields[#fields + 1] = field
	end
	return fields
end

local here = debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]*$") or "."
local machines = here .. "/machines"

local function resolve()
	local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
	local pin = first_line(config_home .. "/dotfiles/profile")
	if pin then
		return pin:gsub("%s", ""), "pinned"
	end

	-- both overridable for tests, like install/machine.sh
	local dmi = os.getenv("DMI_DIR") or "/sys/class/dmi/id"
	local ps = os.getenv("PS_DIR") or "/sys/class/power_supply"
	local values = {
		first_line(dmi .. "/sys_vendor") or "",
		first_line(dmi .. "/product_name") or "",
		first_line(dmi .. "/product_version") or "",
		first_line(dmi .. "/product_family") or "",
	}
	local index = io.open(machines .. "/index", "r")
	if index then
		for line in index:lines() do
			if line ~= "" and line:sub(1, 1) ~= "#" then
				local fields = split_fields(line)
				local matched = fields[1] ~= ""
				for i = 1, #values do
					matched = matched and field_matches(values[i], fields[i + 1])
				end
				if matched then
					index:close()
					return fields[1], "dmi"
				end
			end
		end
		index:close()
	end

	for _, bat in ipairs({ "BAT0", "BAT1", "BAT2" }) do
		if readable(ps .. "/" .. bat .. "/type") then
			return "laptop", "battery"
		end
	end
	return "generic", "fallback"
end

local function exists(name)
	return name ~= nil and name ~= "" and not name:find("[/.]") and readable(machines .. "/" .. name .. "/hypr.lua")
end

-- the profile and the layers it extends, base first
local function layers_of(name)
	local layers = {}
	local depth = 0
	while name and exists(name) and depth < 4 do
		table.insert(layers, 1, name)
		name = first_line(machines .. "/" .. name .. "/extends")
		depth = depth + 1
	end
	return layers
end

local name, source = resolve()
if not exists(name) then
	print("machine profile '" .. tostring(name) .. "' not found, using generic")
	name, source = "generic", "error"
end

local profile = {
	name = name,
	source = source,
	dir = machines .. "/" .. name,
	layers = layers_of(name),
	monitors = {},
	configs = {},
	setups = {},
}

for _, layer in ipairs(profile.layers) do
	-- Hyprland's require reports a broken module itself; whatever it hands back that is not a
	-- table contributes nothing
	local ok, spec = pcall(require, "machines." .. layer .. ".hypr")
	if not ok then
		print("machine layer '" .. layer .. "' did not load: " .. tostring(spec))
	elseif type(spec) == "table" then
		for _, monitor in ipairs(spec.monitors or {}) do
			local replaced = false
			for i, existing in ipairs(profile.monitors) do
				if existing.output == monitor.output then
					profile.monitors[i] = monitor
					replaced = true
				end
			end
			if not replaced then
				table.insert(profile.monitors, monitor)
			end
		end
		if type(spec.config) == "table" then
			table.insert(profile.configs, spec.config)
		end
		if type(spec.setup) == "function" then
			table.insert(profile.setups, spec.setup)
		end
		if spec.hypridle then
			profile.hypridle = machines .. "/" .. layer .. "/" .. spec.hypridle
		end
	end
end

-- apply the per-machine overrides; called last by hyprland.lua so they win over the shared values
function profile.apply()
	for _, cfg in ipairs(profile.configs) do
		hl.config(cfg)
	end
	for _, setup in ipairs(profile.setups) do
		local ok, err = pcall(setup)
		if not ok then
			print("machine setup failed: " .. tostring(err))
		end
	end
end

return profile
