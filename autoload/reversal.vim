if !exists('g:loaded_reversal')
  runtime! plugin/reversal.vim
endif

let s:save_cpo = &cpo
set cpo&vim

let s:additinal_find_paths = {
  \   'vim': ['../autoload', '../plugin'],
  \ }

let s:extension_map = {
  \   'c': ['h'],
  \   'cpp': ['h', 'hpp'],
  \   'h': ['c', 'cpp'],
  \   'hpp': ['cpp'],
  \   'vim': ['vim'],
  \ }

function! s:path_info(fullpath)
  return {
    \   'directory': fnamemodify(a:fullpath, ':p:h'),
    \   'name': fnamemodify(a:fullpath, ':t:r'),
    \   'extension': fnamemodify(a:fullpath, ':e'),
    \ }
endfunction

function! s:target_extensions(extension)
  if !has_key(s:extension_map, a:extension)
    return []
  endif

  return s:extension_map[a:extension]
endfunction

function! s:find_paths(path_info)
  if a:path_info.directory == getcwd()
    let find_paths = [a:path_info.directory]
  else
    let find_paths = [a:path_info.directory, getcwd()]
  endif

  if has_key(s:additinal_find_paths, a:path_info.extension)
    for relative in s:additinal_find_paths[a:path_info.extension]
      let path = simplify(a:path_info.directory . '/' . relative)
      if index(find_paths, path) == -1
        call add(find_paths, path)
      endif
    endfor
  endif

  return find_paths
endfunction

function! s:target_file_names(path_info)
  let file_names = []

  for extension in s:target_extensions(a:path_info.extension)
    let file_name = a:path_info.name . '.' . extension

    if index(file_names, file_name) == -1
      call add(file_names, file_name)
    endif
  endfor

  return file_names
endfunction

function! s:switch_candidates(base_file)
  let path_info = s:path_info(a:base_file)
  let candidates = []

  for dir_name in s:find_paths(path_info)
    for file_name in s:target_file_names(path_info)
      let path = simplify(dir_name . '/' . file_name)

      if path == a:base_file
        continue
      endif

      if index(candidates, path) == -1 && filereadable(path)
        call add(candidates, path)
      endif
    endfor
  endfor

  return candidates
endfunction

function! reversal#switch_buffer()
  let base_file = expand('%:p')

  if len(base_file) > 0
    let candidates = s:switch_candidates(base_file)

    if len(candidates) > 0
      execute 'edit '.candidates[0]
    else
      echo 'Can not find pair file.'
    endif
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

