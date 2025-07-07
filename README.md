# VIM-ZK ✨

A **Zettelkasten-inspired** note-taking and project management plugin for Vim/Neovim. This plugin allows you to quickly create or open:

- **Daily** notes (with human-readable dates)
- **Weekly, Monthly, Yearly** overview notes
- **TODO** lists (active + done) with minimal overhead
- **Project** directories with an auto-updating projects index

All integrated into Vim/Neovim via handy shortcuts and a few dynamic templates.

---

## Features 🚀

- **Daily Notes**: Create a note named `YYMMDD.md` in `~/.zd/daily/`.
  - Automatic links to **Previous** / **Next** day, plus Weekly/Monthly/Yearly references.
  - Human-readable date format (e.g., “Tuesday, January 24, 2025”).

- **Weekly / Monthly / Yearly** Notes:
  - Weekly notes (ISO weeks) in `~/.zd/weekly/YYWW.md`.
  - Monthly notes in `~/.zd/monthly/YYMM.md`.
  - Yearly notes in `~/.zd/yearly/YY.md`.
  - Automatically generate links to your daily notes.

- **TODO Management**:
  - **Active** and **Done** TODOs stored under `~/.zd/todos/`.
  - Add a TODO item (`<leader>ta`) → prompts you for text, creates a dedicated file, and appends to `active_todos.md`.
  - Mark it **Done** (`<leader>td`) → moves the line to `done_todos.md`.
  - Sort active todos (`<leader>ts`).

- **Projects**:
  - Each project has its own subfolder under `~/.zd/projects/<ProjectName>/`.
  - A main file `main_project.md` is created from a customizable template.
  - Automatically added to `~/.zd/projects/projects.md` (a master index).
  - Quickly open any project from an interactive prompt.
  - Daily notes show all projects grouped by area for quick access.
- **Llama Summaries**:
  - Use `llama-cli` to generate a summary of recent daily notes.
  - Set `g:zd_llama_repo` to select the model repository.
  - `g:zd_llama_end_token` defines a word printed at the end of every summary so the job closes cleanly.
  - Summaries are saved under `~/.zd/summaries/<start>_<end>.txt` (customize via `g:zd_dir_summaries`).
  - Trigger with `<leader>zs` for the last day or call `:call <SID>SummarizeRecentDays(n)` for `n` days.
  - `:call <SID>SummarizeRecentWeeks(n)` summarizes `n` weeks (7×n days).
  - Runs asynchronously so you can keep editing while `llama-cli` works.
