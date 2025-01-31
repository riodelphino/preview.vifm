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
  - [vifm.vim](https://github.com/vifm/vifm.vim) or [fm.nvim](https://github.com/is0n/fm-nvim) < nvim < tmux < kitty
     - A. `clear` not works at all

**A. 'clear' not works at all**
The cause is Unknown.

**(Resolved) Shown in out of place**
Floating x/y pos | signcolumn | bufferline are the cause.  
In full size window mode, adding `export $VIFM_PREVIEW_PX_ADJUST=1` & `export $VIFM_PREVIEW_PY_ADJUST=1` & applying them, might resolve it.  
In floating window mode, getting the position x/y (=top/left) from the `win` might resolve it.  


## Graphic protocols

Works: `kitten icat`
Not tested: `timg`, `img2sixel`, `imgcat`, `chafa`, etc


## Files

├── README.md      : this file
├── config         : config file
├── config.default : default config file
└── preview        : script


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


### .zshrc or .bashrc

Add the code to `~/.zshrc` or `~/.bashrc`

```bash
export VIFM_PREVIEW_UUID="$(uuidgen)"
export VIFM_PREVIEW_TTY="$(tty)"
```

This code records `tty` like `/dev/tts001` on terminal init.  
`UUID` is set for future expansion.

Remember to execute `source ~/.zshrc` in terminal.

> [!Note]
> Only terminal returns `tty` correctry. `tty` command on vifmrc returns error, like `not a tty`.
> That's the reason for inserting this code.


## Config

Default settings are in `config.default`.  
Copy it & rename to `config`, then modify it.

If `config` not exists, plugin uses `config.default`.

config.default:
```bash
#!/bin/bash

# Cache
if [ -n "$XDG_CACHE_HOME" ]; then
   CACHE_DIR="$XDG_CACHE_HOME/vifm/preview"
else
   CACHE_DIR="$HOME/.cache/vifm/preview"
fi

# Log
LOG_ENABLED=1 # 0: No logging | 1: Logging (cause timeloss)

# Preview command
SHOW_CMD_TEMPLATE='kitten icat --clear --stdin=no --place=%pwx%ph@%pxx%py --scale-up --transfer-mode=file "%file" >%tty <%tty'
CLEAR_CMD_TEMPLATE='kitten icat --clear --silent %N >%tty <%tty &'

# Images
IMAGE_QUALITY=80
IMAGE_RESIZE="600x600" # the size of vifm window on full screen
# IMAGE_RESIZE="1376x1617" # Measured exact size for me, then remove '--scale-up' option from 'kitten icat'

# Videos
VIDEO_FRAME=1000      # frame num for cut, from the movie's start
VIDEO_SCALE="640:360" # width:height
# VIDEO_SCALE="1376:774" # Measured exact size for me, then remove '--scale-up' option from 'kitten icat'
```

> [!Note]
> %pw %ph %px %py %file %tty, are replaced to the actual values in preview command.



### Sample

```bash
# --- timg
# Not works correctly. It shows disturbed color & text block images.
SHOW_CMD_TEMPLATE='timg -p sixel -g %pwx%ph "%file"'
CLEAR_CMD_TEMPLATE='timg -clear'
```


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

### in init.lua of nvim
If you use vifm on nvim, set these code to `init.lua`.
```lua
-- init.lua
function get_window_position()
   local win = vim.api.nvim_get_current_win()
   local win_info = vim.api.nvim_win_get_config(win)
   local left = win_info.col
   local top = win_info.row
   local width = win_info.width
   local height = win_info.height
   return left, top, width, height
end

vim.api.nvim_create_autocmd({ 'BufEnter' }, {
   callback = function()
      local x, y, w, h = get_window_position()
      vim.env.VIFM_PREVIEW_WIN_X = x or 0
      vim.env.VIFM_PREVIEW_WIN_Y = y or 0
      vim.env.VIFM_PREVIEW_WIN_W = w or 0
      vim.env.VIFM_PREVIEW_WIN_H = h or 0
      -- print(string.format('%dx%d @ %dx%d', w, h, x, y)) -- for check
   end,
})
```
This saves x,y,w,h values to environmental variables, and `preview` uses them for adjusting showing position.


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

