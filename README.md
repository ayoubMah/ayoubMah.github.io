# ayoubMah.github.io

My personal blog — built with [Hugo](https://gohugo.io/) + [Obsidian](https://obsidian.md/), deployed on **GitHub Pages**.

## Cross-platform workflow

Write in Obsidian, publish from anywhere.

### On Windows

```pwsh
.\forWind.ps1
```

Pulls latest content → syncs `blog/BLOG/` and `blog/ILT/` from the vault → processes images → builds with Hugo → commits & pushes to `master`. GitHub Actions auto-deploys to `gh-pages`.

### On Linux

```bash
./forLinux.sh
```

Same workflow. Vault paths: `$HOME/Documents/obsidianDir/ayoubObsidian/{BLOG,ILT,Attachments}`.

## How it works

```
Obsidian Vault
  ├── blog/BLOG/          ← blog posts (markdown)
  ├── blog/ILT/           ← ILT notes (markdown)
  ├── attachments/        ← images
  └── .obsidian/          ← plugins, templates, config
        └── plugins/templater-obsidian/
              ├── data.json   ← per-folder auto-templates
              └── Template/
                    ├── Blog.md   ← auto-applied in BLOG/
                    └── ITL.md    ← auto-applied in ILT/
        │
        ▼  (forWind.ps1 / forLinux.sh)
        │
  Hugo Project (this repo)
  ├── content/posts/      ← synced from vault BLOG/
  ├── content/ilt/        ← synced from vault ILT/
  ├── static/images/      ← images copied from vault attachments/
  │
  ▼  (hugo --minify)
  │
  public/                  ← static site
  │
  ▼  (git push → GitHub Actions)
  │
  gh-pages                 ← live at ayoubmah.github.io
```

## Templates

New notes in `blog/BLOG/` or `blog/ILT/` automatically get the right template via [Templater](https://github.com/SilentVoid13/Templater):

| Folder | Template | Frontmatter |
|---|---|---|
| `blog/BLOG/` | `Template/Blog.md` | `title, date, draft: true, categories: [blog]` |
| `blog/ILT/` | `Template/ITL.md` | `title, date, draft: true, categories: [ILT]` |

Posts are created as `draft: true` — remove or set `draft: false` when ready to publish.

## Requirements

| Tool | Windows | Linux |
|---|---|---|
| Hugo extended | `choco install hugo-extended` | `sudo snap install hugo` |
| Git | git-scm.com | `apt install git` |
| PowerShell | Comes with Windows | `apt install pwsh` |
| rsync | — | `apt install rsync` |
| Python 3 | python.org | `apt install python3` |

## License

CC BY-NC 4.0
