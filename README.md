# Fulcra Claude Plugin

This repository is a Claude plugin marketplace. It holds one plugin, [`fulcra`](plugins/fulcra/README.md), which connects Claude to your Fulcra account and adds a couple of skills derived from our `agent-skills` repo.

## Install

- **claude.ai, the Claude desktop app and Cowork:** go to **Customize > Plugins**, select **Add > Add marketplace**, and enter `fulcradynamics/claude-plugin`. Then add **Fulcra**, and connect it from the plugin's **Connectors** tab.
- **Claude Code:**

  ```
  /plugin install fulcra --marketplace fulcradynamics/claude-plugin
  ```

## Layout

```
.claude-plugin/marketplace.json     the marketplace: lists the plugins here
plugins/fulcra/
  .claude-plugin/plugin.json        the plugin's manifest
  .mcp.json                         the Fulcra MCP server (https://mcp.fulcradynamics.com/mcp)
  skills/files/SKILL.md             the files skill, /files in the / menu
  skills/connect-our-agents/        copied from agent-skills; see below
  README.md                         the directory listing's description
scripts/sync-skills.sh              copies skills from agent-skills
skills.lock                         which skills are copied, and from which commit
```

## Development: syncing skills from agent-skills

`connect-our-agents` lives in [fulcradynamics/agent-skills](https://github.com/fulcradynamics/agent-skills), and this plugin carries a copy. Change it there, never here: the next sync overwrites the copy.

```sh
scripts/sync-skills.sh           # copy the skills in skills.lock from agent-skills' main
scripts/sync-skills.sh <ref>     # from a branch, tag or commit
scripts/sync-skills.sh --check   # fail if a copy differs from its commit in skills.lock
```

To add another skill from agent-skills, add a line `<skill-name> main` to `skills.lock` and run the sync.

## Develop

```sh
claude plugin validate .                  # the marketplace
claude plugin validate ./plugins/fulcra   # the plugin
claude --plugin-dir ./plugins/fulcra      # try it in Claude Code: /fulcra:files
```

To try it on claude.ai, zip `plugins/fulcra` and upload it under **Customize > Plugins > Add > Upload plugin**.

Raise `version` in `plugins/fulcra/.claude-plugin/plugin.json` with every release. The directory submission points at the `plugins/fulcra` folder.

## License

MIT
