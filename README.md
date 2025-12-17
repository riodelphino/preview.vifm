# preview.vifm

A faster previewing script for image/video/pdf on vifm.

https://github.com/user-attachments/assets/a0ef0f53-ee6a-4ddc-86c0-5e4d15c917c9

Pictures from <a href="https://unsplash.com/ja/@jeremythomasphoto?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Jeremy Thomas</a> on <a href="https://unsplash.com/ja/%E5%86%99%E7%9C%9F/%E9%9D%92%E3%81%A8%E7%B4%AB%E3%81%AE%E9%8A%80%E6%B2%B3%E3%83%87%E3%82%B8%E3%82%BF%E3%83%AB%E5%A3%81%E7%B4%99-E0AHdsENmDg?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a> 


## Features

Main features
- Preview image/video/pdf (as jpg images)
- Cache preview files (much faster than direct preview)
- Async generating for current dir
- Re-generate preview file when the current image/video/pdf file is updated
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
   action    : image | video | pdf | clear | refresh | delete | dir
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

   Generate a preview file for a pdf:
      preview pdf %c %pw %ph %px %py

   Clear the preview in screen:
      preview clear

   Refresh preview files for current dir:
      preview refresh %d

   Delete all preview files:
      preview delete

   (Legacy) Generate previews for images/videos/pdfs in a directory:
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
let $IMAGE_QUALITY = 80                     " {0-100}            : Thumbnail quality (%)
let $IMAGE_RESIZE = '600x600'               " '{width}x{height}' : Thumbnail size
let $IMAGE_COLORSPACE_CMYK_TO_SRGB = 'true' " {'true'|'false'}   : Convert 'CMYK' to 'sRGB' or not
" Image files filter
let $IMAGE_PATTERNS = '*.bmp,*.jpg,*.jpeg,*.png,*.gif,*.xpm,*.avif,*.webp,*.heic'

" Videos
let $VIDEO_QUALITY = 80   " {0-100} : Thumbnail quality (%)
let $VIDEO_SEEK_TIME = 10 " {0-100} : Seek time (%) of the total video duration
let $VIDEO_RESIZE = 640   " {size}  : Thumbnail size. cropped to fit within {size}x{size}
" Video files filter
let $VIDEO_PATTERNS = '*.avi,*.mp4,*.wmv,*.dat,*.3gp,*.ogv,*.mkv,*.mpg,*.mpeg,*.vob,*.fl[icv],*.m2v,*.mov,*.webm,*.ts,*.mts,*.m4v,*.r[am],*.qt,*.divx,*.as[fx]'

" PDFs
let $PDF_DENSITY = 120                    " {number}          : Pixel resolution
let $PDF_COLORSPACE_CMYK_TO_SRGB = 'true' " {'true'|'false'}  : Convert 'CMYK' to 'sRGB' or not
let $PDF_PAGE_TO_EXTRACT = 0              " {0-?}             : Page num to extract
let $PDF_QUALITY = 80                     " {0-100}           : Thumbnail quality (%)
let $PDF_RESIZE = '600x600'               " '{width}x{heiht}' : Thumbnail size
" PDF files filter
let $PDF_PATTERNS = '*.pdf'
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

