# preview.vifm

A faster previewing script for image/video/pdf on vifm.

https://github.com/user-attachments/assets/a0ef0f53-ee6a-4ddc-86c0-5e4d15c917c9

Pictures from <a href="https://unsplash.com/ja/@jeremythomasphoto?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Jeremy Thomas</a> on <a href="https://unsplash.com/ja/%E5%86%99%E7%9C%9F/%E9%9D%92%E3%81%A8%E7%B4%AB%E3%81%AE%E9%8A%80%E6%B2%B3%E3%83%87%E3%82%B8%E3%82%BF%E3%83%AB%E5%A3%81%E7%B4%99-E0AHdsENmDg?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a> 


## Features

Main features
- Preview image/gif/video/pdf/e.t.c.
- Cache preview files (much faster than direct preview)
- Async generating for current dir
- Re-generate preview file when the current image/video/pdf/e.t.c. file is updated
- Add custom actions (e.g. gif, sound)
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
         - △ [fm-nvim](https://github.com/is0n/fm-nvim) (See [Known Issues](#known-issues))
      - tmux
         - ✓ vifm (directly use)
         - nvim
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
├── README.md    : This file  
├── init.lua     : Entry point
├── util.lua     : Utility functions
└── defaults.lua : Default config file  
```

## Handler usage

```man
USAGE:
   #preview.vifm#{subcmd} {action}

ARGS:
   subcmd    : preview | clear | refresh | delete
   action    : image | video | pdf | e.t.c (only `preview` can accept `action` arg)
```

EXAMPLE CODE:

Generate a preview file for image action:
```vim
fileviewer {*.bmp,*.jpg,*.jpeg,*.png,*.xpm,*.avif,*.webp,*.heic},<image/*>
   \ #preview.vifm#preview image
   \ %pc
   \ #preview.vifm#clear

" `%c %px %py %pw %ph` are given by `info` table arg to lua function. So it's not necessary to set here.
" `%pc` is just a delimiter, between displaying command and cleaning command.
```

## Commands

Refresh cached preview files for current dir:
`:preview refresh<cr>`

Delete all cached preview files:
`:preview delete<cr>`


## Install

If your vifm config dir is `~/.config/vifm`:
```bash
cd ~/.config/vifm
mkdir scripts
cd scripts
git clone https://github.com/riodelphino/preview.vifm

# Copy the config
cp preview.vifm/defaults.lua ../preview.lua
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

### 2. preview.lua

Default settings are stored in `defaults.lua`.  
Copy it to `~/.config/vifm/preview.lua` as user config. Then modify it.

defaults.lua:
```lua
local config = {
  cache = {
    enabled = true, -- TODO: Implement a conditional branch for caching (or in generate()?); should switch how the dst path is resolved.
    dir = os.getenv("HOME") .. "/.cache/vifm/preview", -- WARN: Be carefule to set this. `:preview delete` command will execute `rm -rf` in this dir
    hash_cmd = "shasum", -- or "shasum256"
  },

  log = {
    enabled = false,
    path = os.getenv("HOME") .. "/.local/state/vifm/preview.log",
  },

  common = {
    cmd = { -- TODO: Copy cmd.show, cmd.clear to each actions on startup? Then use it?
      show = "kitten icat --clear --stdin=no --place=%{width}x%{height}@%{x}x%{y} --scale-up --transfer-mode=file '%{dst}' >%{tty} <%{tty}",
      clear = "kitten icat --clear --silent >%{tty} <%{tty}",
    },
  },

  preview = {
    delay = 200, -- ms
  },

  actions = {
    -- Image
    image = {
      patterns = "*.bmp,*.jpg,*.jpeg,*.png,*.xpm,*.avif,*.webp,*.heic", -- TODO: Accepts "<image/*>" and "*.bmp,*.jpg" text
      cmd = {
        generate = "magick '%{src}' -colorspace sRGB -resize 600x600 -quality 80 '%{dst}'",
      },
      cache = {
        ext = "jpg",
      },
    },
    -- Gif
    gif = {
      patterns = "*.gif",
      cmd = {
        generate = "magick '%{src}' -coalesce -resize 200x200 -background none -layers optimize '%{dst}'",
      },
      cache = {
        ext = "gif",
      },
    },
    -- Video
    video = {
      patterns = "*.avi,*.mp4,*.wmv,*.dat,*.3gp,*.ogv,*.mkv,*.mpg,*.mpeg,*.vob,*.fl[icv],*.m2v,*.mov,*.webm,*.ts,*.mts,*.m4v,*.r[am],*.qt,*.divx,*.as[fx]",
      cmd = {
        generate = "ffmpegthumbnailer -s 640 -q 8 -t 10 -i '%{src}' -o '%{dst}'",
      },
      cache = {
        ext = "jpg",
      },
    },
    -- PDF
    pdf = {
      patterns = "*.pdf",
      cmd = {
        generate = 'magick -colorspace sRGB -density 120 "%{src}[0]" -flatten -resize 600x600 -quality 80 "%{dst}"',
      },
      cache = {
        ext = "jpg",
      },
    },
  },
}

return config
```
The placeholders `%{width}`, `%{height}`, `%{x}`, `%{y}`, `%{dst}`, and `%{tty}` will be replaced with their actual values in preview command.
`%{src}` and `%{dst}` are also replaced to actual source and destination path in `actions.{action_name}.generate.cmd`.


#### Preview commands for graphic protocols

##### kitten icat
WORKS. Same above.
```lua
common = {
  cmd = { -- kitten icat
    show = "kitten icat --clear --stdin=no --place=%{width}x%{height}@%{x}x%{y} --scale-up --transfer-mode=file '%{dst}' >%{tty} <%{tty}",
    clear = "kitten icat --clear --silent >%{tty} <%{tty}",
  },
},
```

##### timg
Currently `timg` is not supported. Colors & text block images are disturbed somehow.  
Need your inspection and PR.
```lua
common = {
  cmd = { -- timg (Not works for now)
    show = "timg -p sixel -g %{width}x%{height} '%{dst}'",
    clear = "timg -clear",
  },
},
```

##### Others
NEED YOUR PR!!

### 3. vifmrc

Add this code to `~/.config/vifm/vifmrc`

```vim
" For gif (Should set before `images`)
fileviewer { *.gif }
   \ #preview.vifm#preview gif
   \ %pc
   \ #preview.vifm#clear

" For images
fileviewer <image/*>
   \ #preview.vifm#preview image
   \ %pc
   \ #preview.vifm#clear

" For videos
fileviewer <video/*>
   \ #preview.vifm#preview video
   \ %pc
   \ #preview.vifm#clear

" For PDFs
fileviewer { *.pdf }
   \ #preview.vifm#preview pdf
   \ %pc
   \ #preview.vifm#clear

" To get faster previewing, add this line
set previewoptions+=graphicsdelay:0

" Keymaps
nnoremap <silent> pr :preview refresh<cr>
nnoremap <silent> pd :preview delete<cr>

" Set servername to env (for future expansion)
let $VIFM_SERVER_NAME = v:servername
```

### 4. (Optional) init.lua in nvim

If you use vifm on nvim, follow this step.

With `lazy.nvim`, for `fm-nvim`:
```lua
return {
  'is0n/fm-nvim',
  cmd = { 'Vifm' },
  config = function()
    local servername = 'vifm-nvim-' .. vim.fn.getpid()

    -- Modify vifm_cmd
    require('fm-nvim').setup({
      cmds = {
        vifm_cmd = 'vifm --server-name ' .. servername, -- Set servername to vifm
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
            -- { 'VIFM_SERVER_NAME', servername },
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

This code saves `relative`, `split`, `x`, `y`, `w`, `h`, `bw(boder_width)` values to vifm's environmental variables.  
Then `preview` command uses them for adjusting position.

The w,h are for future expansion.


## Tips

### Faster preview

1. Set measured exact size for your vifm window in bare terminal.
2. Set it to `actions.{action_name}.generate.cmd`. (e.g `-resize 1376x1617`)
3. Then remove `--scale-up` option from `commands.show` template.  

> [!Warning]
> This increases cache file size instead.
> And requires no-changing layout. (e.g. Measured in 2 panes, then change to 3 panes, or +/- pane size. It makes this tips meaningless.)


## Known Issues

- [ ] The preview is disturbed on terminal window resize.
- [ ] nvim
  - [ ] `kitty + nvim + vifm` cause error:
      - `This terminal emulator does not support the graphics protocol, use a terminal emulator such as kitty that does support it`
  - [ ] `clear` not works in `tmux + nvim + vifm`. It causes overlaping images.
  - [ ] If `notify.nvim` is shown in nvim, the vifm preview images are disturbed on floating window.


## Resolved Issues

### Cannot recieve updating of enviromental variables

Updating `vim.env.{environmental_value_name}` on `WinResize` and `VimResize` doesn't work.  
`vifm` and `preview.vifm` cannot recieve the updated environmental variables.  
Can fetch only the variables are set on `vifm` startup.

Resolved by [#4-optional-initlua-in-nvim](#4-optional-initlua-in-nvim).  

- `vifm` has remote control option.
- Set `--server-name` option on vifm startup command. (e.g. `"vifm --server-name vifm-nvim-" .. vim.fn.getpid()` )
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

- [ ] Supports other terminal apps
- [ ] Supports other terminal graphics protocols
- [ ] Wanna support async cursor movement and preview (Needs `coroutine` enabled in vifm lua)

## Related Projects

- [eylles/vifm-sixel-preview](https://github.com/eylles/vifm-sixel-preview/tree/master)


- 
