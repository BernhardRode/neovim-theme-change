#!/bin/bash
# System integration examples for nvim-theme-ipc

# Example 1: Dark/Light mode detection (GNOME)
detect_gnome_theme() {
    if command -v gsettings >/dev/null 2>&1; then
        local gtk_theme
        gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme)
        
        if [[ "$gtk_theme" == *"dark"* ]]; then
            nvim-theme set tokyonight-night
        else
            nvim-theme set github_light
        fi
    fi
}

# Example 2: macOS dark mode detection
detect_macos_theme() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local dark_mode
        dark_mode=$(defaults read -g AppleInterfaceStyle 2>/dev/null)
        
        if [[ "$dark_mode" == "Dark" ]]; then
            nvim-theme set tokyonight-night
        else
            nvim-theme set github_light
        fi
    fi
}

# Example 3: Time-based theme switching
time_based_theme() {
    local hour
    hour=$(date +%H)
    
    if (( hour >= 18 || hour < 8 )); then
        # Night time (6 PM to 8 AM)
        nvim-theme set tokyonight-night
    else
        # Day time (8 AM to 6 PM)
        nvim-theme set github_light
    fi
}

# Example 4: Battery level based theme (darker themes save power on OLED)
battery_based_theme() {
    if command -v acpi >/dev/null 2>&1; then
        local battery_level
        battery_level=$(acpi -b | grep -P -o '[0-9]+(?=%)')
        
        if (( battery_level < 20 )); then
            # Low battery - use dark theme
            nvim-theme set default
        elif (( battery_level < 50 )); then
            nvim-theme set tokyonight-night
        else
            nvim-theme set tokyonight-day
        fi
    fi
}

# Example 5: Location-based theme (requires internet)
location_based_theme() {
    if command -v curl >/dev/null 2>&1; then
        local sunrise_sunset
        sunrise_sunset=$(curl -s "https://api.sunrise-sunset.org/json?lat=40.7128&lng=-74.0060&formatted=0")
        
        local sunrise sunset current_time
        sunrise=$(echo "$sunrise_sunset" | jq -r '.results.sunrise' | date -d - +%s)
        sunset=$(echo "$sunrise_sunset" | jq -r '.results.sunset' | date -d - +%s)
        current_time=$(date +%s)
        
        if (( current_time >= sunrise && current_time < sunset )); then
            nvim-theme set github_light
        else
            nvim-theme set tokyonight-night
        fi
    fi
}

# Example 6: Workspace/project based themes
project_based_theme() {
    local project_dir
    project_dir=$(pwd)
    
    case "$project_dir" in
        */work/*)
            nvim-theme set github_light
            ;;
        */personal/*)
            nvim-theme set catppuccin-mocha
            ;;
        */opensource/*)
            nvim-theme set gruvbox
            ;;
        *)
            nvim-theme set tokyonight
            ;;
    esac
}

# Example 7: Random theme selector
random_theme() {
    local themes
    mapfile -t themes < <(nvim-theme list)
    
    if (( ${#themes[@]} > 0 )); then
        local random_theme
        random_theme=${themes[$RANDOM % ${#themes[@]}]}
        nvim-theme set "$random_theme"
        echo "Switched to random theme: $random_theme"
    fi
}

# Example 8: Theme cycling
cycle_themes() {
    local themes=("tokyonight-night" "tokyonight-day" "github_dark" "github_light" "gruvbox" "catppuccin-mocha")
    local current_theme
    current_theme=$(nvim-theme get)
    
    local next_index=0
    for i in "${!themes[@]}"; do
        if [[ "${themes[$i]}" == "$current_theme" ]]; then
            next_index=$(( (i + 1) % ${#themes[@]} ))
            break
        fi
    done
    
    nvim-theme set "${themes[$next_index]}"
    echo "Cycled to: ${themes[$next_index]}"
}

# Main function to demonstrate usage
main() {
    case "${1:-}" in
        "gnome")
            detect_gnome_theme
            ;;
        "macos")
            detect_macos_theme
            ;;
        "time")
            time_based_theme
            ;;
        "battery")
            battery_based_theme
            ;;
        "location")
            location_based_theme
            ;;
        "project")
            project_based_theme
            ;;
        "random")
            random_theme
            ;;
        "cycle")
            cycle_themes
            ;;
        *)
            echo "Usage: $0 {gnome|macos|time|battery|location|project|random|cycle}"
            echo ""
            echo "Examples:"
            echo "  $0 gnome     - Switch based on GNOME theme"
            echo "  $0 time      - Switch based on time of day"
            echo "  $0 random    - Switch to random theme"
            echo "  $0 cycle     - Cycle through predefined themes"
            ;;
    esac
}

main "$@"
