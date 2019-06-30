
function! dirvishfs#add(pathname) abort
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

function! dirvishfs#copy(pathname)
  let from = IsInDirvish() ? getline('.') : expand('%:p')
  let to = a:pathname

  if IsDirectoryName(to)
    let to = to . GetBaseName(from)
  endif

  if IsDirectoryName(from)
    call system("cp -r " . from . " " . to)
  else
    call system("cp " . from . " " . to)
  endif
endfunction

function! dirvishfs#move(pathname) abort
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

  let currentWinId = win_getid()
  let fromToMap = GetFromToMap(fromPaths, from, to)
  let toPaths = GetToPaths(fromToMap)

  if HasFileExists(toPaths)
    execute "normal! :echo 'some dist files exists'"
    return
  endif

  " call EnsureParentDir(to)
  " call SwitchModifyWindowBufferToDefault(infos, fromToMap)

  if IsDirectoryName(from)
    call system("cp -r " . from . " " . to)
  else
    call system("cp " . from . " " . to)
  endif

  call delete(from, 'rf')


  " call rename(from, to)
  let actions = GetBufferReplaceActions(infos, fromToMap)
  call ExecuteActions(actions)
  call WipeBuffers(infos, fromPaths)
  call win_gotoid(currentWinId)
  call RefreshDirvish()
endfunction

function! dirvishfs#delete(pathname) abort
  let paths = GetFromPaths(a:pathname)
  let bufInfos = GetBufInfos()

  let actions = GetBufferDeleteActions(bufInfos, paths)

  call delete(a:pathname, 'rf')

  call ExecuteActions(actions)
  call WipeBuffers(bufInfos, paths)
  call RefreshDirvish()
endfunction

function! IsDirectoryName(pathname)
  return a:pathname[len(a:pathname) - 1] == "/"
endfunction

function! IsExists(pathname) abort
  return isdirectory(a:pathname) || filereadable(a:pathname)
endfunction

function! GetBaseName(pathname) abort
  if IsDirectoryName(a:pathname)
    return fnamemodify(a:pathname, ':p:h:t')
  else
    return fnamemodify(a:pathname, ':p:t')
  endif

endfunction

function! GetWindowIds(bufInfos) abort
  let results = []
  for info in bufInfos
    let results = results + info.windows
  endfor
  return results
endfunction
" function! EnsureDir(pathname) abort
"   if !isdirectory(a:pathname) && !filereadable(a:pathname)
"     call mkdir(a:pathname, 'p')
"   endif
" endfunction

function! EnsureParentDir(pathname) abort
  let dir = fnamemodify(a:pathname, ':p:h')
  " call EnsureDir(dir)
  if !isdirectory(dir)
    call mkdir(dir, 'p')
  endif
endfunction

function! WipeBuffers(bufInfos, paths) abort
  for path in a:paths
    let info =GetBufInfo(a:bufInfos, path)
    if !GetNothing(info)
      execute "normal! :bwipe " . path . "\<CR>"
    endif
  endfor
endfunction

function! IsInDirvish() abort
  return &filetype == 'dirvish'
endfunction

function! RefreshDirvish() abort
  if IsInDirvish()
    execute "normal R"
  endif
endfunction

function! GetBufInfos() abort
  let infos = getbufinfo()
  let results = []
  for info in infos
    let result = {
          \ 'loaded': info.loaded,
          \ 'listed': info.listed,
          \ 'changed': info.changed,
          \ 'hidden': info.hidden,
          \ 'windows': info.windows,
          \ 'syntax': get(info.variables, 'current_syntax', ''),
          \ 'name': DirPathFormat(get(info, 'name', ''))
          \ }
    call add(results, result)
  endfor
  return results
endfunction

function! GetFromPaths(from) abort
  if !isdirectory(a:from)
    return [a:from]
  end

  let arr = split(globpath(a:from, '**'), '\n')

  let i = 0
  while i < len(arr)
    let arr[i] = DirPathFormat(arr[i])
    " let arr[i] = arr[i]
    let i += 1
  endwhile

  return arr
endfunction

function! GetToPaths(fromToMap) abort
  let results = []
  for info in a:fromToMap
    call add(results, info.to)
  endfor
  return results
endfunction

function! DirPathFormat(...) abort
  if a:0 == 1
    if !isdirectory(a:1) || a:1 == ''
      return a:1
    endif
  endif

  if a:1 == ''
    return a:1
  endif

  let pathname = a:1

  if !IsDirectoryName(pathname)
    return pathname . '/'
  endif
  return pathname
endfunction

function! ReplaceRoot(pathname, fromRoot, toRoot) abort
  let fromRootFormated = DirPathFormat(a:fromRoot, 'force')
  let toRootFormated = DirPathFormat(a:toRoot, 'force')
  return toRootFormated . a:pathname[len(fromRootFormated):]
endfunction

function! GetFromToMap(fromPaths, from, to) abort
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

function! GetBufInfo(bufinfos, pathname) abort
  for info in a:bufinfos
    if info.name == a:pathname
      return info
    endif
  endfor
  return -1
endfunction