" For PDFs
fileviewer {*.pdf},<pdf/*>
   \ preview pdf %c %pw %ph %px %py
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

If you use vifm on nvim, follow this step.

With `lazy.nvim`, for `fm-nvim`:
```lua
return {
  'is0n/fm-nvim',
  cmd = { 'Vifm' },
  config = function()

    -- Modify vifm_cmd
    require('fm-nvim').setup({
      cmds = {
        vifm_cmd = 'vifm --server-name vifm-nvim-' .. vim.fn.getpid(), -- Set servername to vifm
      }
    })

    vim.api.nvim_create_autocmd({ 'WinEnter', 'WinResized', 'VimResized' }, {
      pattern = { '*' },
      callback = function(ev)
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
        function get_envs()
          local win_id = vim.api.nvim_get_current_win()
          local config = vim.api.nvim_win_get_config(win_id)
          local y, x = unpack(vim.fn.win_screenpos(win_id))
          local envs = {
            { 'VIFM_PREVIEW_WIN_RELATIVE', config.relative },
            { 'VIFM_PREVIEW_WIN_SPLIT', config.split },
            { 'VIFM_PREVIEW_WIN_X', config.col or x - 1 },
            { 'VIFM_PREVIEW_WIN_Y', config.row or y - 1 },
            { 'VIFM_PREVIEW_WIN_W', config.width },
            { 'VIFM_PREVIEW_WIN_H', config.height },
            { 'VIFM_PREVIEW_WIN_BORDER_WIDTH', get_floating_window_border_width(config) },
          }
          return envs
        end
        if ev.event == 'WinEnter' then
          local envs = get_envs()
          for _, env in ipairs(envs) do
            local env_name, value = unpack(env)
            vim.env[env_name] = value
          end
        else
          if vim.bo.filetype == 'Fm' and vim.bo.buftype == 'terminal' then -- Filtering for fm-nvim
            local vifm_cmds = {}
            local envs = get_envs()
            for _, v in ipairs(envs) do
              local env_name, value = unpack(v)
              local cmd
              if type(value) == 'string' then
                cmd = string.format('let $%s = "%s"', env_name, value)
              elseif type(value) == 'number' then
                cmd = string.format('let $%s = %d', env_name, value)
              end
              table.insert(vifm_cmds, cmd)
            end
            local vifm_cmd_str = table.concat(vifm_cmds, ' | ')
            local vifm_servername = 'vifm-nvim-' .. vim.fn.getpid()
            vim.fn.system({
              'vifm',
              '--server-name',
              vifm_servername,
              '--remote',
              '-c',
              vifm_cmd_str,
            })
            -- for checking
            -- print(vifm_servername)
            -- print(vifm_cmd_str)
          end
        end
        -- for checking
        -- print(vim.inspect({
        --   x = config.col or x,
        --   y = config.row or y,
        --   w = config.width,
        --   h = config.height,
        --   split = config.split,
        --   relative = config.relative,
        --   bw = get_floating_window_border_width(config),
        -- }))
        -- end
      end,
    })
  end,
}
```
(Need `vifm.vim` example code)

This code saves relative,split,x,y,w,h,bw(boder_width) values to vifm's environmental variables.  
Then `preview` command uses them for adjusting position.

The w,h are for future expansion.


## Tips

### Faster preview

1. Set measured exact size for your vifm window in bare terminal. (e.g `IMAGE_SIZE="1376x1617"`)
2. Then remove `--scale-up` option from `SHOW_CMD_TEMPLATE`.  

> [!Warning]
> This increases cache file size instead.
> And requires no-changing layout. (e.g. Measured in 2 panes, then change to 3 panes, or +/- pane size. It makes this tips meaningless.)


## Known Issues

- [ ] When previewing image/video, the preview is disturbed on window resize.
- [ ] 'clear' not works in `vifm on nvim on tmux`. It causes overlaping images.
- [ ] If `notify.nvim` is shown in nvim, the vifm preview images are disturbed on floating window.
- [ ] The images are shown disturbed & overlapped in `tmux + nvim + vifm(with plugin)`, Because of not working `clear` command.


## Resolved Issues

### Cannot recieve updating of enviromental variables

Updating `vim.env.{environmental_value_name}` on `WinResize` and `VimResize` doesn't work.  
`vifm` and `preview.vifm` cannot recieve the updated environmental variables.  
Can fetch only the variables are set on `vifm` startup.

Resolved by [#4-optional-initlua-in-nvim](#4-optional-initlua-in-nvim).  

- `vifm` has remote control option.
- Set `--servername` option on vifm startup command. (e.g. `"vifm --servername vifm-nvim-" .. vim.fn.getpid()` )
- Use the servername and `--remote -c` to set environmental variables for the specific `vifm` instance.


### tty not works

`tty` command returns like `/dev/ttys001` values on a `bare terminal` or `tmux`.
But `tty` command returns `not a tty` strings in `vifmrc` or `nvim`.  

Additionally...
Without the `tty` like `zsh -c 'setsid kitten icat --stdin=no --use-window-size $COLUMNS,$LINES,3000,2000 --transfer-mode=file myimage.png'` not works for me. 
Though that sample code is on kitty official site.

Resolved by [#1-zshrc-or-bashrc](#1-zshrc-or-bashrc)


### Shown in out of place in floating window

Floating x,y positions or border size are the cause.  
And `set signcolumn=auto` is recommended in nvim's `init.lua`.

Resolved by [#4-optional-initlua-in-nvim](#4-optional-initlua-in-nvim).  

- Add `WinEnter` autocmd to get the current window's x,y positions.


## TODO

- [ ] Make image/video/pdf generating comands configurable and extensible for any filetype
- [ ] Supports gif images?
- [ ] Supports other terminal apps
- [ ] Supports other terminal graphics tools
- [ ] install/uninstall by MakeFile? (like [https://github.com/eylles/vifm-sixel-preview/blob/master/Makefile](https://github.com/eylles/vifm-sixel-preview/blob/master/Makefile))

