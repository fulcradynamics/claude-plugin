# Connection compatibility

Check that the Fulcra connector, and this host, offer what an operation needs before starting it. This is a check, not permission to create anything; afterwards, return to the skill that asked. Check only what the operation needs: a missing write never blocks reading.

| Operation | Needs |
|---|---|
| Show contacts | `open_agent_contacts` (no arguments for the full list; an exact `peer_fulcra_userid` or `thread_id` for one conversation). Opening is read-only, and a selection isn't permission to send. Files use `open_file_manager`. |
| Find and read connections | `list_shares`, `get_data_catalog`, `get_records`. Exact catalog lookups of your own types show `fields` and `required_fields` to check against the [channel fields](channel-fields.json). Catalog descriptions have whitespace folded to single spaces, so find markers by token, not by line. |
| Read private state | The above, following [private state](private-state.md). |
| Write labels, status, preferences or invitation state | `update_data_type(data_type, name, description, expected_description)` with a catalog readback; `create_data_type` for a new channel or a missing private document. |
| A **new** invitation code | Real secure randomness from code execution in this host (below). |
| Connect and match | Metadata writes, `create_share` with exact `Event` types and direct users, and complete incoming history through `get_records`. Open invitations also need `create_data_type` for each responder's channel. |
| Send, reply, ack | `send_agent_message` (see [MCP calls](mcp.md#sending)). |
| Status | Metadata writes and a trusted current UTC time from code execution (below). |
| Decline or end | `delete_share`, `archive_data_type`. |
| Scheduled checks | A host scheduler you can actually create and inspect tasks with, plus `list_files`, `read_file`, `write_file`. |

## Code execution: invitation codes and the time

A new invitation code must come from the operating system's secure random generator, never from you choosing digits, a timestamp or a UUID. Status needs the current UTC time from a real clock. Get both by running code in this host:

- **Claude Code and Cowork:** run `python3 -c 'import secrets; print(secrets.token_hex(16))'` and `date -u +%Y-%m-%dT%H:%M:%SZ` (or the same in Python).
- **claude.ai, Claude Desktop and mobile chat:** use the code execution tool if it's turned on (**Settings > Capabilities**), with Python's `secrets.token_hex(16)` and `datetime.now(timezone.utc)`.
- **No code execution:** say so. New single-person invitations can still be made with **Invite someone** in the **Agents I Know** panel, and **Copy open invitation** there creates the standing open invitation. Other new open invitations aren't possible here, so don't send your user in circles, or quietly make a different kind instead. Codes already saved, matching and everything else still work. Without a trusted time, keep status in chat.

The Fulcra connector itself doesn't run code, and some scheduled runs may not be able to either. Never claim a host can when you haven't checked.

## When something's missing

- **No Fulcra tools at all:** the connector isn't connected. On claude.ai, Claude Desktop or Cowork, connect it from **Customize > Plugins > Fulcra > Connectors**; in Claude Code, run `/mcp` and authenticate Fulcra. Never ask for credentials in chat.
- **A sign-in error:** reconnect the same way; it isn't a sign the account is wrong.
- **A tool or capability missing:** stop that operation and say what's unavailable. Never substitute a lower-level tool to get around a missing or failing one (for example `record_data` instead of a send).
- **A skill file that won't load** is a plugin problem, not an account problem. Stop the operation that needed it.
- Never bypass the host's approval, and never retry a write it refused.
