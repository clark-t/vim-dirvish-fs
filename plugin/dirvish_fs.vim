" {{{
"   @file dirvish_fs.vim
"   @author clark-t (clarktanglei@163.com)
" }}}

if !exists('loaded_dirvish') || exists('loaded_dirvish_fs')
  finish
endif

let loaded_dirvish_fs = 1

command -nargs=1 -complete=dir FsAdd :call dirvishfs#add(<f-args>)
command -nargs=1 -complete=dir FsMove :call dirvishfs#move(<f-args>)
command -nargs=1 -complete=dir FsDel :call dirvishfs#delete(<f-args>)
command -nargs=1 -complete=dir FsCopy :call dirvishfs#copy(<f-args>)

nnoremap ma :<C-U><C-R>=printf("FsAdd %s", expand('%:p'))<CR>
nnoremap mm :<C-U><C-R>=printf("FsMove %s", &filetype=='dirvish' ? getline('.') : expand('%:p'))<CR>
nnoremap md :<C-U><C-R>=printf("FsDel %s", &filetype=='dirvish' ? getline('.') : expand('%:p'))<CR>
nnoremap mc :<C-U><C-R>=printf("FsCopy %s", &filetype=='dirvish' ? getline('.') : expand('%:p'))<CR>
nnoremap MA :<C-U><C-R>=printf("FsAdd %s", expand('%:p'))<CR>
nnoremap MM :<C-U><C-R>=printf("FsMove %s", &filetype=='dirvish' ? getline('.') : expand('%:p'))<CR>
nnoremap MD :<C-U><C-R>=printf("FsDel %s", &filetype=='dirvish' ? getline('.') : expand('%:p'))<CR>
nnoremap MC :<C-U><C-R>=printf("FsCopy %s", &filetype=='dirvish' ? getline('.') : expand('%:p'))<CR>

