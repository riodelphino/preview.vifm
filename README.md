# preview.vifm

A previewing script for image/video on vifm.


## Features

   - Image preview
   - Video preview (as jpg)
   - Cache files with hash filename (for faster viewing)
   - Async generation for all files in current dir
   - Previewing commands are modifiable. ex.) kitten icat, img2sixel, imgcat, etc. But not tested.
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
   ./preview.sh [action] [file] [pw] [ph] [px] [py] [patterns]

ARGS:
   action    : clear | image | video ...
   file      : target filename
   pw        : panel width
   ph        : panel height
   px        : panel x
   py        : panel y
   patterns  : file patterns (delimiter = ',')

SAMPLE CODE:
   Clear:
      preview clear
   For images:
      preview image %c %pw %ph %px %py '*.jpg,*.png'
   For videos:
      preview video %c %pw %ph %px %py '*.mp4,*.mov'

DEPENDENCIES:
   - imagemagick
   - ffmpeg
   - kitten icat (or other graphic protocols)
```

## Install

FIXME: install/uninstall by MakeFile like
[https://github.com/eylles/vifm-sixel-preview/blob/master/Makefile](https://github.com/eylles/vifm-sixel-preview/blob/master/Makefile)

```bash
cd ~/.config/vifm/scripts
git clone https://github.com/riodelphino/preview.vifm/
ln -s preview.vifm/preview preview # vifm do not read scripts's sub dir somewhy, so link it.
```

## Setup


### in bash or zsh

Add code to `~/.zshrc` or `~/.bashrc`
```bash
# preview.vifm
export VIFM_PREVIEW_CACHE_DIR="$HOME/.cache/vifm/preview"
export VIFM_PREVIEW_LOG_ENABLED=0 # 0: No logging | 1: Logging
export VIFM_PREVIEW_UID="$(uuidgen)"
export VIFM_PREVIEW_TTY="$(tty)"
export VIFM_PREVIEW_SHOW='kitten icat --stdin=no --place=%pwx%ph@%pxx%py --scale-up --transfer-mode=file "%file" >%tty <%tty'
export VIFM_PREVIEW_CLEAR='kitten icat --clear --silent %N >%tty <%tty &'
```
Then, remember to execute `source ~/.zshrc` in terminal

> [!Note]
> %pw %ph %px %py %file %tty, are replaced to the actual values in preview command.

> [!Note]
> Only terminal returns `tty` correctry. `tty` command on vifmrc returns error, like `not a tty`. That's why using enviromental variables on terminal's init.


### in vifmrc

Add code to `~/.config/vifmrc`

```vim


" For images
let $IMAGE_PATTERNS = '*.bmp,*.jpg,*.jpeg,*.png,*.gif,*.xpm,*.avif,*.webp,*.heic'
fileviewer {*.bmp,*.jpg,*.jpeg,*.png,*.gif,*.xpm,*.avif,*.webp,*.heic},<image/*>
   \ preview image %c %pw %ph %px %py $IMAGE_PATTERNS
   \ %pc
   \ preview clear

" For videos
let $VIDEO_PATTERNS = '*.avi,*.mp4,*.wmv,*.dat,*.3gp,*.ogv,*.mkv,*.mpg,*.mpeg,*.vob,*.fl[icv],*.m2v,*.mov,*.webm,*.ts,*.mts,*.m4v,*.r[am],*.qt,*.divx,*.as[fx]'
fileviewer {*.avi,*.mp4,*.wmv,*.dat,*.3gp,*.ogv,*.mkv,*.mpg,*.mpeg,*.vob,*.fl[icv],*.m2v,*.mov,*.webm,*.ts,*.mts,*.m4v,*.r[am],*.qt,*.divx,*.as[f},
   \ preview video %c %pw %ph %px %py $VIDEO_PATTERNS
   \ %pc
   \ preview clear
```

> [!Note]
> Variable expansion is not allowed in file pattern list, like `fileviwer {$VIDEO_PATTERNS}`. Hmmm, It's redundant...

> [!Note]
> `%pc` is just a delimiter, between displaying command and cleaning command.


## Known problems

- [ ] Freeze the vifm, until the async(?) generation of all preview images in dir is complete.


