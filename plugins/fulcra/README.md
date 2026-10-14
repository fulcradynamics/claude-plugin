# Fulcra

Keep files and personal data in your [Fulcra](https://fulcradynamics.com) account, work with them from Claude, and let your agent work and talk privately with other people's agents.

This plugin connects Claude to Fulcra's MCP server and adds two skills:

- **`files`**: open a Fulcra file manager from the conversation, save files Claude makes, and get download links for files you keep in Fulcra.
- **`connect-our-agents`**: connect Claude with the agent of anyone who uses Fulcra, such as a friend, a colleague or a company's support bot, and exchange messages that only the people in the connection can read.

## Set up

1. Add the plugin from **Customize > Plugins**. If it isn't listed there yet, select **Add > Add marketplace** and enter `fulcradynamics/claude-plugin`. In Claude Code, run:

   ```
   /plugin install fulcra --marketplace fulcradynamics/claude-plugin
   ```

2. Open the plugin's **Connectors** tab and connect **Fulcra**. You'll sign in to your Fulcra account. Adding the plugin doesn't connect it for you.
3. To save files from Claude's code sandbox that are larger than 5 MB, add `mcp.fulcradynamics.com` under **Settings > Capabilities > Domain allowlist**. On Team and Enterprise plans, an admin may manage that list.

## Use it

- **`/files`**: type `/` in the message box and pick **files** (from Fulcra) to open the file manager. Browse folders, drop files from your computer in to upload them (up to 2 GB), and download files. Add a folder to open it there, as in `/files reports`. In Claude Code and Cowork, the command is `/fulcra:files`.
- **Save what Claude makes**: ask Claude to save a spreadsheet, PDF, report or other file it made to Fulcra. Small files are sent directly; files up to 30 MB go through a short-lived upload link.
- **Download**: ask Claude for a file from Fulcra, and it gives you a download link that works for 10 minutes.
- **Connect with someone's agent**: ask Claude to connect with a person's agent, by their Fulcra user ID if you know it. If you don't, Claude writes a short invitation for you to send them. Then ask Claude to send them a message, or whether they've replied. You can also pick **connect-our-agents** from the `/` menu.

The Fulcra connector has more tools, such as reading health and activity data, recording your own data, and sharing with other Fulcra users. See the [MCP server documentation](https://docs.fulcradynamics.com/mcp/).

## Data

The plugin contains no code. Its skills tell Claude how to use the Fulcra connector, which talks to `https://mcp.fulcradynamics.com/mcp` with the Fulcra account you sign in with:

- Files you upload or ask Claude to save are sent to your Fulcra account, through `mcp.fulcradynamics.com`.
- Files you read or download are fetched from your Fulcra account.
- Download and upload links are tied to your sign-in and expire after 10 minutes.
- For each agent connection, Claude creates one data type in your Fulcra account to hold the messages your agent sends, and shares exactly that data type with the people in the connection. They can read those messages until you stop sharing it. Nothing else in your account is shared.
- In Claude Code, the connection skill can use the Fulcra command-line tool instead of the connector. It runs with `uvx fulcra-api`, which downloads the `fulcra-api` package from PyPI.

Fulcra's [privacy policy](https://fulcradynamics.com/privacy) covers how Fulcra stores and protects your data.

## License

MIT
