@echo off

:: Forge CMD Plugin Setup
:: Run this to set up DOSKEY macros for the current CMD session
:: Add to your AutoRun registry key for persistence

:: Set up DOSKEY macros for :command shortcuts
doskey :new="%~dp0forge.cmd" :new $*
doskey :n="%~dp0forge.cmd" :new $*
doskey :info="%~dp0forge.cmd" :info $*
doskey :i="%~dp0forge.cmd" :info $*
doskey :env="%~dp0forge.cmd" :env $*
doskey :conversation="%~dp0forge.cmd" :conversation $*
doskey :c="%~dp0forge.cmd" :conversation $*
doskey :model="%~dp0forge.cmd" :model $*
doskey :m="%~dp0forge.cmd" :model $*
doskey :agent="%~dp0forge.cmd" :agent $*
doskey :a="%~dp0forge.cmd" :agent $*
doskey :tools="%~dp0forge.cmd" :tools $*
doskey :t="%~dp0forge.cmd" :tools $*
doskey :config="%~dp0forge.cmd" :config $*
doskey :commit="%~dp0forge.cmd" :commit $*
doskey :clone="%~dp0forge.cmd" :clone $*
doskey :copy="%~dp0forge.cmd" :copy $*
doskey :sync="%~dp0forge.cmd" :sync $*
doskey :login="%~dp0forge.cmd" :login $*
doskey :logout="%~dp0forge.cmd" :logout $*
doskey :doctor="%~dp0forge.cmd" :doctor $*
doskey :retry="%~dp0forge.cmd" :retry $*
doskey :r="%~dp0forge.cmd" :retry $*
doskey :dump="%~dp0forge.cmd" :dump $*
doskey :d="%~dp0forge.cmd" :dump $*
doskey :compact="%~dp0forge.cmd" :compact $*
doskey :rename="%~dp0forge.cmd" :rename $*
doskey :rn="%~dp0forge.cmd" :rename $*
doskey :skill="%~dp0forge.cmd" :skill $*
doskey :keyboard-shortcuts="%~dp0forge.cmd" :keyboard-shortcuts $*
doskey :kb="%~dp0forge.cmd" :keyboard-shortcuts $*

echo Forge CMD macros loaded. Type "forge" for help.
