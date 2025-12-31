local config = {
  cache = {
    enabled = true, -- Not implemented yet
    dir = os.getenv("HOME") .. "/.cache/vifm/preview", -- WARN: `:preview delete` command will execute `rm -rf` in this dir
    hash_cmd = "shasum", -- or "shasum256"
  },

  log = {
    enabled = false,
    path = os.getenv("HOME") .. "/.local/state/vifm/preview.log",
  },

  common = {
    cmd = {
      show = "kitten icat --clear --stdin=no --place=%{width}x%{height}@%{x}x%{y} --scale-up --transfer-mode=file '%{dst}' >%{tty} <%{tty}",
      clear = "kitten icat --clear --silent >%{tty} <%{tty}",
    },
  },

  preview = {
    delay = 200, -- Not implemented yet
  },

  actions = {
    -- Image
    image = {
      patterns = "*.bmp,*.jpg,*.jpeg,*.png,*.xpm,*.avif,*.webp,*.heic", -- Set the same patterns as fileviewr
      cmd = {
        generate = "magick '%{src}' -colorspace sRGB -resize 600x600 -quality 80 '%{dst}'",
        -- Action-specific {show|clear} command are available. Fallback to `common.cmd.{show|clear}` if nil.
        -- show = "",
        -- clear = "",
      },
      cache = { ext = "jpg" },
    },
    -- Gif
    gif = {
      patterns = "*.gif",
      cmd = { generate = "magick '%{src}' -coalesce -resize 200x200 -background none -layers optimize '%{dst}'" },
      cache = { ext = "gif" },
    },
    -- Video
    video = {
      patterns = "*.avi,*.mp4,*.wmv,*.dat,*.3gp,*.ogv,*.mkv,*.mpg,*.mpeg,*.vob,*.fl[icv],*.m2v,*.mov,*.webm,*.ts,*.mts,*.m4v,*.r[am],*.qt,*.divx,*.as[fx]",
      cmd = { generate = "ffmpegthumbnailer -s 640 -q 8 -t 10 -i '%{src}' -o '%{dst}'" },
      cache = { ext = "jpg" },
    },
    -- PDF
    pdf = {
      patterns = "*.pdf",
      cmd = { generate = 'magick -colorspace sRGB -density 120 "%{src}[0]" -flatten -resize 600x600 -quality 80 "%{dst}"' },
      cache = { ext = "jpg" },
    },
  },
}

return config
