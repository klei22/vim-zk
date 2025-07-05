" File: ~/.vim/plugin/zd_todo_plugin.vim
" ZD Plugin: Daily/Weekly/Monthly/Yearly + TODO + Projects
" ========================================================

if exists('g:loaded_zd_plugin')
  finish
endif
let g:loaded_zd_plugin = 1

" =============================================================================
"                               CONFIGURATION
" =============================================================================

let g:zd_dir = expand('~/.zd')  " or "~/zd", your choice
let g:zd_dir_daily   = g:zd_dir . '/daily'
let g:zd_dir_weekly  = g:zd_dir . '/weekly'
let g:zd_dir_monthly = g:zd_dir . '/monthly'
let g:zd_dir_yearly  = g:zd_dir . '/yearly'
let g:zd_dir_templates = g:zd_dir . '/templates'
let g:zd_dir_todos   = g:zd_dir . '/todos'
let g:zd_dir_projects = g:zd_dir . '/projects'  " <--- For project support
let g:zd_dir_areas = g:zd_dir . '/areas'  " <--- For organizing projects
let g:zd_dir_resources = g:zd_dir . '/resources'  " <--- shared resources
let g:zd_dir_archives= g:zd_dir . '/archives'  " <--- old projects, etc, things unused but should keep
let g:zd_dir_summaries = g:zd_dir . '/summaries'

" Template filenames
let g:zd_tpl_daily   = g:zd_dir_templates . '/daily.md'
let g:zd_tpl_weekly  = g:zd_dir_templates . '/weekly.md'
let g:zd_tpl_monthly = g:zd_dir_templates . '/monthly.md'
let g:zd_tpl_yearly  = g:zd_dir_templates . '/yearly.md'
let g:zd_tpl_project = g:zd_dir_templates . '/project.md'
let g:zd_tpl_area = g:zd_dir_templates . '/area.md'

" Active/done todos
let g:zd_active_todos = g:zd_dir_todos . '/active_todos.md'
let g:zd_done_todos   = g:zd_dir_todos . '/done_todos.md'

" Project listing index
let g:zd_projects_index = g:zd_dir_projects . '/projects.md'
let g:zd_areas_index = g:zd_dir_areas . '/areas.md'

" Llama model repo for summaries
let g:zd_llama_repo = 'bartowski/Llama-3.2-3B-Instruct-GGUF:Q8_0'

" Create top-level directories if they don't exist
call mkdir(g:zd_dir_daily, 'p')
call mkdir(g:zd_dir_weekly, 'p')
call mkdir(g:zd_dir_monthly, 'p')
call mkdir(g:zd_dir_yearly, 'p')
call mkdir(g:zd_dir_templates, 'p')
call mkdir(g:zd_dir_todos, 'p')
call mkdir(g:zd_dir_projects, 'p')
call mkdir(g:zd_dir_areas, 'p')
call mkdir(g:zd_dir_resources, 'p')
call mkdir(g:zd_dir_archives, 'p')
call mkdir(g:zd_dir_summaries, 'p')


" =============================================================================
"            HELPER: PARSE YYMMDD FOR DAILY NOTE (PREV_DAY / NEXT_DAY)
" =============================================================================

function! s:ParseDailyTimestamp(yyMMdd) abort
  " Expects e.g. "230131" => parse as "2023-01-31", return localtime() or 0 if invalid
  if len(a:yyMMdd) != 6 || a:yyMMdd !~# '^\d\{6}$'
    return 0
  endif
  let l:year_str = '20' . strpart(a:yyMMdd, 0, 2)
  let l:mon_str  = strpart(a:yyMMdd, 2, 2)
  let l:day_str  = strpart(a:yyMMdd, 4, 2)
  let l:datestr  = l:year_str . '-' . l:mon_str . '-' . l:day_str
  let l:t = strptime('%Y-%m-%d', l:datestr)
  return (l:t < 0 ? 0 : l:t)
endfunction


