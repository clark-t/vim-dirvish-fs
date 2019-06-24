
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

  let fromToMap = FromToMap(from, to)
  let bufMaps = QueryOpeningBuffers(fromToMap)

  call EnsureParentDir(to)
  call rename(from, to)

  call SwitchBuffers(bufMaps)
  call SwipeBuffers(bufMaps)
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

function! QueryOpeningBuffers(fromToMap)
  let bufs = []

  for i in a:fromToMap
    if bufexists(i[0])
      call add(bufs, i)
    endif
  endfor

  return bufs
endfunction

function! SwipeBuffers(bufMaps)
  for i in a:bufMaps
    if bufexists(i[0])
      silent execute "normal! :bwipe " . i[0] . "\<CR>"
    endif
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

" function! GetWindowIds()
"   let layout = winlayout()
"   let stack = [layout]
"   let ids = []

"   while len(stack) > 0
"     let val = stack[-1]
"     let stack = stack[0:-2]
"     if val[0] != 'leaf'
"       let stack = stack + val[1]
"     else
"       call add(ids, val[1])
"     endif
"   endwhile

"   return ids
" endfunction

" function! GetWinBufInfos()
"   let winids = GetWindowIds()
"   let results = []
"   for id in winids
"     let nr = winbufnr(id)
"     let name = bufname(nr)
"     call add(results, [id, nr, name])
"   endfor
"   return results
" endfunction

" function! GetListedBufInfos()
"   let results = []
"   for nr in range(1, bufnr('$'))
"     if bufexists(nr) && buflisted(nr)
"       call add(results, [nr, bufname(nr)])
"     endif
"   endfor
"   return results
" endfunction

function! SwitchBuffers(fromToMap)
  " let curwinid = win_getid()
  " let isInDirvish = IsInDirvish()
  " let curpath = expand('%')

  for i from a:fromToMap
    let winid = bufwinid(i[0])
    if winid == -1
      continue
    endif
    call win_gotoid(winid)
    silent execute "normal! :e " . i[1] . "\<CR>"
  endfor
endfunction

function! FromToMap(from, to)
  if !isdirectory(a:from)
    let dist = IsDirectoryName(a:to) ? (a:to . GetBaseName(a:from)) : a:to
    return [[a:from, dist]]
  endif

  let results = []
  let lenOfFromRoot = IsDirectoryName(a:from) ? len(a:from) : (len(a:from) + 1)
  let toRoot = IsDirectoryName(a:to) ? a:to : (a:to . '/')
  let frompaths = split(globpath(a:from, '*'), '\n')
  for frompath in frompaths
    call add(results, [frompath, toRoot . frompath[lenOfFromRoot:]])
  endfor
  return results
endfunction

