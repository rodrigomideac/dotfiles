set clipboard=unnamed
set number
syntax on

" Set theme
color pablo

" Set style for .yaml files
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

" Allow saving of files as sudo when I forgot to start vim using sudo.
cmap w!! w !sudo tee > /dev/null %

call plug#begin('~/.vim/plugged')

Plug 'chrisbra/Colorizer'

" Initialize plugin system
call plug#end()
