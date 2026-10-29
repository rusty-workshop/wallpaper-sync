# wallpaper-sync

Pulls new wallpapers from [JaKooLit/Wallpaper-Bank](https://github.com/JaKooLit/Wallpaper-Bank)
into `~/Pictures/wallpapers` on a schedule, without touching anything
already there.

Built after tracing where `~/Pictures/wallpapers` came from: that folder is
mostly sourced from this one upstream repo, but nothing kept it in sync, and there was a real
2026-08-22 incident where files in it went zero-byte during a dothop.

## What it does

- Shallow-clones (or updates) Wallpaper-Bank into `~/.cache/wallpaper-sync/`.
- `rsync --ignore-existing`s `wallpapers/` (+ `astralbed.png`) into
  `~/Pictures/wallpapers` — **only ever adds new files**, never overwrites
  or deletes. My own non-upstream wallpapers (the AI-generated
  `desert-*` set) are never touched.
- Flags (doesn't fix) any zero-byte file already sitting in
  `~/Pictures/wallpapers`, in case that corruption pattern recurs.
- Sends a desktop notification (`notify-send`) summarizing what was added,
  or a critical one if zero-byte files are found.

## Usage

```bash
./sync-wallpapers.sh            # sync for real
./sync-wallpapers.sh --dry-run  # show what would be added, change nothing
```

## Install as a weekly timer

```bash
mkdir -p ~/.config/systemd/user
cp systemd/wallpaper-sync.{service,timer} ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now wallpaper-sync.timer
```

## License

AGPL-3.0-or-later.
