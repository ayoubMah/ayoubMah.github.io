#!/usr/bin/env python3
import os
import re
import shutil
import subprocess

# === CONFIG PATHS ===
obsidian_blog_dir = "/home/ayoub/Documents/obsidianDir/ayoubObsidian/BLOG/"
attachments_dir = "/home/ayoub/Documents/obsidianDir/ayoubObsidian/Attachments"
hugo_posts_dir = "/home/ayoub/Documents/ayBlog/content/posts"
static_images_dir = "/home/ayoub/Documents/ayBlog/static/images"

# === Step 1: Sync Obsidian → Hugo posts ===
print("🔄 Syncing Obsidian → Hugo posts...")
os.makedirs(hugo_posts_dir, exist_ok=True)
subprocess.run([
    "rsync", "-av", "--delete",
    obsidian_blog_dir, hugo_posts_dir
], check=True)

# === Step 2: Ensure static/images exists ===
os.makedirs(static_images_dir, exist_ok=True)

# === Step 3: Process each Markdown file ===
print("📝 Processing Markdown files...")
image_pattern = re.compile(
    r'!?\[\[([^]]*\.(?:png|jpg|jpeg|gif|webp))\]\]', flags=re.IGNORECASE
)

for root, _, files in os.walk(hugo_posts_dir):
    for fname in files:
        if fname.lower().endswith(".md"):
            fpath = os.path.join(root, fname)

            with open(fpath, "r", encoding="utf-8") as f:
                content = f.read()

            images = image_pattern.findall(content)
            for image in images:
                # Create Markdown image syntax
                markdown_image = f"![Image Description](/images/{image.replace(' ', '%20')})"
                content = re.sub(
                    r'!?\[\[(' + re.escape(image) + r')\]\]',
                    markdown_image,
                    content
                )

                # Copy image to Hugo static/images
                source_img_path = os.path.join(attachments_dir, image)
                if os.path.exists(source_img_path):
                    shutil.copy(source_img_path, static_images_dir)
                    print(f"📷 Copied: {image}")
                else:
                    print(f"⚠️ Missing image in Attachments: {image}")

            # Write updated markdown back
            with open(fpath, "w", encoding="utf-8") as f:
                f.write(content)

print("✅ Done! Now run: hugo server")