" =============================================================================
"              TEMPLATE LOADING AND STRING PLACEHOLDER REPLACEMENTS
" =============================================================================

function! s:LoadTemplateAndReplace(template_file, replacements) abort
  if filereadable(a:template_file)
    let l:lines = readfile(a:template_file)
  else
    let l:lines = []
  endif

  for i in range(len(l:lines))
    for [key, val] in items(a:replacements)
      let l:lines[i] = substitute(l:lines[i], '{{' . key . '}}', val, 'g')
    endfor
  endfor

  return l:lines
endfunction


" =============================================================================
"              COLLECT PROJECTS ORGANIZED BY AREA FOR DAILY NOTES
" =============================================================================
function! s:ProjectsByAreaLines() abort
  let l:out = []
  if !isdirectory(g:zd_dir_areas)
    return l:out
  endif
  let l:dirs = sort(filter(split(globpath(g:zd_dir_areas, '*', 1, 1), '\n'), 'isdirectory(v:val)'))
  for l:dir in l:dirs
    let l:area_name = fnamemodify(l:dir, ':t')
    let l:file = l:dir . '/main_area.md'
    if !filereadable(l:file)
      continue
    endif
    let l:lines = readfile(l:file)
    let l:start = index(l:lines, '## Projects')
    if l:start < 0
      continue
    endif
    let l:list = []
    for l:i in range(l:start + 1, len(l:lines) - 1)
      let l:ln = l:lines[l:i]
      if l:ln =~# '^##'
        break
      endif
      if l:ln =~# '^-'
        call add(l:list, '  ' . l:ln)
      endif
    endfor
    if !empty(l:list)
      call add(l:out, '##### ' . l:area_name)
      call extend(l:out, l:list)
      call add(l:out, '')
    endif
  endfor
  return l:out
endfunction


" =============================================================================
"                    DAILY NOTE (<leader>zd) with READABLE_DATE
" =============================================================================

function! s:OpenDailyNote(...) abort
  if a:0 > 0
    let l:today_str = a:1
  else
    let l:today_str = strftime('%y%m%d')
  endif

  let l:filename  = fnamemodify(g:zd_dir_daily . '/' . l:today_str . '.md', ':p')

  if !filereadable(l:filename)
    let l:t = s:ParseDailyTimestamp(l:today_str)
    if l:t > 0
      let l:prev_str = strftime('%y%m%d', l:t - 86400)
      let l:next_str = strftime('%y%m%d', l:t + 86400)
      " e.g. "Tuesday, January 24, 2025"
      let l:readable_date = strftime('%A, %B %d, %Y', l:t)
    else
      " fallback if parse fails
      let l:prev_str = ''
      let l:next_str = ''
      let l:readable_date = strftime('%A, %B %d, %Y')
    endif

    let l:week_str  = strftime('%y%V', (l:t > 0 ? l:t : localtime()))
    let l:month_str = strftime('%y%m', (l:t > 0 ? l:t : localtime()))
    let l:year_str  = strftime('%y',   (l:t > 0 ? l:t : localtime()))

    let l:proj_lines = s:ProjectsByAreaLines()
    let l:replacements = {
    \ 'TODAY': l:today_str,
    \ 'PREV_DAY': l:prev_str,
    \ 'NEXT_DAY': l:next_str,
    \ 'READABLE_DATE': l:readable_date,
    \ 'WEEK': l:week_str,
    \ 'MONTH': l:month_str,
    \ 'YEAR': l:year_str,
    \ 'PATH_DAILY': g:zd_dir_daily,
    \ 'PATH_WEEKLY': g:zd_dir_weekly,
    \ 'PATH_MONTHLY': g:zd_dir_monthly,
    \ 'PATH_YEARLY': g:zd_dir_yearly,
    \ 'PROJECTS_BY_AREA': join(l:proj_lines, "\n"),
    \}

    let l:lines = s:LoadTemplateAndReplace(g:zd_tpl_daily, l:replacements)

    if empty(l:lines)
      " Fallback if no daily.md template found
      let l:header = '# Daily Note ' . l:today_str
      let l:links = []
      if !empty(l:prev_str)
        call add(l:links, '[← Prev Day](' . g:zd_dir_daily . '/' . l:prev_str . '.md)')
      endif
      if !empty(l:next_str)
        call add(l:links, '[→ Next Day](' . g:zd_dir_daily . '/' . l:next_str . '.md)')
      endif
      call add(l:links, '[Weekly]('     . g:zd_dir_weekly  . '/' . l:week_str  . '.md)')
      call add(l:links, '[Monthly]('    . g:zd_dir_monthly . '/' . l:month_str . '.md)')
      call add(l:links, '[Yearly]('     . g:zd_dir_yearly  . '/' . l:year_str  . '.md)')

      let l:lines = [
      \ l:header,
      \ '',
      \ join(l:links, '  '),
      \ '',
      \ '---',
      \ '',
      \ '## ' . l:readable_date,
      \ '',
      \ '#### Projects by Area',
      \ ] + l:proj_lines + [
      \ '',
      \ ]
    endif

    call mkdir(fnamemodify(l:filename, ':h'), 'p')
    call writefile(l:lines, l:filename, 'b')
  endif

  execute 'edit ' . fnameescape(l:filename)
