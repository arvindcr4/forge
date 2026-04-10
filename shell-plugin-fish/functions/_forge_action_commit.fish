#!/usr/bin/env fish

# Git integration actions

function _forge_action_commit
    set -l additional_context $argv[1]
    echo

    if test -n "$additional_context"
        FORCE_COLOR=true CLICOLOR_FORCE=1 $_FORGE_BIN commit --max-diff "$_FORGE_MAX_COMMIT_DIFF" $additional_context
    else
        FORCE_COLOR=true CLICOLOR_FORCE=1 $_FORGE_BIN commit --max-diff "$_FORGE_MAX_COMMIT_DIFF"
    end
end

function _forge_action_commit_preview
    set -l additional_context $argv[1]
    echo

    set -l commit_message
    if test -n "$additional_context"
        set commit_message (FORCE_COLOR=true CLICOLOR_FORCE=1 $_FORGE_BIN commit --preview --max-diff "$_FORGE_MAX_COMMIT_DIFF" $additional_context)
    else
        set commit_message (FORCE_COLOR=true CLICOLOR_FORCE=1 $_FORGE_BIN commit --preview --max-diff "$_FORGE_MAX_COMMIT_DIFF")
    end

    if test -n "$commit_message"
        # In fish, we output the suggested command for user to execute
        if git diff --staged --quiet
            echo "git commit -am '$commit_message'"
        else
            echo "git commit -m '$commit_message'"
        end
    end
end
