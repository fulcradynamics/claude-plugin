---
name: files
description: Open the Fulcra file manager, or move files between Claude and the user's Fulcra account. Use when the user types /files, asks to upload, download, save, browse or share a file in Fulcra, or wants a file Claude made (a spreadsheet, PDF, image, report or data export) kept in Fulcra.
---

# Fulcra files

The user's Fulcra account keeps files of any type, with every version kept. Use the Fulcra connector's tools. Paths are absolute and start with `/`, such as `/reports/q3.xlsx`.

## Before you start

If the Fulcra tools (`open_file_manager`, `read_file`, `write_file`, `list_files`) aren't available, the connector isn't connected. Tell the user to connect it: open **Customize > Plugins > Fulcra**, then the **Connectors** tab, and connect Fulcra. Don't try another way.

## Open the file manager

When the user types `/files` with nothing else, or asks to browse, upload or download files themselves, call `open_file_manager`. If they named a folder (`/files reports`), pass it as `path`, starting with `/`.

The file manager opens as a panel in the conversation. There the user can browse folders, drop files from their computer in to upload them (any type, up to 2 GB), and download files. Say this in one sentence; don't list the folder's contents again.

## Save a file Claude has

Pick by where the file is and how big it is. After saving, tell the user the path.

- **Text you wrote** (notes, JSON, CSV, Markdown): `write_file(path, content)`.
- **A binary file in your sandbox up to 5 MB** (a spreadsheet, PDF or image you made with code): base64-encode it in the sandbox, then `write_file(path, content=<base64>, encoding="base64")`.
- **A file in your sandbox over 5 MB, up to 30 MB:** call `write_file(path, encoding="upload_link")`. It returns a link and a command; run it in the sandbox: `curl -sS -T <file> '<link>'`. The link works once, for 10 minutes.
  - If `curl` can't connect, or the host is blocked, the sandbox can't reach `mcp.fulcradynamics.com`. Tell the user to add `mcp.fulcradynamics.com` under **Settings > Capabilities > Domain allowlist** and try again. On Team and Enterprise plans an admin may manage that list.
  - Meanwhile, offer the file manager: give the user the file to download, then they upload it with `/files`.
- **Over 30 MB:** the user uploads it with the file manager.
- **A file on the user's computer:** Claude can't read it from there. Open the file manager so they can upload it.

Never paste base64 into the conversation for the user, and never print a whole file to save it.

A new file can take a few seconds to show up in `list_files`. If it isn't there yet, wait briefly and check again before saying it failed.

## Give the user a file

- **To download:** `read_file(path, as_link=true)` returns a link that works for 10 minutes. Give the user the link, and say when it expires.
- **To read it yourself:** `read_file(path)`. Spreadsheets (`.xlsx`) come back as CSV, one section per sheet. Large files are cut off at `max_bytes`; raise it only when you need the whole file.
- **A file another user shares:** pass their Fulcra ID as `fulcra_userid`.

## Other file tasks

- **List a folder:** `list_files(path)`.
- **Delete:** `delete_file(path)`, only when the user asks. Earlier versions are kept, so it can be undone.
- **Earlier versions:** writing to an existing path makes a new version. To bring one back, find its ID with `list_files(path, include_versions=true)`, then call `restore_file(version_id)`.
