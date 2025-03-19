set clipboard=unnamed
set number
set nocompatible
filetype plugin on
syntax on

" Set theme
color pablo

" Set style for .yaml files
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

" Set startup order
autocmd VimEnter *
            \   if !argc()
            \ |   Startify
            \ |   NERDTree
            \ |   wincmd w
            \ | endif

" fix nerdtree crashing when loading sessions
set sessionoptions-=blank

" Go to previous (last accessed) window.
autocmd VimEnter * wincmd p

" Allow saving of files as sudo when I forgot to start vim using sudo.
cmap w!! w !sudo tee > /dev/null %

call plug#begin('~/.vim/plugged')

Plug 'preservim/nerdtree'
Plug 'chrisbra/Colorizer'
Plug 'lervag/vimtex'
Plug 'mhinz/vim-startify'
Plug 'vimwiki/vimwiki'

let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0
let g:vimtex_compiler_latexmk = {
            \ 'build_dir' : 'build',
            \}
set conceallevel=1
let g:tex_conceal='abdmg'
" Initialize plugin system
call plug#end()

""""" Shortcuts""""""""""""
map <F4> :NERDTreeToggle

" Edit vimr configuration file
nnoremap confe :e $MYVIMRC<CR>
" Reload vims configuration file
nnoremap confr :source $MYVIMRC<CR>

" Enable crtl-s to save document
noremap <silent> <C-S>          :update<CR>
vnoremap <silent> <C-S>         <C-C>:update<CR>
inoremap <silent> <C-S>         <C-O>:update<CR>

" Go back to previous file
execute "set <M-z>=\ez"
nnoremap <M-z> :e#<CR>

" Commenting blocks of code.
augroup commenting_blocks_of_code
  autocmd!
  autocmd FileType c,cpp,java,scala let b:comment_leader = '// '
  autocmd FileType sh,ruby,python   let b:comment_leader = '# '
  autocmd FileType conf,fstab       let b:comment_leader = '# '
  autocmd FileType tex              let b:comment_leader = '% '
  autocmd FileType mail             let b:comment_leader = '> '
  autocmd FileType vim              let b:comment_leader = '" '
augroup END
noremap <silent> ,cc :<C-B>silent <C-E>s/^/<C-R>=escape(b:comment_leader,'\/')<CR>/<CR>:nohlsearch<CR>
noremap <silent> ,cu :<C-B>silent <C-E>s/^\V<C-R>=escape(b:comment_leader,'\/')<CR>//e<CR>:nohlsearch<CR>

" Variable assignments
" Enable yank to copy to clipboard
set clipboard=unnamedplus

set pastetoggle=<F2>

