# Forge Fish Shell Plugin Setup
# Add this to your ~/.config/fish/config.fish

# Load forge shell plugin (commands, completions, keybindings) if not already loaded
if not set -q _FORGE_PLUGIN_LOADED
    set -l plugin_path (command -v forge 2>/dev/null; and forge fish plugin-path 2>/dev/null)
    if test -n "$plugin_path"; and test -f "$plugin_path"
        source "$plugin_path"
    else
        # Fallback: source directly if forge.plugin.fish is in a known location
        for p in ~/.config/fish/forge/forge.plugin.fish ~/.local/share/forge/shell-plugin-fish/forge.plugin.fish
            if test -f "$p"
                source "$p"
                break
            end
        end
    end
end

# Load forge shell theme (prompt with AI context) if not already loaded
if not set -q _FORGE_THEME_LOADED
    set -l theme_path (dirname (status filename) 2>/dev/null)/forge.theme.fish
    if test -f "$theme_path"
        source "$theme_path"
    end
end
