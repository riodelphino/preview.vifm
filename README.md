# preview.vifm

A previewing script for image/video on vifm.


## Features

   - Preview image/video as jpg
   - Faster previewing with cache files
   - Batch generation for all matched files in current dir
   - Modifiable graphic protocol to preview
   - Logging


## Ensured to work
It works on kitty or tmux on kitty, in MacOS.

- MacOS
  - [vifm](https://github.com/vifm/vifm) < kitty
  - [vifm](https://github.com/vifm/vifm) < tmux < kitty

> [!Warning]
> Not tested in ohter OS or terminal apps.


## Not fully functional

The images are shown disturbed in nvim, with plugins like [vifm.vim](https://github.com/vifm/vifm.vim) or [fm.nvim](https://github.com/is0n/fm-nvim).  
Because of the position out of place & not working `clear` command.


- MacOS
  - [vifm.vim](https://github.com/vifm/vifm.vim) or [fm.nvim](https://github.com/is0n/fm-nvim) < nvim < kitty
     - A. Shown in out of place
  - [vifm.vim](https://github.com/vifm/vifm.vim) or [fm.nvim](https://github.com/is0n/fm-nvim) < nvim < tmux < kitty
     - A. Shown in out of place
     - B. `clear` not works at all

**A. Shown in out of place**
Floating x/y pos | signcolumn | bufferline are the cause.  
In full size window mode, adding `export $VIFM_PREVIEW_PX_ADJUST=1` & `export $VIFM_PREVIEW_PY_ADJUST=1` & applying them, might resolve it.  
In floating window mode, getting the position x/y (=top/left) from the `win` might resolve it.  

**B. 'clear' not works at all**
The cause is Unknown.


## Graphic protocols

Works: `kitten icat`
Not tested: `timg`, `img2sixel`, `imgcat`, `chafa`, etc


## Command usage

```txt
USAGE:
   preview [action] [file] [pw] [ph] [px] [py] [patterns]

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


## Technical info

`tty` command returns the tty value like `/dev/ttys001` on a bare terminal or on a terminal with tmux.
But `tty` command returns `not a tty` in `vifmrc` or `nvim`.  
So I put the line `$VIFM_PREVIEW_TTY="$(tty)"` in `~/.zshrc` to pick up the the current terminal's tty at startup.

Additionally, the preview function didn't work without using the `tty` like `--stdin=no` option of `kitten icat`.


## TODO & Known problems

- [ ] Disturbance in nvim
   - [ ] Omit previewing if in vifm on nvim?
   - [ ] Or fix them 
      - [ ] Maybe 'clear' not works
      - [ ] Misalignment in px py
- [ ] Async generation not works
   - [ ] It freeze the vifm, until the generation of all preview images in dir is complete.
- [ ] Move enviromental variables to .env
- [ ] install/uninstall by MakeFile like [https://github.com/eylles/vifm-sixel-preview/blob/master/Makefile](https://github.com/eylles/vifm-sixel-preview/blob/master/Makefile)

