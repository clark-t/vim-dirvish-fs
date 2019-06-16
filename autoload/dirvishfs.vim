
function! dirvishfs#add(pathname)
  if IsExists(a:pathname)
    call EchoExistsWarning(a:pathname)
    return
  endif

  if IsDirectoryName(a:pathname)
    call mkdir(a:pathname, 'p')
  else
    call EnsureParentDir(a:pathname)
    execute "normal! :e " . a:pathname . "\<CR>:w\<CR>"
  endif

  call RefreshDirvish()
endfunction

function! dirvishfs#move(pathname)
  let from = IsInDirvish() ? getline('.') : expand('%:p')
  let to = a:pathname

  if IsDirectoryName(to)
    let to = to . GetBaseName(from)
  endif

  if IsExists(to)
    call EchoExistsWarning(to)
    return
  endif

  let bufs = QueryOpeningBuffers(from)

  call EnsureParentDir(to)
  call rename(from, to)

  call SwipeBuffers(bufs)
  call RefreshDirvish()
endfunction

function! dirvishfs#delete(pathname)
  let bufs = QueryOpeningBuffers(a:pathname)

  call delete(a:pathname, 'rf')

  call SwipeBuffers(bufs)
  call RefreshDirvish()
endfunction

function! IsDirectoryName(pathname)
  return a:pathname[len(a:pathname) - 1] == "/"
endfunction

function! IsExists(pathname)
  return isdirectory(a:pathname) || filereadable(a:pathname)
endfunction

function! EchoExistsWarning(pathname)
  execute "normal! :echoerr '" . a:pathname . " is EXSITS!'\<CR>"
endfunction

function! GetBaseName(pathname)
  if IsDirectoryName(a:pathname)
    return fnamemodify(a:pathname, ':p:h:t')
  else
    return fnamemodify(a:pathname, ':p:t')
  endif

endfunction

function! EnsureParentDir(pathname)
  let dir = fnamemodify(a:pathname, ':p:h')
  if !isdirectory(dir)
    call mkdir(dir, 'p')
  endif
endfunction

function! QueryOpeningBuffers(pathname)
  let filepaths = []
  let bufs = []

  if IsDirectoryName(a:pathname)
    let filepaths = split(globpath(a:pathname, '*'), '\n')
  else
    let filepaths = [a:pathname]
  endif

  for i in filepaths
    let buf = bufname(i)
    if !empty(buf)
      call add(bufs, buf)
    endif
  endfor

  return bufs
endfunction

function! SwipeBuffers(bufs)
  for i in a:bufs
    execute "normal! :bwipe " . i . "\<CR>"
  endfor
endfunction

function! IsInDirvish()
  return &filetype == 'dirvish'
endfunction

function! RefreshDirvish()
  if IsInDirvish()
    execute "normal R"
  endif
endfunction
