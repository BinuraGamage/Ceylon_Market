#!/bin/bash

# =========================================================
# Ceylon Market - Launcher Icon Shrinker Helper
# =========================================================
# The raw icon can appear too large because generic masks
# aggressively crop the edges. This script scales the content
# down while keeping the original canvas size.
# =========================================================

# ---> CHANGE THIS VARIABLE to adjust the size! (0-100) <---
SCALE_PERCENT=70

# =========================================================

echo "⏳ Shrinking icon to ${SCALE_PERCENT}%..."

# Generate padded icon
magick convert assets/icon.png -resize "${SCALE_PERCENT}%" -background transparent -gravity center -extent 192x192 assets/icon_padded.png

echo "✅ Generated assets/icon_padded.png at ${SCALE_PERCENT}% scale!"
echo "⏳ Running flutter_launcher_icons..."

dart run flutter_launcher_icons

echo "🎉 Done! Your icons have been updated. Rebuild your app to see the changes."
