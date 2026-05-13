---
title: Obsidian + Hugo + GitHub Pages Blog Setup Guide
date: 2025-08-10
draft: false
tags:
  - blog
  - obsidian
---

## Overview

This setup creates an automated blog workflow where you write in Obsidian, push to GitHub, and GitHub Actions automatically builds and deploys your Hugo site.

## Phase 1: Local Setup

### Step 1: Install Required Tools

1. **Install Hugo**
    
    
    ```bash
    # Windows (using Chocolatey)
    choco install hugo-extended
    
    # macOS (using Homebrew)
    brew install hugo
    
    # Linux (using Snap)
    sudo snap install hugo
    ```
    
2. **Install Git** (if not already installed)
    - Download from [git-scm.com](https://git-scm.com/)
3. **Install Obsidian**
    - Download from [obsidian.md](https://obsidian.md/)

### Step 2: Create Your Hugo Site

1. **Generate Hugo site**
    
    
    ```bash
    hugo new site my-blog
    cd my-blog
    ```
    
2. **Initialize Git repository**
    
    
    ```bash
    git init
    git branch -m main
    ```
    
3. **Choose and install a Hugo theme**
    
    
    ```bash
    # Example with PaperMod theme
    git submodule add https://github.com/adityatelange/hugo-PaperMod themes/PaperMod
    
    # Or clone without submodule (simpler for beginners)
    git clone https://github.com/adityatelange/hugo-PaperMod themes/PaperMod
    ```
    

### Step 3: Configure Hugo

1. **Edit `hugo.toml` (or `config.toml`)**
    
    
    ```toml
    baseURL = 'https://yourusername.github.io/your-repo-name'
    languageCode = 'en-us'
    title = 'My Blog'
    theme = 'PaperMod'
    
    [params]
    author = "Your Name"
    description = "My awesome blog"
    
    [menu]
    [[menu.main]]
    name = "Home"
    url = "/"
    weight = 10
    
    [[menu.main]]
    name = "Posts"
    url = "/posts/"
    weight = 20
    ```
    
2. **Create content structure**
    
    
    ```bash
    mkdir -p content/posts
    mkdir -p static/images
    ```
    

## Phase 2: Obsidian Integration

### Step 4: Setup Obsidian Vault

1. **Create Obsidian vault in Hugo content directory**
    - Open Obsidian
    - Choose "Open folder as vault"
    - Select your `my-blog/content` folder
2. **Configure Obsidian settings**
    - Go to Settings → Files & Links
    - Set "Default location for new notes" to `posts/`
    - Set "New link format" to "Relative path to file"
    - Enable "Use [[Wikilinks]]" if you want internal linking

### Step 5: Create Obsidian Templates

1. **Create templates folder**
    
    ```
    content/
    ├── posts/
    └── templates/
        └── blog-post.md
    ```
    
2. **Blog post template (`content/templates/blog-post.md`)**
    
    
    ```markdown
    ---
    title: "{{title}}"
    date: {{date}}
    draft: false
    tags: []
    categories: []
    description: ""
    ---
    
    # {{title}}
    
    Your content here...
    ```
    
3. **Configure Obsidian Templates plugin**
    - Go to Settings → Core plugins → Enable "Templates"
    - Set template folder to `templates`

## Phase 3: GitHub Setup

### Step 6: Create GitHub Repository

1. **Create new repository on GitHub**
    - Name: `your-blog` or `yourusername.github.io`
    - Make it public
    - Don't initialize with README (you already have local repo)
2. **Connect local repo to GitHub**
    
    
    ```bash
    git remote add origin https://github.com/yourusername/your-repo-name.git
    ```
    

### Step 7: Create GitHub Actions Workflow

1. **Create workflow directory**
    
    
    ```bash
    mkdir -p .github/workflows
    ```
    
2. **Create deployment workflow (`.github/workflows/deploy.yml`)**
    
    
    ```yaml
    name: Deploy Hugo site to Pages
    
    on:
      push:
        branches: ["master"] #or main 
      workflow_dispatch:
    
    permissions:
      contents: read
      pages: write
      id-token: write
    
    concurrency:
      group: "pages"
      cancel-in-progress: false
    
    defaults:
      run:
        shell: bash
    
    jobs:
      build:
        runs-on: ubuntu-latest
        steps:
          - name: Checkout
            uses: actions/checkout@v4
            with:
              submodules: recursive
    
          - name: Setup Hugo
            uses: peaceiris/actions-hugo@v2
            with:
              hugo-version: 'latest'
              extended: true
    
          - name: Setup Pages
            id: pages
            uses: actions/configure-pages@v3
    
          - name: Build with Hugo
            env:
              HUGO_ENVIRONMENT: production
              HUGO_ENV: production
            run: |
              hugo \
                --gc \
                --minify \
                --baseURL "${{ steps.pages.outputs.base_url }}/"
    
          - name: Upload artifact
            uses: actions/upload-pages-artifact@v2
            with:
              path: ./public
    
      deploy:
        environment:
          name: github-pages
          url: ${{ steps.deployment.outputs.page_url }}
        runs-on: ubuntu-latest
        needs: build
        steps:
          - name: Deploy to GitHub Pages
            id: deployment
            uses: actions/deploy-pages@v2
    ```
    

## Phase 4: GitHub Pages Configuration

### Step 8: Enable GitHub Pages

1. **Push your code first**
    
    
    ```bash
    git add .
    git commit -m "Initial blog setup"
    git push -u origin main
    ```
    
2. **Configure GitHub Pages**
    - Go to your repo → Settings → Pages
    - Source: "GitHub Actions"
    - The workflow will automatically deploy after the first push

## Phase 5: Content Creation Workflow

### Step 9: Daily Workflow

1. **Writing in Obsidian**
    - Open Obsidian vault (your Hugo content folder)
    - Create new note in `posts/` folder
    - Use your blog post template
    - Write your content using Markdown
2. **Hugo-specific front matter**
    
    
    ```markdown
    ---
    title: "My First Post"
    date: 2024-01-15T10:00:00Z
    draft: false
    tags: ["technology", "blogging"]
    categories: ["tutorial"]
    description: "Learn how to set up a blog with Hugo and Obsidian"
    ---
    ```
    
3. **Publishing workflow**
    
    
    ```bash
    # Test locally (optional)
    hugo server -D
    
    # Commit and push
    git add .
    git commit -m "New post: My First Post"
    git push
    ```
    

## Phase 6: Advanced Configuration

### Step 10: Optimize Obsidian for Hugo

1. **Install useful Obsidian plugins**
    - Templater (advanced templates)
    - Obsidian Git (auto-sync)
    - Tag Wrangler (manage tags)
2. **Configure Obsidian Git plugin**
    - Auto-pull: every 10 minutes
    - Auto-backup: every 10 minutes
    - This automates the git workflow

### Step 11: Hugo Customizations

1. **Add image handling**
    
    
    ```markdown
    # In your posts, reference images like:
    ![Alt text](../static/images/my-image.jpg)
    ```
    
2. **Configure Hugo for Obsidian links**
    - Install Hugo modules or use shortcodes for better wiki-link support

## Troubleshooting Tips

### Common Issues

1. **Theme not showing**: Ensure theme is properly installed and referenced in config
2. **Images not displaying**: Check image paths and Hugo static folder structure
3. **Build fails**: Check Hugo version compatibility with your theme
4. **Obsidian links**: Some Obsidian-specific syntax may need conversion for Hugo

### Useful Commands

```bash
# Test locally
hugo server -D

# Build site
hugo

# Check Hugo version
hugo version

# Create new post
hugo new posts/my-new-post.md
```

## Benefits of This Setup

- ✅ Write naturally in Obsidian with all its features
- ✅ Automatic deployment when you push changes
- ✅ Version control for all your content
- ✅ Fast, static site performance
- ✅ Free hosting on GitHub Pages
- ✅ Mobile editing possible through Obsidian mobile + GitHub

Your blog will be live at `https://yourusername.github.io/your-repo-name` after the first successful deployment!