
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

" function! dirvish#copy(pathname)

" endfunction

function! dirvishfs#move(pathname)
  let from = IsInDirvish() ? getline('.') : expand('%:p')
  let to = a:pathname

  if IsDirectoryName(to)
    let to = to . GetBaseName(from)
  endif

  let infos = GetBufInfos()
  let fromPaths = GetFromPaths(from)

  if HasFileModified(infos, fromPaths)
    execute "normal! :echo 'there are some files modified without saving'\<CR>"
    return
  endif

  let fromToMap = GetFromToMap(fromPaths, from, to)
  let toPaths = GetToPaths(fromToMap)

  if HasFileExists(infos, toPaths)
    execute "normal! :echo 'some dist files exists'"
    return
  endif

  let actions = GetBufferReplaceActions(infos, fromToMap)

  call EnsureParentDir(to)
  call rename(from, to)

  call ExecuteActions(actions)
  call WipeBuffers(fromPaths)
  call RefreshDirvish()
endfunction

function! dirvishfs#delete(pathname)
  let paths = GetFromPaths(a:pathname)
  let bufInfos = GetBufInfos()

  let actions = GetBufferDeleteActions(bufInfos, paths)

  call delete(a:pathname, 'rf')

  call ExecuteActions(actions)
  call WipeBuffers(paths)
  call RefreshDirvish()
endfunction

function! IsDirectoryName(pathname)
  return a:pathname[len(a:pathname) - 1] == "/"
endfunction

function! IsExists(pathname)
  return isdirectory(a:pathname) || filereadable(a:pathname)
endfunction

function! GetBaseName(pathname)
  if IsDirectoryName(a:pathname)
    return fnamemodify(a:pathname, ':p:h:t')
  else
    return fnamemodify(a:pathname, ':p:t')
  endif

endfunction

function! EnsureDir(pathname)
  if !isdirectory(pathname) && !filereadable(a:pathname)
    call mkdir(pathname, 'p')
  endif
endfunction

function! EnsureParentDir(pathname)
  let dir = fnamemodify(a:pathname, ':p:h')
  call EnsureDir(dir)
  " if !isdirectory(dir)
  "   call mkdir(dir, 'p')
  " endif
endfunction

function! WipeBuffers(paths)
  for path in a:paths
    if bufexists(path)
      silent execute "normal! :bwipe " . path . "\<CR>"
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

function! GetBufInfos()
  let infos = getbufinfo()
  let results = []
  for info in infos
    let result = {
          \ 'loaded': info.loaded,
          \ 'listed': info.listed,
          \ 'changed': info.changed,
          \ 'hidden': info.hidden,
          \ 'windows': info.windows,
          \ 'syntax': info.variables.current_syntax,
          \ 'name': DirPathFormat(info.name)
          \ }
    call add(results, result)
  endfor
  return results
endfunction

function! GetFromPaths (from)
  if !isdirectory(a:from)
    return [a:from]
  end

  let arr = split(globpath(a:from, '**'), '%')

  let i = 0
  while i < len(arr)
    let i += 1
    let arr[i] = DirPathFormat(arr[i])
  endwhile

  return arr
endfunction

function! GetToPaths(fromToMap)
  let results = []
  for info in a:fromToMap
    call add(results, info.to)
  endfor
endfunction

function! DirPathFormat(...)
  if a:0 == 1
    if !isdirectory(a:1)
      return a:1
    endif
  endif

  let pathname = a:1

  if !IsDirectoryName(pathname)
    return pathname + '/'
  endif
  return pathname
endfunction

function! ReplaceRoot(pathname, fromRoot, toRoot)
  let fromRootFormated = DirPathFormat(a:fromRoot, 'force')
  let toRootFormated = DirPathFormat(a:toRoot, 'force')
  return toRootFormated . pathname[len(fromRootFormated):]
endfunction

function! GetFromToMap (fromPaths, from, to)
  if !isdirectory(a:from)
    let dist = IsDirectoryName(a:to) ? (a:to . GetBaseName(a:from)) : a:to
    return [{'from': a:from, 'to': a:to}]
  endif

  let results = []

  for fromPath in a:fromPaths
    let dist = ReplaceRoot(fromPath, a:from, a:to)
    call add(results, {'from': fromPath, 'to': dist})
  endfor

  return results
endfunction

