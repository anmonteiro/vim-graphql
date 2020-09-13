" Copyright (c) 2016-2020 Jon Parise <jon@indelible.org>
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to
" deal in the Software without restriction, including without limitation the
" rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
" sell copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
" FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
" IN THE SOFTWARE.
"
" Language: GraphQL
" Maintainer: Jon Parise <jon@indelible.org>

" Set our local options if indentation hasn't already been set up.
" This generally means we've been detected as the primary filetype.
if !exists('b:did_indent')
  setlocal autoindent
  setlocal nocindent
  setlocal nolisp
  setlocal nosmartindent

  setlocal indentexpr=GetGraphQLIndent()
  setlocal indentkeys=0{,0},0),0[,0],0#,!^F,o,O

  let b:did_indent = 1
endif

" If our indentation function already exists, we have nothing more to do.
if exists('*GetGraphQLIndent')
  finish
endif

let s:cpo_save = &cpoptions
set cpoptions&vim

" Check if the character at lnum:col is inside a string.
function s:InString(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 1), 'name') ==# 'graphqlString'
endfunction

function GetGraphQLIndent()
  " If this is the first non-blank line, we have nothing more to do because
  " all of our indentation rules are based on matching against earlier lines.
  let l:prevlnum = prevnonblank(v:lnum - 1)
  if l:prevlnum == 0
    return 0
  endif

  let l:line = getline(v:lnum)

  " If this line contains just a closing bracket, find its matching opening
  " bracket and indent the closing bracket to match.
  let l:col = matchend(l:line, '^\s*[]})]')
  if l:col > 0 && !s:InString(v:lnum, l:col)
    call cursor(v:lnum, l:col)

    let l:bracket = l:line[l:col - 1]
    if l:bracket ==# '}'
      let l:matched = searchpair('{', '', '}', 'bW')
    elseif l:bracket ==# ']'
      let l:matched = searchpair('\[', '', '\]', 'bW')
    elseif l:bracket ==# ')'
      let l:matched = searchpair('(', '', ')', 'bW')
    else
      let l:matched = -1
    endif

    return l:matched > 0 ? indent(l:matched) : virtcol('.') - 1
  endif

  " If we're inside of a multiline string, continue with the same indentation.
  if s:InString(v:lnum, matchend(l:line, '^\s*') + 1)
    return indent(v:lnum)
  endif

  " If the previous line contained an opening bracket, and we are still in it,
  " add indent depending on the bracket type.
  if getline(l:prevlnum) =~# '[[{(]\s*$'
    return indent(l:prevlnum) + shiftwidth()
  endif

  " Default to the existing indentation level.
  return indent(l:prevlnum)
endfunction

let &cpoptions = s:cpo_save
unlet s:cpo_save