- **Whisper Transcription**:
  - Uses [faster-whisper](https://github.com/guillaumekln/faster-whisper) for speedy voice to text.
  - Command configured via `g:zd_whisper_cmd` (defaults to `faster-whisper`).
  - CUDA accelerated and runs asynchronously similar to the summarizer.
  - Transcripts are saved under `~/.zd/transcripts/`.
  - Results open in split windows so you can keep editing while they load.
  - Call `:call <SID>WhisperTranscribe('file.wav')` to convert existing audio.
  - Press `<leader>zr` to **record** with `arecord` for `g:zd_record_seconds` seconds and transcribe.
  - Press `<leader>zR` to record, transcribe, **and summarize** the audio.
  - Summary buffers show the transcript text followed by the LLM's summary.
- **File Summaries**:
  - `<leader>zB` summarizes the current file into a bullet list using `llama-cli`.
  - `<leader>zM` summarizes the current file as structured Markdown with headings.

- **Templating System**:
  - Store your own markdown templates in `~/.zd/templates/` (e.g. `daily.md`, `weekly.md`, etc.).
  - The plugin replaces placeholders like `{{TODAY}}`, `{{READABLE_DATE}}`, `{{PROJECT_NAME}}`, etc.
  - If no template is found, a **fallback** text is created automatically.

- **File-Under-Cursor Creation**:
  - Press `<leader>zn` on a link (e.g. `(~/.../daily/230131.md)`) to auto-create or open that note, hooking into the correct daily/weekly/etc. logic.

---

## Installation ⚙️

1. **Prerequisites**:
   - You need a running Vim or Neovim environment.
   - This plugin is pure Vimscript; no external dependencies required.
  - Install `llama-cli` if you want to use the summary feature.
  - Install `arecord` (from ALSA) to capture audio snippets.
  - Install the `whisper` CLI for compatibility with earlier versions.

2. **Plugin File**:
   - Save the plugin script as `vim-zk.vim` in your local plugin directory:
     - `~/.vim/plugin/vim-zk.vim` for Vim, or
     - `~/.config/nvim/plugin/vim-zk.vim` for Neovim.

3. **Source It** (in your `~/.vimrc` or `~/.config/nvim/init.vim`):
   ```vim
   source ~/.vim/plugin/vim-zk.vim
   ```

4. **(Optional) Create Template Files** under `~/.zd/templates/`, for example:
   - `daily.md`
   - `weekly.md`
   - `monthly.md`
   - `yearly.md`
   - `project.md`
   If no template is found, fallback text is used.

5. **Restart** Vim/Neovim and you’re ready!

## Faster-Whisper Setup 🗣️

The voice transcription feature now relies on the [faster-whisper](https://github.com/guillaumekln/faster-whisper) library.
Set it up like this:

1. Install **Python 3** and **ffmpeg** on your system.
2. Install the package via pip:
   ```bash
   pip install -U faster-whisper
   ```
3. Create a helper script (see `faster_whisper.py` in this repo) and note its location:
   ```python
   #!/usr/bin/env python3
   from faster_whisper import WhisperModel
   import argparse

   parser = argparse.ArgumentParser()
   parser.add_argument("audio")
   parser.add_argument("--model", default="large-v3")
   parser.add_argument("--device", default="cuda")
   parser.add_argument("--output", required=True)
   args = parser.parse_args()

   model = WhisperModel(args.model, device=args.device, compute_type="float16")
   segments, _ = model.transcribe(
       args.audio,
       beam_size=10,
       language="en",
       vad_filter=True,
       condition_on_previous_text=False,
   )
   with open(args.output, "w", encoding="utf-8") as f:
       for seg in segments:
           f.write(seg.text + "\n")
   ```
   Use it with a Python interpreter, e.g. `~/.venv/bin/python3.10 /path/to/faster_whisper.py`.
4. Set `g:zd_whisper_cmd` in your `vimrc` to that command so the plugin can invoke it.
   (If you installed `faster-whisper` system-wide, leave it as the default.)
5. Optionally tweak the model by setting `g:zd_whisper_model` (defaults to `large-v3`).

After setup, press `<leader>zr` to record and transcribe, or call
`WhisperTranscribe('path/to/file.wav')` for existing audio. The transcript (and
optional summary) will appear in dedicated split windows.

## Whisper Setup (optional)

To use the original `whisper` CLI instead of faster-whisper, install it with pip:

```bash
pip install git+https://github.com/openai/whisper.git
```

Ensure `whisper` is on your `PATH`, then set:

```vim
let g:zd_whisper_cmd = 'whisper'
```

The plugin will invoke it just like the faster-whisper script.

---

## Usage & Shortcuts ⌨️

Below are the default mappings (`<leader>` often defaults to `\` in Vim, but you can change it in your `.vimrc`):

16:08❯ cat 20250706-160749.txt

| Mapping      | Action                                                                                       |
|:------------:|----------------------------------------------------------------------------------------------|
| `<leader>zd` | **Daily Note**: Open (or create) your daily note, `~/.zd/daily/YYMMDD.md`.                   |
| `<leader>zw` | **Weekly Note**: Open (or create) your weekly note, `~/.zd/weekly/YYWW.md`.                  |
| `<leader>zm` | **Monthly Note**: Open (or create) your monthly note, `~/.zd/monthly/YYMM.md`.               |
| `<leader>zy` | **Yearly Note**: Open (or create) your yearly note, `~/.zd/yearly/YY.md`.                    |
| `<leader>zn` | **Create/Open Link Under Cursor**: If on `(.../daily/230131.md)`, it auto-creates/opens daily.|
| `<leader>ta` | **Add TODO**: Prompts for a description, creates a unique file, and appends to active todos.  |
| `<leader>td` | **Mark TODO as Done**: Moves the current line from active to done with timestamp.            |
| `<leader>ts` | **Sort Active TODOS**: Sorts lines in `active_todos.md`.                                     |
| `<leader>to` | **Open Active TODOS**: Quickly open `~/.zd/todos/active_todos.md`.                           |
| `<leader>tO` | **Open Done TODOS**: Quickly open `~/.zd/todos/done_todos.md`.                               |
| `<leader>zp` | **Open/Prompt for Project**: Creates or opens a project’s `main_project.md`.                 |
| `<leader>zP` | **Open Projects Index**: Opens the master `projects.md` listing all created projects.        |
| `<leader>zs` | **Summarize Dailies**: Asynchronously run `llama-cli` on the last day (or use `:call <SID>SummarizeRecentDays(n)` for more) and store the result. |
| `<leader>zr` | **Record & Transcribe**: Record via `arecord` then transcribe. |
| `<leader>zR` | **Record, Transcribe & Summarize**: Capture audio and generate a summary. |
| `<leader>zB` | **Summarize File (Bullets)**: Generate a bullet list summary of the current file. |
| `<leader>zM` | **Summarize File (Markdown)**: Summarize the current file with Markdown headings. |


### Example Workflows

1. **Daily Journaling**:
   - Open Vim → type `<leader>zd` → it jumps to today’s note, linking to previous/next day.

2. **Add a Task**:
   - Press `<leader>ta` → type “Refactor the project code.” → A new note file is made, appended to `active_todos.md`.

3. **Create a Project**:
   - Press `<leader>zp` → type “MyAwesomeProject.”
   - A new folder `~/.zd/projects/MyAwesomeProject/` is made, along with `main_project.md` from a template.
   - A link `[MyAwesomeProject](MyAwesomeProject/main_project.md)` is added to `projects.md`.
4. **Record and Transcribe**:
   - Press `<leader>zr` to capture audio for a few seconds and automatically open the transcript.
5. **Record, Transcribe & Summarize**:
   - Press `<leader>zR` to capture audio and view both the transcript and its summary.

---

## File Structure 🗂

By default, the plugin organizes notes under `~/.zd/`:

```
~/.zd/
  ├─ daily/
  ├─ weekly/
  ├─ monthly/
  ├─ yearly/
  ├─ todos/
  │   ├─ active_todos.md
  │   └─ done_todos.md
  ├─ projects/
  │   ├─ projects.md   <-- Master project index
  │   └─ <ProjectName>/main_project.md
  ├─ transcripts/
  │   └─ <audio>.txt
  ├─ recordings/
  │   └─ <timestamp>.wav
  └─ templates/
      ├─ daily.md
      ├─ weekly.md
      ├─ ...
```

You can change these paths in the plugin code if you prefer.

---

## Templates 📝

Each note type can have a markdown template in `~/.zd/templates/
16:08❯ cat 20250706-160749.txt
<type>.md`. For instance, a **daily note** template might look like:

```markdown
# Daily Note {{TODAY}}

[← Prev Day]({{PATH_DAILY}}/{{PREV_DAY}}.md)
[→ Next Day]({{PATH_DAILY}}/{{NEXT_DAY}}.md)
[Weekly]({{PATH_WEEKLY}}/{{WEEK}}.md)
[Monthly]({{PATH_MONTHLY}}/{{MONTH}}.md)
[Yearly]({{PATH_YEARLY}}/{{YEAR}}.md)

---

## {{READABLE_DATE}}

#### Projects by Area
{{PROJECTS_BY_AREA}}

### Morning Thoughts
-

### Important Tasks
- [ ]

### Notes / Observations
-

### Evening Reflection
-
```

Placeholders like `{{TODAY}}`, `{{READABLE_DATE}}`, `{{PREV_DAY}}`, etc. are replaced dynamically.

---

## License ⚖️

http://www.apache.org/licenses/LICENSE-2.0