function! GetBufInfo(bufinfos, pathname)
  for info in a:bufinfos
    if info.name == pathname
      return info
    endif
  endfor
  return -1
endfunction

function! HasFileModified(bufinfos, paths)
  for path in a:paths
    let info = GetBufInfo(bufinfos, paths)
    if info.changed == v:true
      return v:true
    endif
  endfor
  return v:false
endfunction

function! HasFileExists(paths)
  for path in a:paths
    if filereadable(path)
      return v:true
    endif
  endfor
  return v:false
endfunction

" replace the dirvish window first
" then replace opening file
" then replace hidden buffer
function! GetBufferReplaceActions(infos, fromToMap)
  let actions = []

  for fromTo in a:fromToMap
    let info = GetBufInfo(a:infos, fromTo.from)

    if type(info) != v:t_dict
      continue
    endif

    if info.hidden == v:false && info.syntax == 'dirvish'
      let subActions = CreateDirvishReplaceAction(a:fromToMap, info)
      let actions = actions + subActions
      continue
    endif

    if info.hidden == v:false
      let subActions = CreateFilePeplaceAction(a:fromToMap, info)
      let actions = actions + subActions
      continue
    endif

    if info.listed == v:false
      call add(actions, "normal! :badd " . fromTo.to . "\<CR>")
      continue
    endif
  endfor

  return actions
endfunction

function! GetBufferDeleteActions(infos, paths)
  let actions = []
  for pathname in a:paths
    let info = GetBufInfo(a:infos, pathname)
    if GetNothing(info)
      continue
    endif

    if info.hidden == v:true
      continue
    endif

    for winid in info.windows
      call add(actions, "normal! :call win_gotoid(" . winid . ")\<CR>")
      call add(actions, "normal :call ShowDefaultDir()\<CR>")
    endfor
  endfor
  return actions
endfunction

function! CreateDirvishReplaceAction(fromToMap, bufInfo)
  let prevInfo = GetDirvishPrevInfo(a:bufInfo)
  let actions = []
  for info in prevInfo['prev']
    call add(actions, "normal! :call win_gotoid(" . info.winid . ")\<CR>")
    call add(actions, "normal q")

    let prevFromTo = GetFromTo(a:fromToMap, info.file)
    if !GetNothing(prevFromTo)
      call add(actions, "normal! e " . prevFromTo.to . "\<CR>")
    endif

    let dirvishFromTo= GetFromTo(a:fromToMap, bufInfo.name)
    call add(actions, "normal :Dirvish " . dirvishFromTo.to)
  endfor

  return actions
endfunction

function! CreateFilePeplaceAction(fromToMap, bufInfo)
  let actions = []
  let fromTo = GetFromTo(a:fromToMap, a:bufInfo)
  for winid in bufInfo.windows
    execute add(actions, "normal! :call win_gotoid(" . winid . ")\<CR>")
    execute add(actions, "normal! e " . fromTo.to . "\<CR>")
  endfor
  return actions
endfunction

function! GetDirvishPrevInfo(bufInfo)
  let currentWinId = win_getid()

  let result = {
        \ 'dirvish': a:bufInfo.name,
        \ 'prev': []
        \ }

  for winid in a:bufInfo.windows

    call win_gotoid(winId)
    silent execute "normal q"
    let prevPath = expand('%:p')

    call add(result.prev, {'winid': winid, 'file': prevPath})

    execute "normal :Dirvish " . a:bufInfo.name "\<CR>"
    call win_gotoid(currentWinId)
  endfor

  return result
endfunction

function! GetFromTo(fromToMap, from)
  for fromTo in a:fromToMap
    if fromTo.from == a:from
      return fromTo
    end
  endfor
  return -1
endfunction

function! GetNothing(sth)
  return type(sth) == v:t_number && sth == -1
endfunction

function! ExecuteActions(actions) abort
  for action in a:actions
    execute action
  endfor
endfunction

let s:defaultEmptyBufnr = -1

function! ShowDefaultDir()
  if s:defaultEmptyBufnr == -1
    execute "normal! :enew\<CR>"
    let s:defaultEmptyBufnr = winbufnr(win_getid())
  endif
  execute "normal! :b " . s:defaultEmptyBufnr . "\<CR>"
  execute "normal :Dirvish " . fnamemodify('.', ':p') . "\<CR>"
  execute "normal! :bd " . s:defaultEmptyBufnr . "\<CR>"
endfunction