endfunction

nnoremap <silent> <leader>zd :call <SID>OpenDailyNote()<CR>


" =============================================================================
"                          WEEKLY NOTE (<leader>zw)
" =============================================================================

function! s:OpenWeeklyNote(...) abort
  if a:0 > 0
    let l:week_str = a:1
  else
    let l:week_str = strftime('%y%V')
  endif

  let l:filename = fnamemodify(g:zd_dir_weekly . '/' . l:week_str . '.md', ':p')

  if !filereadable(l:filename)
    if a:0 == 0
      " compute Monday of current ISO week
      let l:today_u = strftime('%u')
      let l:start_of_week = localtime() - (l:today_u - 1) * 86400
    else
      let l:start_of_week = localtime()
    endif

    let l:replacements = {
    \ 'WEEK': l:week_str,
    \ 'PATH_DAILY': g:zd_dir_daily,
    \}

    let l:lines = s:LoadTemplateAndReplace(g:zd_tpl_weekly, l:replacements)

    if empty(l:lines)
      let l:lines = [
      \ '# Weekly Note ' . l:week_str,
      \ '',
      \ '## Daily Links',
      \ ]
    else
      call add(l:lines, '## Daily Links')
    endif

    " Monday..Sunday
    for i in range(0, 6)
      let l:day_time = l:start_of_week + i * 86400
      let l:day_str  = strftime('%y%m%d', l:day_time)
      let l:day_file = g:zd_dir_daily . '/' . l:day_str . '.md'
      if filereadable(expand(l:day_file))
        call add(l:lines, '- [Daily ' . l:day_str . '](' . l:day_file . ')')
      else
        call add(l:lines, '- [Daily ' . l:day_str . '](' . l:day_file . ') (not yet created)')
      endif
    endfor

    call mkdir(fnamemodify(l:filename, ':h'), 'p')
    call writefile(l:lines, l:filename, 'b')
  endif

  execute 'edit ' . fnameescape(l:filename)
endfunction

nnoremap <silent> <leader>zw :call <SID>OpenWeeklyNote()<CR>


" =============================================================================
"                        MONTHLY NOTE (<leader>zm)
" =============================================================================

