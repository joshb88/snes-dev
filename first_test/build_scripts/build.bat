@echo off

REM move to project root (one level up from build_scripts)
cd /d "%~dp0.."

cl65 -C smc.cfg -o hello.mc -l hello.list -m hello.mmap hello.asm