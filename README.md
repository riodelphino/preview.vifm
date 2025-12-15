# preview.vifm

A faster previewing script for image/video on vifm.

https://github.com/user-attachments/assets/a0ef0f53-ee6a-4ddc-86c0-5e4d15c917c9

Pictures from <a href="https://unsplash.com/ja/@jeremythomasphoto?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Jeremy Thomas</a> on <a href="https://unsplash.com/ja/%E5%86%99%E7%9C%9F/%E9%9D%92%E3%81%A8%E7%B4%AB%E3%81%AE%E9%8A%80%E6%B2%B3%E3%83%87%E3%82%B8%E3%82%BF%E3%83%AB%E5%A3%81%E7%B4%99-E0AHdsENmDg?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a> 


## Features

Main features
- Preview images/videos (as jpg images)
- Cache preview files (much faster than direct preview)
- Async generating for current dir
- Re-generate preview file when the current image/video file is updated
- Modifiable graphic protocol commands

Additional
- (For nvim) Correct the %px %py position in nvim plugins or floating window
- Logging for debug


## Dependencies

- [ImageMagick](https://github.com/ImageMagick/ImageMagick)
- [ffmpegthumbnailer](https://github.com/dirkvdb/ffmpegthumbnailer)
- Graphic protocol: [kitten icat](https://sw.kovidgoyal.net/kitty/kittens/icat/) (or others)


## Supported Environments

Currently ensured to work with:
- MacOS
   - kitty
      - ✓ vifm directly use (Need to set `TERM` environmental variable)
      - nvim
         - ✓ [vifm.vim](https://github.com/vifm/vifm.vim)
         - ✓ [fm-nvim](https://github.com/is0n/fm-nvim)
      - tmux
         - ✓ vifm (directly use)
         - nvim
            - △ [vifm.vim](https://github.com/vifm/vifm.vim) (`clear` not works)  
            - △ [fm-nvim](https://github.com/is0n/fm-nvim) (`clear` not works)  
- Linux
   - Not tested
- Windows
   - Not tested


## Graphic protocols

Currently supported:
- `kitten icat`  

Not tested:
- `timg`
- `img2sixel`
- `imgcat`
- `chafa`
- e.t.c.


## Structure

```txt
├── README.md                : this file  
├── preview.conf.default.vim : default config file  
└── preview                  : script
```

## Command usage

```man
USAGE:
   preview [action] [file] [pw] [ph] [px] [py]

ARGS:
   action    : clear | dir | image | video ...
   path      : target path
   pw        : panel width
   ph        : panel height
   px        : panel x
   py        : panel y

EXAMPLE CODE:
   Generate a preview file for a image:
      preview image %c %pw %ph %px %py

   Generate a preview file for a video:
      preview video %c %pw %ph %px %py

   Clear the preview in screen:
      preview clear

   Refresh preview files for current dir:
      preview refresh %d

   Delete all preview files:
      preview delete

   (Legacy) Generate previews for images/videos in a directory:
      preview dir %d
```

## Install

If your vifm config dir is `~/.config/vifm`:
```bash
cd ~/.config/vifm
mkdir scripts
cd scripts
git clone https://github.com/riodelphino/preview.vifm

# Link the command (vifm doesn't read the sub-dir in scripts folder as the document says.)
ln -s preview.vifm/preview preview

# Copy the config
cp preview.vifm/preview.conf.default.vim ../preview.conf.vim
```

## Setup

Follow these 3 or 4 steps.  

1. `.zshrc` or `.bashrc`
2. `preview.conf.vim`
3. `vifmrc`
4. (Optional) `init.lua` in nvim

(It would be nice if the steps could be reduced.)


### 1 .zshrc or .bashrc

Add these code to `~/.zshrc` or `~/.bashrc`

```bash
export VIFM_PREVIEW_TTY="$(tty)"      # Records `tty` on terminal init (e.g. like `/dev/tts001`)
export VIFM_PREVIEW_UUID="$(uuidgen)" # `UUID` is set for future expansion
```
Ensure to execute `source ~/.zshrc` or `source ~/.bashrc` in terminal.

> [!Note]
> Though the `tty` command on terminal returns tty correctry, the same command on vifmrc doesn't return tty. (e.g. `not a tty` error)
> Ensure to get tty with above code.

> [!Warning]
> This setup is for `vifm on tmux`.
> If you use `vifm` directly , the `TERM` environmental variable has to be set. (e.g. `export TERM=xterm-256color`)
> Otherwise, the preview shows error, because the `tty` command returns `` empty string.

### 2. preview.conf.vim

Default settings are stored in `preview.conf.default.vim`.  
Copy it to `~/.config/vifm/preview.conf.vim` as user config. Then modify it.

preview.conf.default.vim:
```vim
" Cache
if $XDG_CACHE_HOME != ''
   let $CACHE_DIR = $XDG_CACHE_HOME . '/vifm/preview'
else
   let $CACHE_DIR = $HOME . '/.cache/vifm/preview'
endif

" Log
let $LOG_ENABLED = 1                " {0=true|1=false} : Enable/Disable logging
let $LOG_PATH = $CACHE_DIR . '/log' " {path}           : Log filename

" Preview commands
let $SHOW_CMD_TEMPLATE = 'kitten icat --clear --stdin=no --place=%pwx%ph@%pxx%py --scale-up --transfer-mode=file "%file" >%tty <%tty'
let $CLEAR_CMD_TEMPLATE = 'kitten icat --clear --silent %N >%tty <%tty &'

" Images
let $IMAGE_QUALITY = 80                " {quality}        : Thumbnail quality
let $IMAGE_SIZE = '600x600'            " {width}x{height} : Thumbnail size
let $IMAGE_COLORSPACE_CMYK_TO_SRGB = 0 " {0=true|1=false} : Convert 'CMYK' to 'sRGB' or not
" Image files filter
let $IMAGE_PATTERNS = '*.bmp,*.jpg,*.jpeg,*.png,*.gif,*.xpm,*.avif,*.webp,*.heic'

" Videos
let $VIDEO_QUALITY = 80   " {quolity}    : Thumbnail quality
let $VIDEO_SEEK_TIME = 10 " {percentage} : Seek time (%) of the total video duration
let $VIDEO_SIZE = 640     " {size}       : Thumbnail size. cropped to fit within {size}x{size}
" Video files filter
let $VIDEO_PATTERNS = '*.avi,*.mp4,*.wmv,*.dat,*.3gp,*.ogv,*.mkv,*.mpg,*.mpeg,*.vob,*.fl[icv],*.m2v,*.mov,*.webm,*.ts,*.mts,*.m4v,*.r[am],*.qt,*.divx,*.as[fx]'
```
The placeholders `%pw`, `%ph`, `%px`, `%py`, `%file`, and `%tty` will be replaced with their actual values in preview command.


#### Preview commands for graphic protocols

##### kitten icat
WORKS. Same above.
```bash
SHOW_CMD_TEMPLATE='kitten icat --clear --stdin=no --place=%pwx%ph@%pxx%py --scale-up --transfer-mode=file "%file" >%tty <%tty'
CLEAR_CMD_TEMPLATE='kitten icat --clear --silent %N >%tty <%tty &'
```

##### timg
Currently `timg` is not supported. Colors & text block images are disturbed somehow.  
Need your inspection and PR.
```bash
# --- timg
SHOW_CMD_TEMPLATE='timg -p sixel -g %pwx%ph "%file"'
CLEAR_CMD_TEMPLATE='timg -clear'
```

##### Others
NEED YOUR PR!!

### 3. vifmrc

Add this code to `~/.config/vifm/vifmrc`

```vim
" Load config
source $VIFM/preview.conf.vim
" or
" Load config with defaults
" source $VIFM/scripts/preview.vifm/preview.conf.default.vim " Set defaults
" source $VIFM/preview.conf.vim " Set only your custom lines

" For images
fileviewer {*.bmp,*.jpg,*.jpeg,*.png,*.gif,*.xpm,*.avif,*.webp,*.heic},<image/*>
   \ preview image %c %pw %ph %px %py
   \ %pc
   \ preview clear

" For videos
fileviewer {*.avi,*.mp4,*.wmv,*.dat,*.3gp,*.ogv,*.mkv,*.mpg,*.mpeg,*.vob,*.fl[icv],*.m2v,*.mov,*.webm,*.ts,*.mts,*.m4v,*.r[am],*.qt,*.divx,*.as[f},
   \ preview video %c %pw %ph %px %py
   \ %pc
   \ preview clear

" == Disabled because DirEnter flickers vifm window ==
" For directory
" autocmd DirEnter * !preview dir %d

" To get faster previewing, add this line
set previewoptions+=graphicsdelay:0

" Keybinds
nnoremap pr :!preview refresh %d<cr>:echo "Refreshed preview caches for" expand('%"d')<cr>
nnoremap pd :!preview delete<cr>:echo "Deleted all preview caches."<cr>
```

> [!Note]
> `%pc` is just a delimiter, between displaying command and cleaning command.


### 4. (Optional) init.lua in nvim

If you use vifm on nvim, set this code to `init.lua`.  
With `lazy.nvim`, you can set it to `config = funciton() ... end` section on the settings for [vifm.vim](https://github.com/vifm/vifm.vim) / [fm-nvim](https://github.com/is0n/fm-nvim)

```lua
-- init.lua
function get_floating_window_border_width(config)
   -- If not a floating window
   if config.relative == '' then return 0 end

   -- Get border and determine width
   local border = config.border
   if type(border) == 'table' then
      return #border > 0 and 1 or 0
   elseif type(border) == 'string' then
      return border == 'none' and 0 or 1
   end

   return 0 -- Unknown border type
end

function get_window_info()
   local win_id = vim.api.nvim_get_current_win()
   local config = vim.api.nvim_win_get_config(win_id)
   local x = config.col
   local y = config.row
   local w = config.width
   local h = config.height
   local bw = get_floating_window_border_width(config)
   return x, y, w, h, bw
end

vim.api.nvim_create_autocmd({ 'WinEnter' }, {
   pattern = { '*' },
   callback = function()
      local x, y, w, h, bw = get_window_info()
      vim.env.VIFM_PREVIEW_WIN_X = x
      vim.env.VIFM_PREVIEW_WIN_Y = y
      vim.env.VIFM_PREVIEW_WIN_W = w
      vim.env.VIFM_PREVIEW_WIN_H = h
      vim.env.VIFM_PREVIEW_WIN_BORDER_WIDTH = bw
      print(string.format('%dx%d @ %dx%d (%d)', w, h, x, y, bw)) -- Check code
   end,
})
-- NOTE: 'TermEnter' fails at the first `:Vifm` execution
```
This saves x,y,w,h,boder_width values to environmental variables, and `preview` command uses them for adjusting showing position.

(The w,h are for future expansion.)

## Tips

### Faster preview

1. Set measured exact size for your vifm window in bare terminal. (e.g `IMAGE_SIZE="1376x1617"`)
2. Then remove `--scale-up` option from `SHOW_CMD_TEMPLATE`.  

> [!Warning]
> This increases cache file size instead.
> And requires no-changing layout. (e.g. Measured in 2 panes, then change to 3 panes, or +/- pane size. It makes this tips meaningless.)


## Known Issues

- [ ] 'clear' not works in `vifm on nvim on tmux`. It causes overlaping images.
- [ ] If `notify.nvim` is shown in nvim, the vifm preview images are disturbed.
- [ ] The images are shown disturbed & overlapped in `tmux + nvim + vifm(with plugin)`, Because of not working `clear` command.


## Resolved Issues

### tty not works

**Resolved** by [#1-zshrc-or-bashrc](#1-zshrc-or-bashrc)

`tty` command returns like `/dev/ttys001` values on a `bare terminal` or `tmux`.
But `tty` command returns `not a tty` strings in `vifmrc` or `nvim`.  

Additionally...
Without the `tty` like `zsh -c 'setsid kitten icat --stdin=no --use-window-size $COLUMNS,$LINES,3000,2000 --transfer-mode=file myimage.png'` not works for me. 
Though that sample code is on kitty official site.


### Shown in out of place

Almost **resolved** by [#4-optional-initlua-in-nvim](#4-optional-initlua-in-nvim).  

Floating x,y positions or border size are the cause.  
And `set signcolumn=auto` is recommended in nvim's `init.lua`.


## TODO

- [ ] Supports gif images?
- [ ] Supports other terminal apps
- [ ] Supports other terminal graphics tools
- [ ] install/uninstall by MakeFile? (like [https://github.com/eylles/vifm-sixel-preview/blob/master/Makefile](https://github.com/eylles/vifm-sixel-preview/blob/master/Makefile))

