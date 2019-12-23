## Statusryne

This is a fairly simple satusline and tabline plugin for vim.

#### Satusline

![Preview of long normal mode](screenshots/statusryne.png)
![Preview of short normal mode git](screenshots/statusryne-git.png)
![Preview of short normal mode](screenshots/statusryne-short.png)
![Preview of short insert mode](screenshots/statusryne-insert.png)
![Preview of short visual mode](screenshots/statusryne-visual.png)

Left side: Mode, filename, git branch, git additions and deletions.

Right side: Word count, character count, file size (as reported by `du`),
spelling language, filetype, percentage through file in lines, line count/ total
line count, cursor column line.

Features:

* *(Filename set dynamically)* Depending on the size available in the terminal,
  first the full path of the file is displayed, else a shortened path is
  displayed, else only the basename is shown.

* *(Colour indicator)* Automatic mode dependent colour switching.

* *(Git information)* Display git branch with insertions and deletions

#### Tabline

![Preview of tabline](screenshots/statusryne-tabline.png)
![Preview of tabline](screenshots/statusryne-tabline-widths.png)

Features:

* *(Equal spacing)* Tab widths are set to equal lengths whenever a new buffer is
  opened.
