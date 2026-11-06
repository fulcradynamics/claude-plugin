# Fulcra Claude Plugin

This repository is a Claude plugin marketplace. It holds one plugin, [`fulcra`](plugins/fulcra/README.md), which connects Claude to your Fulcra account and adds skills for files and for connecting with other people's agents.

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
  .mcp.json                         the Fulcra MCP server (https://mcp.fulcradynamics.com/claude/mcp)
  skills/                           the skills; see below
  README.md                         the directory listing's description
provenance.json                     where each skill came from, with source hashes
scripts/check-upstream.py           what changed upstream since the skills were adapted
scripts/check-tools.py              whether every tool the skills call exists on a server
scripts/sync-skills.sh              copies skills verbatim from agent-skills (none at the moment)
skills.lock                         which skills sync-skills.sh copies
```

## Where the skills come from

- **The contact skills** (`agents-i-know`, `invite`, `send`, `check-messages`, `reply-to-messages`, `set-up-agent-contacts`, `connect-our-agents`) are adapted for Claude from the ChatGPT Fulcra plugin, [fulcradynamics/fulcra-openai-plugin](https://github.com/fulcradynamics/fulcra-openai-plugin). They're rewritten, not copied: Claude has no setup button, no native settings, no @-mentions and different scheduling, and the text is plainer. `provenance.json` records each file's source and a hash of the source content it was adapted from.
- **`files`** is written for Claude.
- **`connect-our-agents`** used to be a verbatim copy from [fulcradynamics/agent-skills](https://github.com/fulcradynamics/agent-skills). That skill still exists there, for agents that use the Fulcra CLI or other hosts; the plugin's version uses the connector's contact tools, which the CLI doesn't have.

To see what changed upstream since the skills were adapted, and port it by hand:

```sh
scripts/check-upstream.py <fulcra-openai-plugin checkout>           # against its origin/main
scripts/check-upstream.py <fulcra-openai-plugin checkout> <ref>     # against another ref
scripts/check-upstream.py <fulcra-openai-plugin checkout> <ref> --repin   # after porting
```

It lists changed sources and upstream skill files nothing here comes from yet (unless `provenance.json` lists them under `ignored_upstream`).

## Develop

```sh
claude plugin validate .                  # the marketplace
claude plugin validate ./plugins/fulcra   # the plugin
scripts/check-tools.py <fulcra-context-mcp checkout>   # every tool the skills call exists
claude --plugin-dir ./plugins/fulcra      # try it in Claude Code: /fulcra:agents-i-know
```

The plugin uses the server's `/claude/mcp` endpoint, the same URL as Fulcra's directory connector, so people with both see one set of tools. `scripts/check-tools.py` checks that endpoint. Check that `mcp.fulcradynamics.com` serves any new tools the skills call before releasing.

To try it on claude.ai, zip `plugins/fulcra` (or run `build-dev.sh` for a build against dev) and upload it under **Customize > Plugins > Add > Upload plugin**.

Raise `version` in `plugins/fulcra/.claude-plugin/plugin.json` with every release. The directory submission points at the `plugins/fulcra` folder.

## License

MIT
