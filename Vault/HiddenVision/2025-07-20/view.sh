#!/bin/bash
qlmanage -p "$(find . -name 'vision_*.txt' | head -n 1)" >/dev/null 2>&1 &
