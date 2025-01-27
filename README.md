# preview.sh

A previewing support script for image/video on vifm.


## Features

   - Image preview
   - Video preview (jpg)
   - Cache files with hash filename (for faster viewing)
   - Async generation for all files in current dir
   - Logging if needed

## Ensured to work on

   - MacOS
      - kitty
      - tmux on kitty
   
   > [!Warning]
   > Not tested in ohter OS or other terminal apps.



## Command usage

```txt
USAGE:
   ./preview.sh [filename] [ft_group] [process_type]

ARGS:
   filename      : target filename
   ft_group      : image : Use imagemagick
                   video : Use ffmpeg
   process_type  : single : Generate preview for the single file
                   all    : Generate previews for all files in the dir
DEPENDENCIES:
   - imagemagick
   - ffmpeg
   - kitten icat (or other graphic protocols)
```

## Install

```bash
cd ~/.config/vifm/plugins
git clone https://github.com/riodelphino/preview.vifm/
```

## Setup sample

Add below code to `~/.config/vifmrc`
(Sorry for dirty codes. I was unable to resolve the tty error when running kitten icat from within a script.)

```vim

" For images
fileviewer {*.bmp,*.jpg,*.jpeg,*.png,*.gif,*.xpm,*.avif,*.webp,*.heic},<image/*>
    \ kitten icat --transfer-mode=file --silent --scale-up --place=%pwx%ph@%pxx%py "$(~/.config/vifm/plugins/preview.vifm/preview.sh '%c' image single)" >/dev/tty </dev/tty %N &
    \ sh -c "$HOME/.config/vifm/plugins/preview.vifm/preview.sh '%c' image all" &
    \ %pc
    \ kitten icat --clear --silent >/dev/tty </dev/tty %N &

" For videos
fileviewer {*.avi,*.mp4,*.wmv,*.dat,*.3gp,*.ogv,*.mkv,*.mpg,*.mpeg,*.vob,*.fl[icv],*.m2v,*.mov,*.webm,*.ts,*.mts,*.m4v,*.r[am],*.qt,*.divx,*.as[fx]},
   \ kitten icat --transfer-mode=file --silent --scale-up --place=%pwx%ph@%pxx%py "$(~/.config/vifm/plugins/preview.vifm/preview.sh '%c' video single)" >/dev/tty </dev/tty %N &
   \ sh -c "$HOME/.config/vifm/plugins/preview.vifm/preview.sh '%c' video all" &
   \ %pc
   \ kitten icat --clear --silent >/dev/tty </dev/tty %N &
```

> [!Note]
> `%pc` is just a delimiter, between displaying command and cleaning command.

> [!Note]
> `kitten icat` and it’s options can be replaced to your own graphic protocol.


