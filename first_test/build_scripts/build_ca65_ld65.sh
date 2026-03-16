#!/bin/bash

ca65 -l hello.list -o hello.o hello.asm
ld65 -C smfc.cfg -o hello.mc -m hello.mmap hello.o
