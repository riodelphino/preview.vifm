local config = {
  cache = {
    dir = os.getenv("HOME") .. "/.cache/vifm/preview",
    hash_cmd = "shasum", -- "shasum256"
  },

  log = {
    enabled = false,
    path = os.getenv("HOME") .. "/.cache/vifm/preview" .. "/log",
  },

  command = {
    show = "kitten icat --clear --stdin=no --place=%{width}x%{height}@%{x}x%{y} --scale-up --transfer-mode=file '%{path}' >%{tty} <%{tty}",
    -- clear = "kitten icat --clear --silent %N >%{tty} <%{tty} &", -- "%N" cause error
    clear = "kitten icat --clear --silent >%{tty} <%{tty}",
  },

  actions = {
    image = {
      patterns = {
        "*.bmp",
        "*.jpg",
        "*.jpeg",
        "*.png",
        "*.xpm",
        "*.avif",
        "*.webp",
        "*.heic",
      },
      generate = {
        cmd = "magick '%{src}' -colorspace sRGB -resize 600x600 -quality 80 '%{dst}'",
        preview_path = function(ctx)
          local path = string.format("%s/%s.jpg", ctx.cache_dir, ctx.hash)
          return path
        end,
      },
    },

    gif = {
      patterns = {
        "*.gif",
      },
      generate = {
        cmd = "magick '%{src}' -coalesce -resize 100x100 -background none -layers optimize '%{dst}'",
        preview_path = function(ctx)
          local path = string.format("%s/%s.gif", ctx.cache_dir, ctx.hash)
          return path
        end,
      },
    },

    video = {
      patterns = {
        "*.avi",
        "*.mp4",
        "*.wmv",
        "*.dat",
        "*.3gp",
        "*.ogv",
        "*.mkv",
        "*.mpg",
        "*.mpeg",
        "*.vob",
        "*.fl[icv]",
        "*.m2v",
        "*.mov",
        "*.webm",
        "*.ts",
        "*.mts",
        "*.m4v",
        "*.r[am]",
        "*.qt",
        "*.divx",
        "*.as[fx]",
      },
      generate = {
        cmd = "ffmpegthumbnailer -s 640 -q 8 -t 10 -i '%{src}' -o '%{dst}'",
        preview_path = function(ctx)
          local path = string.format("%s/%s.jpg", ctx.cache_dir, ctx.hash)
          return path
        end,
      },
    },

    -- ERROR ?? 出力されない
    pdf = {
      patterns = { "*.pdf" },
      generate = {
        cmd = 'magick -colorspace sRGB -density 120 "%{src}[0]" -flatten -resize 600x600 -quality 80 "%{dst}"',
        preview_path = function(ctx)
          local path = string.format("%s/%s.jpg", ctx.cache_dir, ctx.hash)
          return path
        end,
      },
    },
  },
}

return config