function! s:OpenMonthlyNote(...) abort
  if a:0 > 0
    let l:month_str = a:1
  else
    let l:month_str = strftime('%y%m')
  endif

  let l:filename = fnamemodify(g:zd_dir_monthly . '/' . l:month_str . '.md', ':p')

  if !filereadable(l:filename)
    let l:year_str = strpart(l:month_str, 0, 2)
    let l:replacements = {
    \ 'MONTH': l:month_str,
    \ 'YEAR':  l:year_str,
    \ 'PATH_WEEKLY': g:zd_dir_weekly,
    \ 'PATH_DAILY':  g:zd_dir_daily,
    \ 'PATH_YEARLY': g:zd_dir_yearly,
    \}

    let l:lines = s:LoadTemplateAndReplace(g:zd_tpl_monthly, l:replacements)

    if empty(l:lines)
      let l:lines = [
      \ '# Monthly Note ' . l:month_str,
      \ '',
      \ '[Yearly](' . g:zd_dir_yearly . '/' . l:year_str . '.md)',
      \ '',
      \ '---',
      \ '',
      \ '## Daily and Weekly Links',
      \ ]
    endif

    let l:full_year = '20' . l:year_str
    let l:mon_only  = strpart(l:month_str, 2, 2)
    let l:ym = l:full_year . '-' . l:mon_only

    let l:day = 1
    while 1
      let l:this_date_str = printf('%s-%02d', l:ym, l:day)
      let l:this_time = strptime('%Y-%m-%d', l:this_date_str)
      if strftime('%Y-%m', l:this_time) != strftime('%Y-%m', strptime('%Y-%m', l:ym))
        break
      endif

      let l:day_str   = strftime('%y%m%d', l:this_time)
      let l:day_file  = g:zd_dir_daily . '/' . l:day_str . '.md'
      let l:week_str  = strftime('%y%V', l:this_time)
      let l:week_file = g:zd_dir_weekly . '/' . l:week_str . '.md'
      let l:line = '- [Daily ' . l:day_str . '](' . l:day_file . ')' .
            \ ' | [W' . l:week_str . '](' . l:week_file . ')'
      call add(l:lines, l:line)

      let l:day += 1
    endwhile

    call mkdir(fnamemodify(l:filename, ':h'), 'p')
    call writefile(l:lines, l:filename, 'b')
  endif

  execute 'edit ' . fnameescape(l:filename)
endfunction

nnoremap <silent> <leader>zm :call <SID>OpenMonthlyNote()<CR>


" =============================================================================
"                       YEARLY NOTE (<leader>zy)
" =============================================================================

function! s:OpenYearlyNote(...) abort
  if a:0 > 0
    let l:year_str = a:1
  else
    let l:year_str = strftime('%y')
  endif

  let l:filename = fnamemodify(g:zd_dir_yearly . '/' . l:year_str . '.md', ':p')

  if !filereadable(l:filename)
    let l:replacements = {
    \ 'YEAR': l:year_str,
    \ 'PATH_MONTHLY': g:zd_dir_monthly,
    \}

    let l:lines = s:LoadTemplateAndReplace(g:zd_tpl_yearly, l:replacements)

    if empty(l:lines)
      let l:lines = [ '# Yearly Note ' . l:year_str, '', '## Monthly Links' ]
    else
      call add(l:lines, '## Monthly Links')
    endif

    for l:month_num in range(1, 12)
      let l:month_str = printf('%02d', l:month_num)
      let l:ym = l:year_str . l:month_str
      let l:month_file = g:zd_dir_monthly . '/' . l:ym . '.md'
      call add(l:lines, '- [Month ' . l:ym . '](' . l:month_file . ')')
    endfor

    call mkdir(fnamemodify(l:filename, ':h'), 'p')
    call writefile(l:lines, l:filename, 'b')
  endif

  execute 'edit ' . fnameescape(l:filename)
endfunction

nnoremap <silent> <leader>zy :call <SID>OpenYearlyNote()<CR>


" =============================================================================
"                         TODO SYSTEM + KEYBINDINGS
" =============================================================================
" - <leader>ta => Add a new TODO
" - <leader>td => Mark a TODO as done
" - <leader>ts => Sort active todos
" - <leader>to => Open active todos
" - <leader>tO => Open done todos

