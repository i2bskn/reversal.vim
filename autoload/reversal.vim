if !exists('g:loaded_reversal')
  runtime! plugin/reversal.vim
endif

let s:save_cpo = &cpo
set cpo&vim

let s:additinal_find_paths = {
  \   'vim': ['../autoload', '../plugin'],
  \ }

let s:extension_map = {
  \   'cpp': ['h', 'hpp'],
  \   'h': ['cpp'],
  \   'hpp': ['cpp'],
  \   'vim': ['vim'],
  \ }

function! s:find_paths(extension)
  let base = expand('%:p:h')
  let current = getcwd()
  let find_paths = base == current ? [base] : [base, current]

  if has_key(s:additinal_find_paths, a:extension)
    for relative in s:additinal_find_paths[a:extension]
      let path = simplify(base . '/' . relative)
      if index(find_paths, path) == -1
        call add(find_paths, path)
      endif
    endfor
  endif
  return find_paths
endfunction

function! s:target_extensions(extension)
  if !has_key(s:extension_map, a:extension)
    if len(a:extension)
      echo a:extension.' is not supported.'
    else
      echo 'No buffer name.'
    endif
    return
  endif

  return s:extension_map[a:extension]
endfunction

function! s:target_file_names(extensions)
  let base_name = expand('%:t:r')
  let file_names = []

  for extension in a:extensions
    let file_name = base_name.'.'.extension
    if index(file_names, file_name) == -1
      call add(file_names, file_name)
    endif
  endfor
  return file_names
endfunction

function! s:switch_candidates()
  let extension = expand('%:e')
  let extensions = s:target_extensions(extension)

  if type(extensions) == 0
    return
  endif

  let candidates = []
  let current_buffer = expand('%:p')

  for dir_name in s:find_paths(extension)
    for file_name in s:target_file_names(extensions)
      let path = simplify(dir_name . '/' . file_name)

      if path == current_buffer
        continue
      endif

    if index(candidates, path) == -1 && filereadable(path)
      call add(candidates, path)
    endif
  endfor

  return candidates
endfunction

function! reversal#switch_buffer()
  let candidates = s:switch_candidates()

  if len(candidates) > 0
    execute 'edit '.candidates[0]
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

