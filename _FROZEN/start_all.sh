#!/bin/bash
osascript <<END
tell application "Safari"
    activate
    open location "https://www.tiktok.com/upload"
end tell
END
echo "🎬 Manuell opplasting må fullføres i Safari!"
