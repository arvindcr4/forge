#!/usr/bin/env fish

# Logging utility for forge plugin

function _forge_log
    set -l level $argv[1]
    set -l message $argv[2]
    set -l timestamp (set_color 888888)"["(date '+%H:%M:%S')"]"(set_color normal)

    switch $level
        case error
            echo (set_color red)"⏺"(set_color normal) $timestamp (set_color red)$message(set_color normal)
        case info
            echo (set_color white)"⏺"(set_color normal) $timestamp (set_color white)$message(set_color normal)
        case success
            echo (set_color yellow)"⏺"(set_color normal) $timestamp (set_color white)$message(set_color normal)
        case warning
            echo (set_color bryellow)"⚠️"(set_color normal) $timestamp (set_color bryellow)$message(set_color normal)
        case debug
            echo (set_color cyan)"⏺"(set_color normal) $timestamp (set_color 888888)$message(set_color normal)
        case '*'
            echo $message
    end
end
