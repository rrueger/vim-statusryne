" Vim Plugin

if exists("g:statusryne") || &cp
  finish
endif

let s:keepcpo = &cpo
set cpo&vim

" Statusline {{{
" Always show statusline.
set laststatus=2
" Don't additionally show mode underneath statusline.
set noshowmode

" Mode Dict {{{
let g:currentmode={
    \ "n"      : "NORMAL",
    \ "no"     : "N-PENDING",
    \ "v"      : "VISUAL",
    \ "V"      : "V-LINE",
    \ "\<C-V>" : "V-Block",
    \ "s"      : "SELECT",
    \ "S"      : "S-LINE",
    \ "\<C-S>" : "S-BLOCK",
    \ "i"      : "INSERT",
    \ "R"      : "REPLACE",
    \ "Rv"     : "V-REPLACE",
    \ "c"      : "COMMAND",
    \ "cv"     : "VIM-EX",
    \ "ce"     : "EX",
    \ "r"      : "PROMPT",
    \ "rm"     : "MORE",
    \ "r?"     : "CONFIRM",
    \ "!"      : "SHELL",
    \ "t"      : "TERMINAL"
    \}
" }}}
" (f) Git Info {{{
let b:git_info = ''

augroup GetGitBranch
  autocmd!
  autocmd BufEnter,BufWritePost * let b:git_info = GitInfo()
augroup END

function! GitInfo()

  let git = ''
  let git_cmd = 'git -C ' . expand('%:p:h')

  let branch_cmd = git_cmd . ' rev-parse --abbrev-ref HEAD 2> /dev/null'
  let branch = system(branch_cmd)

  " git puts strange characters on branch output. Sanitise output, remove
  " non-printable characters, i.e. those in ascii range ~ (tilde) to -
  " (minus).
  let branch = substitute(branch, '[^ -~]\+', '', '')

  " Get more information if in a git repo.
  if branch != ''
    let git .= '  '
    let git .= '(' . branch . ')'

    " Could be a new file in a git repo with no name yet.
    if expand('%:p') != ''
      let stats_cmd = git_cmd . ' diff --numstat ' . expand('%:p' )
      let stats = system(stats_cmd)

      " Could be a non-tracked file. Then there are no stats.
      if stats != ''
        " Parse.
        let stats_pattern = '^\([0-9]*\)\s*\([0-9]*\).*$'
        let stats = substitute(stats, stats_pattern, '\1(+) \2(-)', '')
        " Truncate.
        let stats = stats[0:14]
        let git .= ' ' . stats
      endif
    endif
  endif

  return git
endfunction
" }}}
" (f) Colours {{{
" 'bg' is text colour, 'fg' is the bar colour.
"
hi StatusLine ctermbg=010
hi StatusLine ctermfg=007

hi StatusLineExtra ctermbg=014
hi StatusLineExtra ctermfg=007

hi StatusLineMode ctermfg=015