function! s:AddTodo() abort
  let l:todo_text = input('New TODO: ')
  if empty(l:todo_text)
    echo "Cancelled."
    return
  endif

  let l:todo_id = strftime('%Y%m%d%H%M%S')
  let l:todo_filename = g:zd_dir_todos . '/' . l:todo_id . '.md'
  let l:note_lines = [
  \ '# TODO Note: ' . l:todo_id,
  \ '',
  \ 'Created: ' . strftime('%Y-%m-%d %H:%M:%S'),
  \ '',
  \ '## Description',
  \ l:todo_text,
  \ ]
  call writefile(l:note_lines, l:todo_filename)

  let l:timestamp = strftime('%Y-%m-%d %H:%M:%S')
  let l:line = '- [' . l:timestamp . '] ' . l:todo_text . '  (Note: ' . l:todo_filename . ')'

  if filereadable(g:zd_active_todos)
    call writefile([l:line], g:zd_active_todos, 'a')
  else
    call writefile(['# Active TODOS', '', l:line ], g:zd_active_todos)
  endif

  echo "TODO added. Opening note file..."
  execute 'edit ' . fnameescape(l:todo_filename)
endfunction

function! s:MarkTodoAsDone() abort
  let l:line = getline('.')
  if empty(l:line) || l:line =~ '^#'
    echo "No TODO on this line (or it's a heading)."
    return
  endif

  let l:done_stamp = strftime('%Y-%m-%d %H:%M:%S')
  let l:done_line = l:line . '  -- DONE at ' . l:done_stamp

  if filereadable(g:zd_done_todos)
    call writefile([l:done_line], g:zd_done_todos, 'a')
  else
    call writefile(['# Done TODOS', '', l:done_line], g:zd_done_todos)
  endif

  call deletebufline('%', line('.'))
  echo "TODO marked done and moved to done_todos.md"
endfunction

function! s:SortActiveTodos() abort
  if !filereadable(g:zd_active_todos)
    echo "No active_todos.md file found."
    return
  endif

  let l:lines = readfile(g:zd_active_todos)
  if empty(l:lines)
    echo "No lines to sort."
    return
  endif

  let l:heading = []
  let l:todos   = []
  for l:ln in l:lines
    if l:ln =~ '^#'
      call add(l:heading, l:ln)
    else
      call add(l:todos, l:ln)
    endif
  endfor

  call sort(l:todos)
  let l:sorted = l:heading + [''] + l:todos
  call writefile(l:sorted, g:zd_active_todos)
  echo "Active todos sorted."
endfunction

function! s:OpenActiveTodos() abort
  if !filereadable(g:zd_active_todos)
    call writefile(['# Active TODOS', ''], g:zd_active_todos)
  endif
  execute 'edit ' . fnameescape(g:zd_active_todos)
endfunction

function! s:OpenDoneTodos() abort
  if !filereadable(g:zd_done_todos)
    call writefile(['# Done TODOS', ''], g:zd_done_todos)
  endif
  execute 'edit ' . fnameescape(g:zd_done_todos)
endfunction

nnoremap <silent> <leader>ta :call <SID>AddTodo()<CR>
nnoremap <silent> <leader>td :call <SID>MarkTodoAsDone()<CR>
nnoremap <silent> <leader>ts :call <SID>SortActiveTodos()<CR>
nnoremap <silent> <leader>to :call <SID>OpenActiveTodos()<CR>
nnoremap <silent> <leader>tO :call <SID>OpenDoneTodos()<CR>


" =============================================================================
"    CREATE/OPEN FILE UNDER CURSOR (<leader>zn) + DAILY/WEEKLY/MONTHLY/YEARLY
" =============================================================================

