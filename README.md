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

---

## Usage & Shortcuts ⌨️

Below are the default mappings (`<leader>` often defaults to `\` in Vim, but you can change it in your `.vimrc`):

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

### Example Workflows

1. **Daily Journaling**:
   - Open Vim → type `<leader>zd` → it jumps to today’s note, linking to previous/next day.

2. **Add a Task**:
   - Press `<leader>ta` → type “Refactor the project code.” → A new note file is made, appended to `active_todos.md`.

3. **Create a Project**:
   - Press `<leader>zp` → type “MyAwesomeProject.”
   - A new folder `~/.zd/projects/MyAwesomeProject/` is made, along with `main_project.md` from a template.
   - A link `[MyAwesomeProject](MyAwesomeProject/main_project.md)` is added to `projects.md`.

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
  └─ templates/
      ├─ daily.md
      ├─ weekly.md
      ├─ ...
```

You can change these paths in the plugin code if you prefer.

---

## Templates 📝

Each note type can have a markdown template in `~/.zd/templates/<type>.md`. For instance, a **daily note** template might look like:

```markdown
# Daily Note {{TODAY}}

[← Prev Day]({{PATH_DAILY}}/{{PREV_DAY}}.md)
[→ Next Day]({{PATH_DAILY}}/{{NEXT_DAY}}.md)
[Weekly]({{PATH_WEEKLY}}/{{WEEK}}.md)
[Monthly]({{PATH_MONTHLY}}/{{MONTH}}.md)
[Yearly]({{PATH_YEARLY}}/{{YEAR}}.md)

---

## {{READABLE_DATE}}

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