" Automatically change the statusline color depending on mode.
function! ChangeStatuslineColor()
  if (mode() =~# '\v(n|no)')
    " Normal Mode.
    exe 'hi! StatusLineMode ctermbg=010'
  elseif (mode() =~# '\v(v|V)')
    " Visual Mode.
    exe 'hi! StatusLineMode ctermbg=005'
  elseif (mode() ==# 'i')
    " Insert Mode.
    exe 'hi! StatusLineMode ctermbg=004'
  elseif (mode() ==# 'R')
    " Replace Mode.
    exe 'hi! StatusLineMode ctermbg=001'
  else
    " Other Mode.
    exe 'hi! StatusLineMode ctermbg=010'
  endif

  return ''
endfunction
" }}}
" (f) Buffer Statistics {{{
let b:buf_stats = ''

augroup GetFileStats
  autocmd!
  autocmd BufEnter,BufWritePost * let b:buf_stats = FileStats()
augroup END

function! FileStats()

  let stats = ''

  " If buffer hasn't been written yet, don't get size.
  if str2float(getfsize(expand('%:p'))) > 0

    " Buffer size.
    " let bytes = str2float(getfsize(expand('%:p')))

    " if bytes <= 0
    "   return '0'
    " endif

    " for size in ["B", "K", "M", "G"]
    "   if (abs(bytes) < 1000)
    "     return string(float2nr(round(bytes))) . size
    "   endif
    "   let bytes = bytes / 1000
    " endfor

    " Using system utils
    let size_cmd = 'du -shL ' . expand('%:p') . ' | cut -f1'
    let word_count_cmd = 'wc -w < ' . expand('%:p')
    let char_count_cmd = 'wc -m < ' . expand('%:p')

    let size = system(size_cmd)
    let word_count = system(word_count_cmd) . '(w) '
    let char_count = system(char_count_cmd) . '(c) '

    let stats = word_count . char_cound . size

  endif

  return stats

endfunction
" }}}
" (f) Read Only {{{
let b:readonly_flag = ""

augroup ReadOnlyStatus
  autocmd!
  autocmd BufEnter,WinEnter * let b:readonly_flag = ReadOnly()
augroup END


function! ReadOnly()

  if &readonly || !&modifiable
    return "[READ ONLY]"
  else
    return ""

endfunction
" }}}
" (f) File Name {{{
" Change how much of the filename is displayed based on available terminal.
" space.

let b:filename = ""

augroup FileName
  autocmd!
  autocmd BufEnter,VimResized * let b:filename = FileName()
augroup END


function! FileName()

    let fullname = expand("%:p")

    if (fullname == "")
        return ' [New]'
    endif

    " See how much space is being occupied by the rest of the statusline
    " elements.
    let remainder =
          \ 25
          \ + len(&filetype)
          \ + len(&fenc)
          \ + len(g:currentmode[mode()])
          \ + len(get(b:, 'git_info', ''))
          \ + len(get(b:, 'readonly_flag', ''))
          \ + len(get(b:, 'buf_stats', ''))

    " If the full name doesn't fit, then use a shorter one.
    " Cases:
    " 1) Show full path.
    " 2) Show only first character of every directory in path.
    " 3) Show only basename.

    if (winwidth(0) > len(fullname) + remainder)

      let shortpath = substitute(fullname, $HOME, '~', "")
      return ' ' . shortpath

    elseif (winwidth(0) > len(pathshorten(fullname)) + remainder)

      let home = pathshorten($HOME . '/')
      let shortpath = substitute(pathshorten(fullname), home, '~/', "")
      return ' ' . shortpath

    else
        return ' ' . expand("%:t")
    endif

endfunction
" }}}

" Status Line Format String.
set statusline=
set statusline+=%{ChangeStatuslineColor()}
set statusline+=%#StatusLineMode#                               " Set colour.
set statusline+=\ %{g:currentmode[mode()]}                      " Get Mode.
set statusline+=\ %*                                            " Default colour.
set statusline+=%{get(b:,'filename','')}                        " Filename.
set statusline+=%{get(b:,'git_info','')}                        " Git branch.
set statusline+=%{get(b:,'readonly_flag','')}                   " Readonly flag.
set statusline+=\ %*                                            " Default colour.

set statusline+=\ %=                                            " Right Side.
set statusline+=\ %3(%{get(b:,'buf_stats','')}%)                " File size.
set statusline+=\ %#StatusLineExtra#                            " Set colour.
set statusline+=\ %<[%{substitute(&spelllang,'_..','','g')}] " Spell Language.
set statusline+=%{(&filetype!=''?'\ ['.&filetype.']':'')}       " FileType.
set statusline+=\ %#StatusLineMode#                             " Set colour.
set statusline+=\ %3p%%                                         " Percentage.
set statusline+=\ %3l/%-3L:%-3c\                                " Line/Column Numbers.
" }}}
" Tab Line {{{
" Only show tabline if there are two or more tabs.
set showtabline=1
set tabpagemax=10
set tabline=%!TabLine()

" Colours and Configurations {{{
let g:padding = 2
let g:mintablabellen = 5

hi TabLineSel ctermfg=007 cterm=None
hi TabLineSel ctermbg=010 cterm=None

hi TabLineNum ctermfg=015 cterm=None
hi TabLineNum ctermbg=014 cterm=None

hi TabLineBuffer ctermbg=014
hi TabLineBuffer ctermfg=007

hi TabLine cterm=None
hi TabLineFill cterm=None
" }}}
" (f) LabelName {{{
function! LabelName(n)
  " Decide label name for n'th buffer.

  let b:buftype = getbufvar(a:n, "&buftype")

  if b:buftype ==# 'help'
    " Show help page name and strip trailing '.txt'.
    let label = '[H] ' . fnamemodify(bufname(a:n), ':t:s/.txt$//')

  elseif b:buftype ==# 'quickfix'
    let label = '[Q]'

  elseif bufname(a:n) != ''
    " Only show basename (with extension) for regular files.
    let label = " " . fnamemodify(bufname(a:n), ':t')

  else
    let label = "[New]"

  endif

  return label

endfunction
" }}}
" (f) Maxlen {{{
function! MaxLen(iterable)
  let maxlen = 0
  for item in a:iterable
    if len(item) > maxlen
      let maxlen = len(item)
    endif
  endfor
  return maxlen
endfunction
" }}}
" (f) TabLine {{{
function! TabLine()
  " Set the format string for the tabline.

  " Explainer {{{
  " The main complexity in the following code arises due to the requirement to
  " have equally spaced tab labels. It means that we need to find what will be
  " visually displayed first (the chars printed to screen with spacing) to
  " find out how long each tab label will be and then go back over the buffer
  " list to add formatting strings (i.e. colour). If we did not do this, the
  " formatting strings would be included in the calculation of the length of
  " the tab labels, even though they don't take up any visual space.
  "
  " Example:
  " The format string
  "
  " '%1T%#TabLineSel#%#TabLineSel#    %#TabLineSel# vimrc %#TabLineBuffer# .tmux.conf     %2T%#TabLine#         [H] eval          %#TabLineFill#%T'
  "
  " takes up 141 chars, but will only display
  "
  " '     vimrc  .tmux.conf              [H] eval          '
  "
  " taking up 54 chars.
  " }}}
  " Get maximum length tab label {{{

  " Get all labels.
  let g:tablabels = []
  for t in range(tabpagenr('$'))
    let g:tablabel = ""
    for bufnum in tabpagebuflist(t + 1)
      let g:tablabel .= LabelName(bufnum)
    endfor
    call add(g:tablabels, g:tablabel)
  endfor

  " Find maximal length.
  " For equal with tabs, fitted to longest tab label.
  let g:maxlabellen = max([g:mintablabellen, MaxLen(g:tablabels)])
  " For full screen width equal width tabs.
  " let g:maxlabellen = winwidth(0) / tabpagenr('$')

  " }}}

  let tablfmt = ''

  " Iter over tabs.
  " Here we set the format strings, for correct colouring, we need to do it in
  " the following order:
  " '<colour><padding><buflabel>[[ <colour> <buflabel>]]*<padding>'

  for t in range(tabpagenr('$'))

    " New tab label begins here.
    let tablfmt .= '%' . (t+1) . 'T'

    " Set highlight.
    " #TabLineSel for selected tab, #TabLine otherwise.
    let tablfmt .= (t+1 == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#')

    " Get buffer names and statuses.
    " Buffer names with formatting strings, colours etc.
    let t:labelfmt = ''
    " Number of buffers in tab.
    let t:bcount = len(tabpagebuflist(t+1))
    " Total amount of whitespace to fill, after considering curent tab label.
    let t:remainder = g:maxlabellen - len(g:tablabels[t])
    let t:pad = t:remainder /2 + g:padding

    " Iter over buffers in tab.
    for bnum in tabpagebuflist(t+1)

      " Set colour.
      if t+1 == tabpagenr()
        " If on current buffer in current tab, set bg colour dark.
        let bcolour = (bnum == bufnr("%") ? '%#TabLineSel#' : '%#TabLineBuffer#')
      else
        " If not on current tab, leave default bg colour.
        let bcolour = ''
      endif

      " Put padding before first buffer name in tab.
      if bnum == tabpagebuflist(t+1)[0]
        let t:labelfmt .= bcolour . repeat(" ", t:pad)
      endif

      let t:labelfmt .= bcolour . LabelName(bnum)

      " Don't add final space to buffer name.
      if t:bcount > 1
        let t:labelfmt .= ' '
      endif
      let t:bcount -= 1

    endfor

    let t:labelfmt .= repeat(" ", t:pad)
    let tablfmt .= t:labelfmt

  endfor

  " Fill to end.
  let tablfmt .= '%#TabLineFill#%T'

  return tablfmt
endfunction
" }}}
" }}}

let &cpo = s:keepcpo
unlet s:keepcpo