function! s:CreateFileUnderCursor() abort
  let l:file = expand('<cfile>')
  if l:file ==# ''
    echo "No file recognized under cursor."
    return
  endif

  let l:filepath = fnamemodify(l:file, ':p')

  if filereadable(l:filepath)
    execute 'edit ' . fnameescape(l:filepath)
    return
  endif

  " Guess note type from path
  if l:filepath =~# '\vdaily/\d{6}\.md$'
    let l:fn = fnamemodify(l:filepath, ':t')
    let l:date_stamp = substitute(l:fn, '\.md$', '', '')
    call s:OpenDailyNote(l:date_stamp)
  elseif l:filepath =~# '\vweekly/\d{4}\.md$'
    let l:fn = fnamemodify(l:filepath, ':t')
    let l:week_stamp = substitute(l:fn, '\.md$', '', '')
    call s:OpenWeeklyNote(l:week_stamp)
  elseif l:filepath =~# '\vmonthly/\d{4}\.md$'
    let l:fn = fnamemodify(l:filepath, ':t')
    let l:month_stamp = substitute(l:fn, '\.md$', '', '')
    call s:OpenMonthlyNote(l:month_stamp)
  elseif l:filepath =~# '\vyearly/\d{2}\.md$'
    let l:fn = fnamemodify(l:filepath, ':t')
    let l:year_stamp = substitute(l:fn, '\.md$', '', '')
    call s:OpenYearlyNote(l:year_stamp)
  else
    " It's outside our known structure, just create an empty file
    call mkdir(fnamemodify(l:filepath, ':h'), 'p')
    call writefile([], l:filepath)
    execute 'edit ' . fnameescape(l:filepath)
    echo "Created generic note: " . l:filepath
  endif
endfunction

nnoremap <silent> <leader>zn :call <SID>CreateFileUnderCursor()<CR>


" =============================================================================
"                  PROJECT SUPPORT: MAIN PROJECTS INDEX + INDIVIDUAL
" =============================================================================

" We'll keep a "projects.md" index at "~/.zd/projects/projects.md".
" Then <leader>zp => prompt for project name => open or create subfolder + main_project.md
" We'll also update projects.md with a link if not present.
"
" <leader>zP => open the "projects.md" index directly.

function! s:OpenProject(...) abort
  " If we got an argument, use it; otherwise prompt
  if a:0 == 1
    let l:project_name = a:1
  else
    let l:project_name = input("Project name: ")
  endif
  if empty(l:project_name)
    echo "Cancelled."
    return
  endif

  let l:dir = g:zd_dir_projects . '/' . l:project_name
  let l:file = l:dir . '/main_project.md'

  if !isdirectory(l:dir)
    call mkdir(l:dir, 'p')
  endif

  " If not exist, create from template or fallback
  if !filereadable(l:file)
    let l:date_str = strftime('%Y-%m-%d %H:%M:%S')
    let l:replacements = {
    \ 'PROJECT_NAME': l:project_name,
    \ 'DATE_CREATED': l:date_str,
    \ 'PROJECT_PATH': l:dir,
    \}
    let l:lines = s:LoadTemplateAndReplace(g:zd_tpl_project, l:replacements)
    if empty(l:lines)
      let l:lines = [
      \ '# Project: ' . l:project_name,
      \ '',
      \ 'Created on ' . l:date_str,
      \ '',
      \ '## Overview',
      \ '- Outline your project goals',
      \ '- Important links or references',
      \ '- Next steps',
      \ '',
      \ '## Tasks',
      \ '- [ ] ',
      \ ]
    endif
    call writefile(l:lines, l:file, 'b')

    " Insert or update the project listing in projects.md
    call s:UpdateProjectsIndex(l:project_name, l:file, l:date_str)
  else
    " Already exist => ensure it's in the index
    call s:UpdateProjectsIndex(l:project_name, l:file, '')
  endif

  execute 'edit ' . fnameescape(l:file)
endfunction

