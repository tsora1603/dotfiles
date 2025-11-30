#!/bin/bash

# Forces dark mode and set matching wallpaper
qs -c noctalia-shell ipc call darkMode setDark
sleep 0.5
qs -c noctalia-shell ipc call wallpaper random
