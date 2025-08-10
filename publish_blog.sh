#!/bin/bash
set -e

# ====== CONFIG ======
OBSIDIAN_BLOG="$HOME/Documents/obsidianDir/ayoubObsidian/BLOG"
HUGO_CONTENT="$HOME/Documents/ayBlog/content/posts"
ATTACHMENTS_DIR="$HOME/Documents/obsidianDir/ayoubObsidian/Attachments"
STATIC_IMAGES_DIR="$HOME/Documents/ayBlog/static/images"
GITHUB_REPO="git@github.com:ayoubMah/ayoubMah.github.io.git"  # SSH is safer
HUGO_THEME="hello-friend-ng"
# ====================

echo "🔄 Syncing Obsidian → Hugo content..."
rsync -av --delete "$OBSIDIAN_BLOG/" "$HUGO_CONTENT/"

echo "🖼 Processing image links..."
python3 <<EOF
import os
import re
import shutil

posts_dir = "$HUGO_CONTENT"
attachments_dir = "$ATTACHMENTS_DIR"
static_images_dir = "$STATIC_IMAGES_DIR"

for filename in os.listdir(posts_dir):
    if filename.endswith(".md"):
        filepath = os.path.join(posts_dir, filename)

        with open(filepath, "r", encoding="utf-8") as file:
            content = file.read()

        images = re.findall(r'\[\[([^]]*\.(?:png|jpg|jpeg|gif))\]\]', content, flags=re.IGNORECASE)

        for image in images:
            markdown_image = f"![Image Description](/images/{image.replace(' ', '%20')})"
            content = content.replace(f"[[{image}]]", markdown_image)

            image_source = os.path.join(attachments_dir, image)
            if os.path.exists(image_source):
                shutil.copy(image_source, static_images_dir)

        with open(filepath, "w", encoding="utf-8") as file:
            file.write(content)

print("✅ Markdown files processed and images copied successfully.")
EOF

echo "🏗 Building site with Hugo..."
cd "$HOME/Documents/ayBlog"
hugo -t "$HUGO_THEME"

echo "📤 Deploying to GitHub Pages..."
git add .
git commit -m "Auto-publish: $(date '+%Y-%m-%d %H:%M:%S')" || true
git push origin master

echo "✅ Blog published successfully!"