" This helper ensures there's an entry in the "projects.md" index for the given project.
function! s:UpdateProjectsIndex(project_name, main_file, date_str) abort
  " Make sure projects.md exists
  if !filereadable(g:zd_projects_index)
    call writefile(['# Projects Index', ''], g:zd_projects_index)
  endif

  let l:lines = readfile(g:zd_projects_index)

  " We want to see if there's already a line referencing this project's "main_file"
  " We'll store the project as a relative link if possible, e.g. "project_name/main_project.md"
  let l:rel_path = fnamemodify(a:main_file, ':~:.')
  " But simpler might be: relative to the projects folder
  let l:rel_to_projects = fnamemodify(a:main_file, ':t')  " "main_project.md"
  " Or "project_name/main_project.md"? Let's do that by taking the base folder name
  let l:base_folder = fnamemodify(a:main_file, ':h:t')  " e.g. project_name
  let l:rel_display = l:base_folder . '/main_project.md'

  " We'll check if the line referencing "rel_display" is already in lines
  let l:found = 0
  for l:ln in l:lines
    if l:ln =~ rel_display
      let l:found = 1
      break
    endif
  endfor

  if !l:found
    " Add a new line: "- [project_name](project_name/main_project.md) (created DATE)"
    let l:date_info = (a:date_str == '' ? '' : ' (created ' . a:date_str . ')')
    let l:new_line = '- [' . a:project_name . '](' . l:rel_display . ')' . l:date_info
    call writefile([l:new_line], g:zd_projects_index, 'a')
  endif
endfunction

" Key mapping to create/open project
nnoremap <silent> <leader>zp :call <SID>OpenProject()<CR>

" And mapping to open the main projects index
function! s:OpenProjectsIndex() abort
  if !filereadable(g:zd_projects_index)
    call writefile(['# Projects Index', ''], g:zd_projects_index)
  endif
  execute 'edit ' . fnameescape(g:zd_projects_index)
endfunction

nnoremap <silent> <leader>zP :call <SID>OpenProjectsIndex()<CR>


" =============================================================================
"                  AREA SUPPORT: MAIN AREA INDEX + INDIVIDUAL
" =============================================================================

" We'll keep a "areas.md" index at "~/.zd/areas/areas.md".
" Then <leader>za => prompt for area name => open or create subfolder + main_area.md
" We'll also update areas.md with a link if not present.
"
" <leader>zA => open the "areas.md" index directly.

function! s:OpenArea(...) abort
  " If we got an argument, use it; otherwise prompt
  if a:0 == 1
    let l:area_name = a:1
  else
    let l:area_name = input("Area name: ")
  endif
  if empty(l:area_name)
    echo "Cancelled."
    return
  endif

  let l:dir = g:zd_dir_areas . '/' . l:area_name
  let l:file = l:dir . '/main_area.md'

  if !isdirectory(l:dir)
    call mkdir(l:dir, 'p')
  endif

  " If not exist, create from template or fallback
  if !filereadable(l:file)
    let l:date_str = strftime('%Y-%m-%d %H:%M:%S')
    let l:replacements = {
    \ 'AREA_NAME': l:area_name,
    \ 'DATE_CREATED': l:date_str,
    \ 'AREA_PATH': l:dir,
    \}
    let l:lines = s:LoadTemplateAndReplace(g:zd_tpl_area, l:replacements)
    if empty(l:lines)
      let l:lines = [
      \ '# Area: ' . l:area_name,
      \ '',
      \ 'Created on ' . l:date_str,
      \ '',
      \ '## Overview',
      \ '- Outline your area goals',
      \ '- Important links or references',
      \ '- Next steps',
      \ '',
      \ '## Tasks',
      \ '- [ ] ',
      \ ]
    endif
    call writefile(l:lines, l:file, 'b')

    " Insert or update the area listing in areas.md
    call s:UpdateAreasIndex(l:area_name, l:file, l:date_str)
  else
    " Already exist => ensure it's in the index
    call s:UpdateAreasIndex(l:area_name, l:file, '')
  endif

  execute 'edit ' . fnameescape(l:file)
endfunction

