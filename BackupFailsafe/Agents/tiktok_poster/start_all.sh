#!/bin/bash
echo "🚀 Starter TikTokPoster..."
cd ~/GinieSystem/Agents/tiktok_poster || exit 1
if [ -f "venv/bin/activate" ]; then source venv/bin/activate; fi
if [ ! -f temp/final_video.mp4 ]; then python3 video_builder.py; fi
python3 autopost.py
