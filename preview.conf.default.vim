" Cache
if $XDG_CACHE_HOME != ''
   let $CACHE_DIR = $XDG_CACHE_HOME . '/vifm/preview'
else
   let $CACHE_DIR = $HOME . '/.cache/vifm/preview'
endif

" Log
let $LOG_ENABLED = 'false'          " {'true'|'false'} : Enable/Disable logging
let $LOG_PATH = $CACHE_DIR . '/log' " {path}           : Log filename

" Preview commands
let $SHOW_CMD_TEMPLATE = 'kitten icat --clear --stdin=no --place=%pwx%ph@%pxx%py --scale-up --transfer-mode=file "%file" >%tty <%tty'
let $CLEAR_CMD_TEMPLATE = 'kitten icat --clear --silent %N >%tty <%tty &'

" Images
let $IMAGE_QUALITY = 80                    " {0-100}            : Thumbnail quality (%)
let $IMAGE_RESIZE = '600x600'              " '{width}x{height}' : Thumbnail size
let $IMAGE_COLORSPACE_CMYK_TO_RGB = 'true' " {'true'|'false'}   : Convert 'CMYK' to 'sRGB' or not
" Image files filter
let $IMAGE_PATTERNS = '*.bmp,*.jpg,*.jpeg,*.png,*.gif,*.xpm,*.avif,*.webp,*.heic'

" Videos
let $VIDEO_QUALITY = 80   " {0-100} : Thumbnail quality (%)
let $VIDEO_SEEK_TIME = 10 " {0-100} : Seek time (%) of the total video duration
let $VIDEO_RESIZE = 640   " {size}  : Thumbnail size. cropped to fit within {size}x{size}
" Video files filter
let $VIDEO_PATTERNS = '*.avi,*.mp4,*.wmv,*.dat,*.3gp,*.ogv,*.mkv,*.mpg,*.mpeg,*.vob,*.fl[icv],*.m2v,*.mov,*.webm,*.ts,*.mts,*.m4v,*.r[am],*.qt,*.divx,*.as[fx]'

" PDFs
let $PDF_DENSITY = 120                   " {number}          : Pixel resolution
let $PDF_COLORSPACE_CMYK_TO_RGB = 'true' " {'true'|'false'}  : Convert 'CMYK' to 'sRGB' or not
let $PDF_PAGE_TO_EXTRACT = 0             " {0-?}             : Page num to extract
let $PDF_QUALITY = 80                    " {0-100}           : Thumbnail quality (%)
let $PDF_RESIZE = '600x600'              " '{width}x{heiht}' : Thumbnail size
" PDF files filter
let $PDF_PATTERNS = '*.pdf'

