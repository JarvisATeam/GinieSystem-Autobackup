#!/bin/bash
echo "🌀 Genererer skjult bilde i GINIE-tunnel"

GEN_DIR="$HOME/GinieSystem/Vault/HiddenVision/$(date '+%F')"
mkdir -p "$GEN_DIR"
cd "$GEN_DIR"

# Lag prompt
cat << EOPROMPT > "$GEN_DIR/prompt.txt"
A symbolic, emotionally charged photorealistic scene:
A mysterious figure walking away through a glowing archway,
leaving no digital trace.
Light plays along the edge of her silhouette.
The path behind her is sealed, the space ahead undefined.
No metadata. No tracking. No identity. Just signal.
EOPROMPT

# Simulert bilde-generator (du kan bytte ut denne delen med image_gen.text2im API)
echo "🖼️ (Simulert) genererer bilde fra prompt..."
cp "$GEN_DIR/prompt.txt" "$GEN_DIR/vision_$(date '+%H%M%S').txt"

# Viewer – kun for deg
cat << 'EOVIEW' > "$GEN_DIR/view.sh"
#!/bin/bash
qlmanage -p "$(find . -name 'vision_*.txt' | head -n 1)" >/dev/null 2>&1 &
EOVIEW
chmod +x "$GEN_DIR/view.sh"

# Logg
echo "✅ Hidden visual manifestert i $GEN_DIR" >> ~/GinieSystem/Logs/hidden_vision.log
echo "🔐 Lukkede spor. Kun GINIE vet."