function! HasFileModified(bufinfos, paths) abort
  for path in a:paths
    let info = GetBufInfo(a:bufinfos, path)
    if !GetNothing(info) && info.changed == v:true
      return v:true
    endif
  endfor
  return v:false
endfunction

function! HasFileExists(paths) abort
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
function! GetBufferReplaceActions(infos, fromToMap) abort
  let actions = []

  for info in a:infos
    " let fro'mTo = GetFromToByFrom(a:fromToMap, info.name)
    " let info = GetBufInfo(a:infos, fromTo.from)

    " if GetNothing(fromTo)
      " continue
    " endif
    " if type(info) != v:t_dict
    "   continue
    " endif

    if info.hidden == v:false && info.syntax == 'dirvish'
      let subActions = CreateDirvishReplaceAction(a:fromToMap, info)
      let actions = actions + subActions
      continue
    endif

    let fromTo = GetFromTo(a:fromToMap, info.name)
    if GetNothing(fromTo)
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

" function! GetFromToByFrom(fromToMap, from)
"   for fromTo in a:fromToMap
"     if fromTo == a:from
"       return fromTo
"     endif
"   endfor
"   return -1
" endfunction

" function! GetFromToByTo(fromToMap, to)
"   for fromTo in a:fromToMap
"     if fromTo == a:from
"       return fromTo
"     endif
"   endfor
"   return -1
" endfunction

function! GetBufferDeleteActions(infos, paths) abort
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

function! CreateDirvishReplaceAction(fromToMap, bufInfo) abort
  let prevInfo = GetDirvishPrevInfo(a:bufInfo)
  let actions = []
  for info in prevInfo.prev
    call add(actions, "normal! :call win_gotoid(" . info.winid . ")\<CR>")
    call add(actions, "normal q")

    let prevFromTo = GetFromTo(a:fromToMap, info.name)
    if !GetNothing(prevFromTo)
      call add(actions, "normal! e " . prevFromTo.to . "\<CR>")
    endif

    let dirvishFromTo = GetFromTo(a:fromToMap, a:bufInfo.name)
    if GetNothing(dirvishFromTo)
      call add(actions, "normal :Dirvish " . a:bufInfo.name . "\<CR>")
    else
      call add(actions, "normal :Dirvish " . dirvishFromTo.to . "\<CR>")
    endif
  endfor

  return actions
endfunction

function! CreateFilePeplaceAction(fromToMap, bufInfo) abort
  let actions = []
  let fromTo = GetFromTo(a:fromToMap, a:bufInfo.name)
  for winid in a:bufInfo.windows
    call add(actions, "normal! :call win_gotoid(" . winid . ")\<CR>")
    call add(actions, "normal! e " . fromTo.to . "\<CR>")
  endfor
  return actions
endfunction

function! GetDirvishPrevInfo(bufInfo) abort
  let currentWinId = win_getid()

  let result = {
        \ 'dirvish': a:bufInfo.name,
        \ 'prev': []
        \ }

  for winid in a:bufInfo.windows

    call win_gotoid(winid)
    silent execute "normal q"
    let prevPath = expand('%:p')

    call add(result.prev, {'winid': winid, 'name': prevPath})

    execute "normal :Dirvish " . a:bufInfo.name "\<CR>"
    call win_gotoid(currentWinId)
  endfor

  return result
endfunction

function! GetFromTo(fromToMap, from) abort
  for fromTo in a:fromToMap
    if fromTo.from == a:from
      return fromTo
    end
  endfor
  return -1
endfunction

function! GetNothing(sth) abort
  return type(a:sth) == v:t_number && a:sth == -1
endfunction

function! ExecuteActions(actions) abort
  for action in a:actions
    execute action
  endfor
endfunction

let s:defaultEmptyBufnr = -1

function! ShowDefaultDir() abort
  if s:defaultEmptyBufnr == -1
    execute "normal! :enew\<CR>"
    let s:defaultEmptyBufnr = winbufnr(win_getid())
  endif
  execute "normal! :b " . s:defaultEmptyBufnr . "\<CR>"
  execute "normal :Dirvish " . fnamemodify('.', ':p') . "\<CR>"
  execute "normal! :bd " . s:defaultEmptyBufnr . "\<CR>"
endfunction

function! SwitchModifyWindowBufferToDefault(infos, fromToMap) abort
  for info in a:infos
    let fromTo = GetFromTo(a:fromToMap, info.name)

    if info.hidden == v:false && info.syntax == 'dirvish'
      for winid in info.windows
        call win_gotoid(winid)
        execute "normal q"
        let pathname = expand('%:p')
        let subFromTo = GetFromTo(a:fromToMap, pathname)
        if GetNothing(subFromTo) && GetNothing(fromTo)
          execute "normal :Dirvish " . info.name "\<CR>"
        elseif GetNothing(subFromTo) && !GetNothing(fromTo)
          continue
        else
          call ShowDefaultDir()
        endif
      endfor
    endif
    if GetNothing(fromTo)
      continue
    endif

    if info.hidden == v:false
      for winid in info.windows
        call win_gotoid(winid)
        call ShowDefaultDir()
      endfor
    endif
  endfor
endfunction


