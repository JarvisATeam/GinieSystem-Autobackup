import os, subprocess
root = os.path.expanduser("~/GinieSystem/Agents/tiktok_poster")
assets = os.path.join(root, "assets")
temp = os.path.join(root, "temp")
output = os.path.join(temp, "final_video.mp4")

images = sorted([f for f in os.listdir(assets) if f.lower().endswith((".jpg", ".png"))])
audio = next((f for f in os.listdir(assets) if f.lower().endswith((".mp3", ".m4a", ".wav"))), None)
if not images or not audio:
    print("🚫 Mangler bilder eller lyd."); exit(1)

with open(os.path.join(temp, "imglist.txt"), "w") as f:
    for i in images:
        f.write(f"file '{os.path.join(assets, i)}'\n")
        f.write("duration 2\n")

subprocess.call([
    "ffmpeg", "-y", "-f", "concat", "-safe", "0",
    "-i", os.path.join(temp, "imglist.txt"),
    "-i", os.path.join(assets, audio),
    "-c:v", "libx264", "-c:a", "aac", "-shortest", output
])
