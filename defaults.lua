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
        args = {
          quality = 80,
          resize = "600x600",
          colorspace = "sRGB",
        },
        ---@type function|string
        cmd = function(_)
          return "magick '%{path}' -colorspace %{colorspace} -resize %{resize} -quality %{quality} '%{out}'"
        end,
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
        args = {
          resize = "100x100",
          coalesce = "-coalesce",
          -- colors = "256",
          background = "none",
          layers = "optimize",
        },
        -- *** Show original gif file ***
        -- ---@type function|string
        -- cmd = function(_)
        --   return "" -- No conversion for gif
        -- end,
        -- preview_path = function(ctx)
        --   return ctx.source -- Show the original gif file
        -- end,
        ---@type function|string
        cmd = function(_)
          return "magick '%{path}' %{coalesce} -resize %{resize} -background %{background} -layers %{layers} '%{out}'"
        end,
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
        args = {
          quality = 80,
          seek_time = 10,
          resize = 640,
        },
        cmd = function(_)
          return "ffmpegthumbnailer -s %{resize} -q %{quality} -t %{seek_time} -loglevel error -i '%{path}' -o '%{out}'"
        end,
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
        args = {
          density = 120,
          page = 0,
          quality = 80,
          resize = "600x600",
          colorspace = "sRGB",
        },
        cmd = function(_)
          return 'magick -colorspace %{colorspace} -density %{density} "%{path}[%{page}]" -flatten -resize %{resize} -quality %{quality} "%{out}"'
        end,
        preview_path = function(ctx)
          local path = string.format("%s/%s.jpg", ctx.cache_dir, ctx.hash)
          return path
        end,
      },
    },
  },
}

return config
