@echo off

:: Configuration for forge CMD plugin

:: Forge binary path
if not defined FORGE_BIN set "FORGE_BIN=forge"

:: Max commit diff size
if not defined FORGE_MAX_COMMIT_DIFF set "FORGE_MAX_COMMIT_DIFF=100000"

:: Session state (persisted via environment variables within this CMD session)
if not defined _FORGE_CONVERSATION_ID set "_FORGE_CONVERSATION_ID="
if not defined _FORGE_ACTIVE_AGENT set "_FORGE_ACTIVE_AGENT="
if not defined _FORGE_PREVIOUS_CONVERSATION_ID set "_FORGE_PREVIOUS_CONVERSATION_ID="
if not defined _FORGE_SESSION_MODEL set "_FORGE_SESSION_MODEL="
if not defined _FORGE_SESSION_PROVIDER set "_FORGE_SESSION_PROVIDER="
