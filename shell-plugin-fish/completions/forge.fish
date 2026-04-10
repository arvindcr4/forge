#!/usr/bin/env fish

# Tab completion for :commands and @files

function _forge_complete_commands
    set -l cmd (commandline -ct)

    # Handle :command completion
    if string match -rq '^:' -- "$cmd"
        set -l filter (string replace ':' '' -- "$cmd")
        set -l commands_list (_forge_get_commands)
        if test -n "$commands_list"
            # Skip header line, extract command names
            echo "$commands_list" | tail -n +2 | awk '{print ":"$1}' | grep -i "$filter"
        end
        return
    end

    # Handle @file completion
    if string match -rq '^@' -- "$cmd"
        set -l filter (string replace '@' '' -- "$cmd")
        set -l file_list ($_FORGE_FD_CMD --type f --type d --hidden --exclude .git 2>/dev/null)
        if test -n "$file_list"
            for f in (echo "$file_list" | grep -i "$filter")
                echo "@[$f]"
            end
        end
        return
    end
end

# Register completions for command line starting with :
complete -c : -f -a '(_forge_complete_commands)'
