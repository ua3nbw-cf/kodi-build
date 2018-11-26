#!/bin/bash
# Copyright (C) 2018-present Team ua3nbw (https://ua3nbw.ru)


echo -e "- For the user management, Line Out and DAC  to $Cyan 100% unmute $Color_Off"
amixer -c 0 -q set "Line Out"  100%+ unmute
amixer -c 0 -q set "DAC"  100%+ unmute

echo "Ok!!!!!!!!!!!!!!!"
exit 0