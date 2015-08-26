if !exists('g:loaded_reversal')
  runtime! plugin/reversal.vim
endif

let s:save_cpo = &cpo
set cpo&vim

let s:search_paths = {
  \   'vim': ['autoload', 'plugin'],
  \ }

let s:extension_map = {
  \   'c': ['h'],
  \   'cpp': ['h', 'hpp'],
  \   'h': ['c', 'cpp'],
  \   'hpp': ['cpp'],
  \   'vim': ['vim'],
  \ }

function! s:root_path()
  if exists('g:reversal_get_root_command')
    let out = system(g:reversal_get_root_command)
    if v:shell_error == 0
      return substitute(out, '\n', '', '')
    endif
  endif
  return getcwd()
endfunction

function! s:path_info(fullpath, ...)
  let extension = fnamemodify(a:fullpath, ':e')
  let ftype = get(a:, 1, extension)

  return {
    \   'fullpath': a:fullpath,
    \   'directory': fnamemodify(a:fullpath, ':p:h'),
    \   'name': fnamemodify(a:fullpath, ':t:r'),
    \   'extension': extension,
    \   'ftype': ftype,
    \   'rootpath': s:root_path(),
    \ }
endfunction

function! s:target_filenames(path_info)
  let basenames = [a:path_info.name]
  let delimiter = get(exists('g:reversal_namespace_delimiter') ?
    \ g:reversal_namespace_delimiter : {}, a:path_info.ftype, '')

  if len(delimiter) > 0
    for flag in ['', 'g']
      let name = substitute(a:path_info.name, delimiter, '/', flag)
      if index(basenames, name) == -1
        call add(basenames, name)
      endif
    endfor

    if match(a:path_info.fullpath, a:path_info.rootpath) == 0
      let from_root = split(substitute(a:path_info.fullpath,
        \ a:path_info.rootpath . '/', '', ''), '/')
      if len(from_root) > 1
        call add(basenames, fnamemodify(join(from_root[-2:], delimiter), ':t:r'))
        if len(from_root) > 2
          call add(basenames, fnamemodify(join(from_root[-3:], delimiter), ':t:r'))
        endif
      endif
    endif
  endif

  let target_filenames = []

  let extensions = extend(
    \  copy(get(exists('g:reversal_extension_map') ?
    \    g:reversal_extension_map : {}, a:path_info.ftype, [])),
    \  get(s:extension_map, a:path_info.extension, []),
    \ )

  for basename in basenames
    for extension in extensions
      let filename = basename . '.' . extension

      if index(target_filenames, filename) == -1
        call add(target_filenames, filename)
      endif
    endfor
  endfor

  return target_filenames
endfunction

" Return the search paths
" Search priority:
"   Buffer dir => User settings => Plugin defaults => Root dir
function! s:search_paths(path_info)
  let search_paths = [a:path_info.directory]

  let relative_paths = extend(
    \   copy(get(exists('g:reversal_search_paths') ?
    \     g:reversal_search_paths : {}, a:path_info.ftype, [])),
    \   get(s:search_paths, a:path_info.ftype, []),
    \ )

  for relative_path in relative_paths
    let path = simplify(a:path_info.rootpath . '/' . relative_path)
    if index(search_paths, path) == -1
      call add(search_paths, path)
    endif
  endfor

  if index(search_paths, a:path_info.rootpath) == -1
    call add(search_paths, a:path_info.rootpath)
  endif

  return search_paths
endfunction

function! s:switch_file(path_info)
  let filenames = s:target_filenames(a:path_info)
  for path in s:search_paths(a:path_info)
    for filename in filenames
      let file = simplify(path . '/' . filename)

      if file == a:path_info.fullpath
        continue
      endif

      if filereadable(file)
        return file
      endif
    endfor
  endfor
endfunction

function! reversal#switch_buffer()
  let base_file = expand('%:p')

  if len(base_file) > 0
    let file = s:switch_file(s:path_info(base_file, &filetype))

    if empty(file)
      echomsg 'Can not find corresponding file'
    else
      execute 'edit ' . file
    endif
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
