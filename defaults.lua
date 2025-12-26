local config = {
  cache = {
    dir = os.getenv("HOME") .. "/.cache/vifm/preview",
    hash_cmd = "shasum", -- or "shasum256"
  },

  log = {
    enabled = true,
    path = os.getenv("HOME") .. "/.cache/vifm/preview/log",
  },

  command = {
    show = "kitten icat --clear --stdin=no --place=%{width}x%{height}@%{x}x%{y} --scale-up --transfer-mode=file '%{dst}' >%{tty} <%{tty}",
    clear = "kitten icat --clear --silent >%{tty} <%{tty}",
  }, -- TODO: 起動時に cmd.show, cmd.clear が無ければこれを自動コピーするか？

  actions = {
    -- Image
    image = {
      patterns = { "*.bmp", "*.jpg", "*.jpeg", "*.png", "*.xpm", "*.avif", "*.webp", "*.heic" }, -- TODO: #preview.vifm#preview image "<image/*>" として受けるか？
      cmd = { -- TODO: この形式に変更！！！
        generate = "",
        show = "",
        clear = "",
      },
      preview_ext = "jpg", -- 変更ここまで
      generate = {
        cmd = "magick '%{src}' -colorspace sRGB -resize 600x600 -quality 80 '%{dst}'",
        ext = "jpg",
      },
    },
    -- Gif
    gif = {
      patterns = { "*.gif" },
      generate = {
        cmd = "magick '%{src}' -coalesce -resize 200x200 -background none -layers optimize '%{dst}'",
        ext = "gif",
      },
    },
    -- Video
    video = {
      patterns = { "*.avi", "*.mp4", "*.wmv", "*.dat", "*.3gp", "*.ogv", "*.mkv", "*.mpg", "*.mpeg", "*.vob", "*.fl[icv]", "*.m2v", "*.mov", "*.webm", "*.ts", "*.mts", "*.m4v", "*.r[am]", "*.qt", "*.divx", "*.as[fx]" },
      generate = {
        cmd = "ffmpegthumbnailer -s 640 -q 8 -t 10 -i '%{src}' -o '%{dst}'",
        ext = "jpg",
      },
    },
    -- PDF
    pdf = {
      patterns = {
        "*.pdf",
      },
      generate = {
        cmd = 'magick -colorspace sRGB -density 120 "%{src}[0]" -flatten -resize 600x600 -quality 80 "%{dst}"',
        ext = "jpg",
      },
    },
  },
}

return config
