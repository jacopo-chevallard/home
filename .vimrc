" An example for a vimrc file.
"
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last change:	2008 Jul 02
"
" To use it, copy it to
"     for Unix and OS/2:  ~/.vimrc
"	      for Amiga:  s:.vimrc
"  for MS-DOS and Win32:  $VIM\_vimrc
"	    for OpenVMS:  sys$login:.vimrc

" pathogen.vim 
execute pathogen#infect()

" When started as "evim", evim.vim will already have done these settings.
if v:progname =~? "evim"
  finish
endif

" Fix backspace and delete issue
set backspace=indent,eol,start
set t_kb=
set t_kD=[3~

" sets the language of the menu (gvim)
"set langmenu=en_GB.UTF-8
" Sets the language of the messages / ui (vim)
"language en   

" Persistent undo
" tell it to use an undo file
" set undofile
" " set a directory to store the undo history
" set undodir=/Users/jacopo/.vim/undo
" set undolevels=10000         " How many undos
" set undoreload=50000        " number of lines to save for undo

" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" To make sure arrow keys work
set term=builtin_ansi

set notimeout          " don't timeout on mappings
set ttimeout           " do timeout on terminal key codes
set timeoutlen=100     " timeout after 100 msec


set number        " always show line numbers
set showmatch     " set show matching parenthesis
"set ignorecase    " ignore case when searching
"set smartcase     " ignore case if search pattern is all lowercase,
                  "    case-sensitive otherwise
set smarttab      " insert tabs on the start of a line according to
                  "    shiftwidth, not tabstop
set hlsearch      " highlight search terms
set incsearch     " show search matches as you type

set visualbell           " don't beep
set noerrorbells         " don't beep

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

if has("vms")
  set nobackup		" do not keep a backup file, use versions instead
else
  set backup		" keep a backup file
endif
set history=100		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set hlsearch        " highlight searches
set incsearch		" do incremental searching
set nobackup        " do not keep a backup file
set ttyfast         " smoother changes

set ttymouse=xterm2

set tabstop=2		" set tab = 4 spaces "
set shiftwidth=2		" set shift width = 4 spaces "
set expandtab

set pastetoggle=<F2>

" Instead of pressing shift + : you can just press ; !!
nnoremap ; :

set tw=0

" Word counter

function! WC()
    let filename = expand("%")
    let cmd = "detex " . filename . " | wc -w | tr -d [:space:]"
    let result = system(cmd)
    echo result . " words"
endfunction

command WC call WC()

" For Win32 GUI: remove 't' flag from 'guioptions': no tearoff menu entries
" let &guioptions = substitute(&guioptions, "t", "", "g")

" Don't use Ex mode, use Q for formatting
map Q gq

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

" In many terminal emulators the mouse works just fine, thus enable it.
set mouse=a

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
"  let fortran_free_source=1
  let fotran_have_tabs=1
  syntax on
  set hlsearch
  colorscheme koehler 
  set bg=dark
endif

set bg=dark

" GitHub markdown syntax downloaded from
" https://github.com/jtratner/vim-flavored-markdown
augroup markdown
    au!
    au BufNewFile,BufRead *.md,*.markdown setlocal filetype=ghmarkdown
augroup END

" Only do this part when compiled with support for autocommands.
if has("autocmd")

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  " Also don't do it when the mark is in the first line, that is the default
  " position when opening a file.
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

  augroup END

else

  " set autoindent		" always set autoindenting on

  set noautoindent
  set nosmartindent
  set nocindent   

endif " has("autocmd")

autocmd! BufRead,BufNewFile *.ics setfiletype icalendar


" tab navigation like firefox
nnoremap <C-S-p> :tabprevious<CR>
nnoremap <C-S-n>   :tabnext<CR>
nnoremap <C-t>     :tabnew<CR>

" Open new split panes to right and bottom, which feels more natural than
" Vim’s default:
"set splitbelow
set splitright

" We can use different key mappings for easy navigation between splits to save
" a keystroke. So instead of ctrl-w then j, it’s just ctrl-j:
nnoremap <C-j> <C-W>j
nnoremap <C-k> <C-W>k
nnoremap <C-h> <C-W>h
nnoremap <C-l> <C-W>l

" For MAC OS X remap Enter to insert a newline without going into insert mode
nnoremap  o<Esc>

set wrap linebreak textwidth=0

" Spell checking highlighting
"
hi SpellBad cterm=underline,bold ctermfg=grey ctermbg=blue

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif

" Vim markdown options
autocmd BufRead,BufNewFile *.md set filetype=markdown
let g:vim_markdown_math = 1
let g:vim_markdown_json_frontmatter = 1
let g:vim_markdown_new_list_item_indent = 2
let g:vim_markdown_folding_disabled = 1
