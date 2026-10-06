#!/usr/bin/env python3
"""Three-way sync between an Obsidian vault and the Hugo content folders.

Shared by forWind.ps1 and forLinux.sh so both machines run the SAME logic.
Git is the transport between machines; each machine keeps its own vault and
its own `.sync-state.json` (gitignored) recording, per file, the hash of the
published content at the last successful sync. Comparing vault and git
against that base tells us who changed what:

    vault   git      ->  action
    same    same         nothing
    edited  same         publish vault -> content
    same    edited       pull content -> vault         (edit from other machine)
    edited  edited       vault wins, git copy backed up (conflict)
    same    deleted      delete from vault             (delete from other machine)
    deleted same         delete from content           (local delete)
    new     -            publish
    -       new          pull into vault               (post from other machine)

With no base (first run) nothing is ever deleted, and on a disagreement
the published (git) version wins and the vault copy is backed up.
Every overwritten or deleted file is copied to .sync-backup/<timestamp>/ first.

Usage: sync.py --repo R --blog DIR --ilt DIR --attachments DIR
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import time
from urllib.parse import unquote

IMG_EXT = r"(?:png|jpe?g|gif|webp|svg|ico)"
WIKI_IMG = re.compile(r"!?\[\[([^\]|]*\." + IMG_EXT + r")(?:\|[^\]]*)?\]\]", re.IGNORECASE)
MD_IMG = re.compile(r"!\[([^\]]*)\]\(/images/([^)\s]+\." + IMG_EXT + r")\)", re.IGNORECASE)


def read_text(path):
    with open(path, "rb") as f:
        data = f.read()
    if data.startswith(b"\xef\xbb\xbf"):
        data = data[3:]
    return data.decode("utf-8").replace("\r\n", "\n")


def write_text(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def digest(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def list_md(root):
    out = {}
    if not os.path.isdir(root):
        return out
    for dirpath, dirnames, files in os.walk(root):
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        for name in files:
            if name.lower().endswith(".md"):
                full = os.path.join(dirpath, name)
                out[os.path.relpath(full, root).replace(os.sep, "/")] = full
    return out


class Syncer:
    def __init__(self, args):
        self.repo = os.path.abspath(args.repo)
        self.attachments = args.attachments
        self.static_images = os.path.join(self.repo, "static", "images")
        self.state_file = os.path.join(self.repo, ".sync-state.json")
        self.backup_root = os.path.join(self.repo, ".sync-backup", time.strftime("%Y%m%d-%H%M%S"))
        self.sections = [
            ("posts", args.blog, os.path.join(self.repo, "content", "posts")),
            ("ilt", args.ilt, os.path.join(self.repo, "content", "ilt")),
        ]
        self.base = {}
        if os.path.exists(self.state_file):
            with open(self.state_file, encoding="utf-8-sig") as f:
                self.base = json.load(f)
        self.first_run = not self.base
        self.state = {}
        self.warnings = []

    # Obsidian ![[img.png]]  ->  Hugo ![img](/images/img.png), copying the image into static/.
    def to_hugo(self, text, copy_images):
        def repl(m):
            name = os.path.basename(m.group(1).strip())
            if copy_images:
                src = os.path.join(self.attachments, name)
                if os.path.exists(src):
                    os.makedirs(self.static_images, exist_ok=True)
                    shutil.copy2(src, self.static_images)
                elif not os.path.exists(os.path.join(self.static_images, name)):
                    self.warnings.append(f"image not found in attachments: {name}")
            return f"![{os.path.splitext(name)[0]}](/images/{name.replace(' ', '%20')})"
        return WIKI_IMG.sub(repl, text)

    # Reverse of to_hugo, so a post pulled from the other machine renders in Obsidian.
    # Only links that to_hugo produced (alt == file stem) are reversed.
    def to_obsidian(self, text):
        def repl(m):
            name = unquote(m.group(2))
            if m.group(1) != os.path.splitext(name)[0]:
                return m.group(0)
            src = os.path.join(self.static_images, name)
            dst = os.path.join(self.attachments, name)
            if os.path.exists(src) and not os.path.exists(dst):
                os.makedirs(self.attachments, exist_ok=True)
                shutil.copy2(src, dst)
            return f"![[{name}]]"
        return MD_IMG.sub(repl, text)

    def backup(self, path, label):
        dst = os.path.join(self.backup_root, label)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(path, dst)
        return dst

    def remove(self, path, label):
        self.backup(path, label)
        os.remove(path)

    def run(self):
        for prefix, vault_dir, content_dir in self.sections:
            os.makedirs(vault_dir, exist_ok=True)
            os.makedirs(content_dir, exist_ok=True)
            vault = list_md(vault_dir)
            content = list_md(content_dir)
            known = {k[len(prefix) + 1:] for k in self.base if k.startswith(prefix + "/")}
            for rel in sorted(set(vault) | set(content) | known):
                self.sync_one(f"{prefix}/{rel}", vault_dir, content_dir, rel,
                              vault.get(rel), content.get(rel))

        with open(self.state_file, "w", encoding="utf-8", newline="\n") as f:
            json.dump(self.state, f, indent=2, ensure_ascii=False, sort_keys=True)
        for w in self.warnings:
            print(f"  WARNING: {w}")
        if os.path.isdir(self.backup_root):
            print(f"  Backups of overwritten/deleted files: {self.backup_root}")

    def sync_one(self, key, vault_dir, content_dir, rel, vpath, gpath):
        base = self.base.get(key)
        vpath_target = os.path.join(vault_dir, *rel.split("/"))
        gpath_target = os.path.join(content_dir, *rel.split("/"))

        vtext = self.to_hugo(read_text(vpath), copy_images=False) if vpath else None
        gtext = read_text(gpath) if gpath else None
        vh = digest(vtext) if vtext is not None else None
        gh = digest(gtext) if gtext is not None else None

        def publish():
            write_text(gpath_target, self.to_hugo(read_text(vpath), copy_images=True))
            self.state[key] = digest(read_text(gpath_target))

        def pull():
            write_text(vpath_target, self.to_obsidian(gtext))
            self.state[key] = gh

        if vpath and gpath:
            if vh == gh:
                if WIKI_IMG.search(read_text(vpath)):
                    self.to_hugo(read_text(vpath), copy_images=True)  # keep images present
                self.state[key] = gh
            elif base is None:
                self.backup(vpath, f"vault/{key}")
                pull()
                self.warnings.append(f"{key}: vault and git differ with no sync history; "
                                     "kept the published version, vault copy backed up")
            elif vh == base:
                pull()
                print(f"  Updated from git:  {key}")
            elif gh == base:
                publish()
                print(f"  Published edit:    {key}")
            else:
                self.backup(gpath, f"git/{key}")
                publish()
                self.warnings.append(f"{key}: edited on BOTH machines; this machine's version "
                                     "wins, the other one is in the backup folder")
        elif vpath:
            if base is None:
                publish()
                print(f"  New post:          {key}")
            elif vh == base:
                self.remove(vpath, f"vault/{key}")
                print(f"  Deleted (remote):  {key}")
            else:
                publish()
                self.warnings.append(f"{key}: deleted on the other machine but edited here; kept it")
        elif gpath:
            if base is None:
                pull()
                print(f"  New from git:      {key}")
            elif gh == base:
                self.remove(gpath, f"git/{key}")
                print(f"  Deleted (local):   {key}")
            else:
                pull()
                self.warnings.append(f"{key}: deleted here but edited on the other machine; restored it")
        # neither side has it: drop it from state


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--repo", required=True)
    p.add_argument("--blog", required=True)
    p.add_argument("--ilt", required=True)
    p.add_argument("--attachments", required=True)
    args = p.parse_args()
    if not os.path.isdir(args.repo):
        sys.exit(f"--repo does not exist: {args.repo}")
    Syncer(args).run()


if __name__ == "__main__":
    main()
