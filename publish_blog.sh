#!/usr/bin/env bash
set -euo pipefail

# === CONFIG ===
OBSIDIAN_POSTS="$HOME/Documents/obsidianDir/ayoubObsidian/BLOG"
OBSIDIAN_ILT="$HOME/Documents/obsidianDir/ayoubObsidian/ILT"
ATTACHMENTS="$HOME/Documents/obsidianDir/ayoubObsidian/Attachments"

HUGO_POSTS="$HOME/Documents/ayBlog/content/posts"
HUGO_ILT="$HOME/Documents/ayBlog/content/ilt"
STATIC_IMAGES="$HOME/Documents/ayBlog/static/images"

HUGO_DIR="$HOME/Documents/ayBlog"
HUGO_THEME="hello-friend-ng"
GITHUB_REPO="git@github.com:ayoubMah/ayoubMah.github.io.git"  # SSH form

mkdir -p "$HUGO_POSTS" "$HUGO_ILT" "$STATIC_IMAGES"

echo "🔄 Rsync: BLOG -> content/posts"
rsync -av --delete "$OBSIDIAN_POSTS/" "$HUGO_POSTS/"

echo "🔄 Rsync: ILT  -> content/ilt"
rsync -av --delete "$OBSIDIAN_ILT/" "$HUGO_ILT/"

# Export paths for the python block to read safely
export HUGO_POSTS HUGO_ILT ATTACHMENTS STATIC_IMAGES

echo "🖼 Converting Obsidian image links and copying images..."
python3 <<'PY'
import os, re, shutil

posts_dir = os.environ['HUGO_POSTS']
ilt_dir = os.environ['HUGO_ILT']
attachments = os.environ['ATTACHMENTS']
static_images = os.environ['STATIC_IMAGES']

# matches ![[file.png]] or [[file.png]] or [[file.png|alt]]
pattern = re.compile(r'!?\[\[([^]\|]*\.(?:png|jpg|jpeg|gif|webp|svg|ico))(?:\|[^\]]*)?\]\]', re.IGNORECASE)

for root_dir in (posts_dir, ilt_dir):
    if not os.path.isdir(root_dir):
        continue
    for root, _, files in os.walk(root_dir):
        for fname in files:
            if not fname.lower().endswith('.md'):
                continue
            fpath = os.path.join(root, fname)
            with open(fpath, 'r', encoding='utf-8') as f:
                content = f.read()

            matches = pattern.findall(content)
            for match in matches:
                img_name = os.path.basename(match.strip())
                alt_text = os.path.splitext(img_name)[0]
                md_img = f'![{alt_text}](/images/{img_name.replace(" ", "%20")})'
                # Replace occurrences with possible |alt text
                content = re.sub(r'!?\[\[' + re.escape(match) + r'(?:\|[^\]]*)?\]\]', md_img, content)
                src = os.path.join(attachments, img_name)
                if os.path.exists(src):
                    shutil.copy(src, static_images)

            with open(fpath, 'w', encoding='utf-8') as f:
                f.write(content)
print("✅ Images converted and copied.")
PY

echo "🏗 Building site with Hugo..."
cd "$HUGO_DIR"
hugo -t "$HUGO_THEME" --minify



echo "📤 Deploying to GitHub Pages..."
git add .
git commit -m "Auto-publish: $(date '+%Y-%m-%d %H:%M:%S')" || true
git push origin master

echo "✅ Blog published successfully!"

