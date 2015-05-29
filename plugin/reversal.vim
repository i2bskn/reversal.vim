if exists('g:loaded_reversal')
  finish
endif
let g:loaded_reversal = 1

let s:save_cpo = &cpo
set cpo&vim

nnoremap <silent> <Plug>(reversal:switch_buffer) :<C-u>call reversal#switch_buffer()<CR>
command! Reversal call reversal#switch_buffer()

let &cpo = s:save_cpo
unlet s:save_cpo
