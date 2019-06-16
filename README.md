# vim-dirvish-fs

File System support for dirvish.vim

it works as NERDTree fs plugin does, so you can use the listed command and
keymapping to add/move/delete file or directory:

## COMMANDS

### FsAdd

add file or direcotry. For Example:

```vimscript
" add file
:FsAdd ~/a/b/c/d/e.txt<CR>

" add file without extension
:FsAdd ~/a/b/c<CR>

" add directory
:FsAdd ~/f/g/h/<CR>
```

if parent directory is not exists, the plugin will create one;

if the adding file is exists, the plugin will alert warning and exit.

### FsMove

Move current file, if in dirvish, the target file or
directory is the one under cursor. For Example:

```vimscript
" expect current file is ~/a/b.txt and moves to ~/a/c.txt
:FsMove ~/a/c.txt<CR>

" expect current file is ~/a/b.txt, and moves to ~/a/c/b.txt
:FsMove ~/a/c/b.txt<CR>
" or
:FsMove ~/a/c/<CR>
```

When file or directory is moved successfull, related opening buffers will be
clean up (by using bwipe)

### FsDel

Delete file or directory. For Example:

```vimscript
" delete file
:FsDel ~/a/b/c.txt<CR>

" delete directory
:FsDel ~/a/b/<CR>
```

Relating opening buffers will be clean up too.

If file has unsave change, alert warning and exit.

## MAPPINGS

Here offer some key mapping for command quick input, it can works in
normal file mode or dirvish mode, if in normal mode, pathname is file
path (value of expand('%')); if in dirvish mode, pathname is the file path under cursor (value of getline('.')).

key map won't execute the command, so you can change the pathname and
then press <CR> to execute.

- `ma`: Fast typing `:FsAdd [pathname]` to command line;
- `mm`: Fast typing `:FsMove [pathname]` to command line;
- `md`: Fast typing `:FsDel [pathname]` to command line;
