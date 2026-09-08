package data

import "core:encoding/json"
import "core:os"
import "core:strings"

// Geometry of the main window: restored on startup and persisted on exit.
// width/height are pixels; x/y are only meaningful when positioned is true
// (GTK4 cannot manage window position, so there positioned stays false).
Window_Geometry :: struct {
	width:      int,
	height:     int,
	x:          int,
	y:          int,
	positioned: bool, // whether x/y hold a real saved position
}

// Application configuration, persisted as JSON (config.json)
Config :: struct {
	language: Language,
	window:   Window_Geometry,
}

// Returns the configuration default when nothing has been saved yet
default_config :: proc() -> Config {
	return Config {
		language = .Spanish,
		window   = {},
	}
}

// One-time migration: reads the language from the legacy config.ini file when
// no config.json exists yet. Returns ok = false when the file is missing.
read_legacy_language_from_ini :: proc(filepath: string, allocator := context.allocator) -> (Language, bool) {
	content, err := os.read_entire_file(filepath, allocator)
	if err != os.ERROR_NONE {
		return .Spanish, false
	}
	defer delete(content)

	lines := strings.split_lines(string(content), allocator)
	defer delete(lines)
	for line in lines {
		trimmed := strings.trim_space(line)
		if len(trimmed) == 0 ||
		   strings.has_prefix(trimmed, "#") ||
		   strings.has_prefix(trimmed, ";") {
			continue
		}

		parts := strings.split(trimmed, "=", allocator)
		if len(parts) == 2 {
			key := strings.to_lower(strings.trim_space(parts[0]))
			val := strings.to_lower(strings.trim_space(parts[1]))
			if key == "language" || key == "lang" {
				if strings.has_prefix(val, "en") {
					return .English, true
				} else if strings.has_prefix(val, "es") {
					return .Spanish, true
				}
			}
		}
	}
	return .Spanish, false
}

// Loads the configuration from filepath. When the file does not exist yet it
// falls back to the legacy config.ini language, otherwise to the defaults.
load_config :: proc(filepath: string, allocator := context.allocator) -> Config {
	content, err := os.read_entire_file(filepath, allocator)
	if err != os.ERROR_NONE {
		// No config.json yet: keep the language from the old config.ini if present
		if lang, ok := read_legacy_language_from_ini("config.ini", allocator); ok {
			return Config {language = lang}
		}
		return default_config()
	}
	defer delete(content)

	cfg: Config
	if json_err := json.unmarshal(content, &cfg, allocator=allocator); json_err != nil {
		return default_config()
	}
	return cfg
}

// Saves the given configuration to filepath in JSON format (enum stored as name)
save_config :: proc(filepath: string, cfg: Config, allocator := context.allocator) -> bool {
	json_bytes, err := json.marshal(cfg, {use_enum_names = true}, allocator=allocator)
	if err != nil {
		return false
	}
	defer delete(json_bytes)

	return os.write_entire_file(filepath, json_bytes) == os.ERROR_NONE
}