" This helper ensures there's an entry in the "areas.md" index for the given area.
function! s:UpdateAreasIndex(area_name, main_file, date_str) abort
  " Make sure areas.md exists
  if !filereadable(g:zd_areas_index)
    call writefile(['# Areas Index', ''], g:zd_areas_index)
  endif

  let l:lines = readfile(g:zd_areas_index)

  " We want to see if there's already a line referencing this area's "main_file"
  " We'll store the area as a relative link if possible, e.g. "area_name/main_area.md"
  let l:rel_path = fnamemodify(a:main_file, ':~:.')
  " But simpler might be: relative to the areas folder
  let l:rel_to_areas = fnamemodify(a:main_file, ':t')  " "main_area.md"
  " Or "area_name/main_area.md"? Let's do that by taking the base folder name
  let l:base_folder = fnamemodify(a:main_file, ':h:t')  " e.g. area_name
  let l:rel_display = l:base_folder . '/main_area.md'

  " We'll check if the line referencing "rel_display" is already in lines
  let l:found = 0
  for l:ln in l:lines
    if l:ln =~ rel_display
      let l:found = 1
      break
    endif
  endfor

  if !l:found
    " Add a new line: "- [area_name](area_name/main_area.md) (created DATE)"
    let l:date_info = (a:date_str == '' ? '' : ' (created ' . a:date_str . ')')
    let l:new_line = '- [' . a:area_name . '](' . l:rel_display . ')' . l:date_info
    call writefile([l:new_line], g:zd_areas_index, 'a')
  endif
endfunction

" Key mapping to create/open area
nnoremap <silent> <leader>za :call <SID>OpenArea()<CR>

" And mapping to open the main areas index
function! s:OpenAreasIndex() abort
  if !filereadable(g:zd_areas_index)
    call writefile(['# Areas Index', ''], g:zd_areas_index)
  endif
  execute 'edit ' . fnameescape(g:zd_areas_index)
endfunction

nnoremap <silent> <leader>zA :call <SID>OpenAreasIndex()<CR>

" =============================================================================
"                   SUMMARIZE DAILY NOTES WITH LLAMA-CLI
" =============================================================================

" Gather the contents of the last {days} daily notes and feed them to
" `llama-cli` for summarization.  Defaults to 1 day.
function! s:SummarizeRecentDays(...) abort
  let l:days = (a:0 > 0 ? a:1 : 1)
  let l:end_stamp = strftime('%y%m%d')
  let l:start_stamp = strftime('%y%m%d', localtime() - (l:days - 1) * 86400)

  let l:all_lines = []
  for i in range(l:days - 1, 0, -1)
    let l:stamp = strftime('%y%m%d', localtime() - i * 86400)
    let l:file = g:zd_dir_daily . '/' . l:stamp . '.md'
    if filereadable(l:file)
      call extend(l:all_lines, ['# ' . l:stamp] + readfile(l:file) + [''])
    endif
  endfor
  if empty(l:all_lines)
    echo 'No daily notes found.'
    return
  endif
  let l:prompt = 'Summarize the following notes:\n' . join(l:all_lines, "\n")
  let l:cmd = 'llama-cli -hf ' . g:zd_llama_repo . ' -p ' . shellescape(l:prompt)
  echom 'Running llama-cli to summarize notes...'
  let l:summary = system(l:cmd)
  let l:summary_file = g:zd_dir_summaries . '/' . l:start_stamp . '_' . l:end_stamp . '.txt'
  call mkdir(fnamemodify(l:summary_file, ':h'), 'p')
  call writefile(split(l:summary, "\n"), l:summary_file)
  echom 'Summary saved to ' . l:summary_file

  botright new
  call setline(1, split(l:summary, "\n"))
  setlocal buftype=nofile bufhidden=wipe noswapfile
endfunction

" Wrapper to summarize recent weeks (7 * n days)
function! s:SummarizeRecentWeeks(...) abort
  let l:weeks = (a:0 > 0 ? a:1 : 1)
  call s:SummarizeRecentDays(l:weeks * 7)
endfunction

nnoremap <silent> <leader>zs :call <SID>SummarizeRecentDays()<CR>

