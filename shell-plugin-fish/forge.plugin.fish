#!/usr/bin/env fish

# Forge Fish Shell Plugin
# Documentation in README.md

# Determine the plugin directory
set -l plugin_dir (status dirname)

# Configuration variables
source "$plugin_dir/conf.d/forge.fish"

# Core utility functions
source "$plugin_dir/functions/_forge_exec.fish"
source "$plugin_dir/functions/_forge_log.fish"

# Action handlers
source "$plugin_dir/functions/_forge_action_new.fish"
source "$plugin_dir/functions/_forge_action_info.fish"
source "$plugin_dir/functions/_forge_action_conversation.fish"
source "$plugin_dir/functions/_forge_action_model.fish"
source "$plugin_dir/functions/_forge_action_commit.fish"
source "$plugin_dir/functions/_forge_action_doctor.fish"
source "$plugin_dir/functions/_forge_action_default.fish"

# Main dispatcher
source "$plugin_dir/functions/_forge_dispatcher.fish"

# Completions
source "$plugin_dir/completions/forge.fish"

# Mark plugin as loaded
set -g _FORGE_PLUGIN_LOADED 1
