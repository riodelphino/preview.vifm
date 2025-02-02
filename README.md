# preview.vifm

A previewing script for image/video on vifm.


## Features

   - Preview image/video as jpg
   - Faster previewing with cache files
   - Batch generation for all matched files in current dir
   - Modifiable graphic protocol to preview
   - Logging


## Ensured to work

- MacOS
   - Without nvim  
      ✓ [vifm](https://github.com/vifm/vifm) < kitty  
      ✓ [vifm](https://github.com/vifm/vifm) < tmux < kitty  
   - With nvim  
      ✓ [vifm](https://github.com/vifm/vifm) < nvim < kitty  
      △ [vifm](https://github.com/vifm/vifm) < nvim < tmux < kitty (`clear` not works)  

> [!Warning]
> Not tested in ohter OS or terminal apps.


## Not fully functional

The images are shown disturbed & overlapped in `vifm on nvim on tmux`, with plugins like [vifm.vim](https://github.com/vifm/vifm.vim) or [fm.nvim](https://github.com/is0n/fm-nvim).  
Because of not working `clear` command.


## Graphic protocols

Works: `kitten icat`  
Not tested: `timg`, `img2sixel`, `imgcat`, `chafa`, etc


## Files

```txt
├── README.md      : this file  
├── config         : config file  
├── config.default : default config file  
└── preview        : script  
```

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
   - ffmpegthumbnailer
   - kitten icat (or other graphic protocols)
```

## Install

```bash
cd ~/.config/vifm/scripts
git clone https://github.com/riodelphino/preview.vifm/
ln -s preview.vifm/preview preview # vifm do not read scripts's sub dir somewhy, so link it.
```

## Setup

Follow these 5 steps.


### 1. zsh or bash

Add this code to `~/.zshrc` or `~/.bashrc`

```bash
export VIFM_PREVIEW_UUID="$(uuidgen)"
export VIFM_PREVIEW_TTY="$(tty)"
```

This code records `tty` like `/dev/tts001` on terminal init.  
`UUID` is set for future expansion.

Remember to execute `source ~/.zshrc` in terminal.

> [!Note]
> Only terminal returns `tty` correctry.
> `tty` command on vifmrc returns error, like `not a tty`.
> That's the reason for inserting this code.


### 2. Config

Default settings are in `config.default`.  
Copy it & rename to `config`, then modify it.

If `config` not exists, plugin uses `config.default`.

config.default:
```bash
#!/bin/bash

# Log
LOG_ENABLED=false # `true` cause a slight performance overhead

# Cache
if [ -n "$XDG_CACHE_HOME" ]; then
   CACHE_DIR="$XDG_CACHE_HOME/vifm/preview"
else
   CACHE_DIR="$HOME/.cache/vifm/preview"
fi

# nvim
NVIM_SHIFT_X=1 # {shift_x} : Adjust x position in nvim (for float border thickness)
NVIM_SHIFT_Y=1 # {shift_y} : Adjust y position in nvim (for float border thickness)

# Preview command
SHOW_CMD_TEMPLATE='kitten icat --clear --stdin=no --place=%pwx%ph@%pxx%py --scale-up --transfer-mode=file "%file" >%tty <%tty'
CLEAR_CMD_TEMPLATE='kitten icat --clear --silent %N >%tty <%tty &'

# Images
IMAGE_QUALITY=80     # {quality}        : Thumbnail quality
IMAGE_SIZE="600x600" # {width}x{height} : Thumbnail size

# Videos
VIDEO_QUALITY=80   # {quolity}    : Thumbnail quality
VIDEO_SEEK_TIME=10 # {percentage} : Seek time (%) of the total video duration
VIDEO_SIZE=640     # {size}       : Thumbnail size. cropped to fit within {size}x{size}
```

> [!Note]
> The placeholders `%pw`, `%ph`, `%px`, `%py`, `%file`, and `%tty` will be replaced with their actual values in preview command.

> [!Note]
> ex.) IMAGE_SIZE="1376x1617"  
> Set measured exact size for your vifm window in bare terminal, then remove '--scale-up' option from SHOW_CMD_TEMPLATE.  
> It allows faster previw, but increases cache file size.




#### Sample for other graphic protocols

```bash
# --- timg
# Sorry, NOT WORKS CORRECTLY. It shows disturbed color & text block images.
SHOW_CMD_TEMPLATE='timg -p sixel -g %pwx%ph "%file"'
CLEAR_CMD_TEMPLATE='timg -clear'
```


### 3. vifmrc

Add this code to `~/.config/vifmrc`

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


### 4. nvim

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
This saves x,y,w,h values to environmental variables, and `preview` command uses them for adjusting showing position.

### 5. vifm

To get faster previewing, add below code to `vifmrc`.

```vim
set previewoptions+=graphicsdelay:0
```


## Known issues

- [ ] Cannot generate correct hash filename for `2025-01-27 10.41.34.mov`, which has '.' in basename.
- [ ] 'clear' not works in `vifm < nvim < tmux`.
- [ ] Async generation all files not works. It freeze `vifm` for a while.

### (Resolved) tty

`tty` command returns the tty value like `/dev/ttys001` on a bare terminal or on a terminal with tmux.
But `tty` command returns `not a tty` in `vifmrc` or `nvim`.  
**Resolved** by [this sh code](#1-zsh-or-bash)

Additionally...
Without the `tty` like `zsh -c 'setsid kitten icat --stdin=no --use-window-size $COLUMNS,$LINES,3000,2000 --transfer-mode=file myimage.png'` not works for me. 
Though that sample code is on kitty official site.


### (Resolved) Images are shown in out of place

Floating x/y pos | signcolumn | bufferline are the cause.  
Almost **resolved** by [this lua code](#4-nvim).  
And `set signcolumn=auto` is recommended in nvim's `init.lua`.


## TODO

- [ ] Move enviromental variables to .env
- [ ] install/uninstall by MakeFile like [https://github.com/eylles/vifm-sixel-preview/blob/master/Makefile](https://github.com/eylles/vifm-sixel-preview/blob/master/Makefile)

