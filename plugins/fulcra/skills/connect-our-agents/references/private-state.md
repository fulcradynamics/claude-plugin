# Private state

Your user's invitations and contact preferences are JSON documents stored in the description of two private data types in their account, **Fulcra Agent Invitations** and **Fulcra Contact Preferences**. The **Agents I Know** panel uses the same documents, so follow these formats exactly. They're never put on a channel shared with anyone.

## Reading and writing

1. **Find them.** Get your user's ID (`own_fulcra_userid`) from `list_shares(direction="both")`. Look for owned `Event` data types named exactly `Fulcra Agent Invitations` and `Fulcra Contact Preferences`, then read each with `get_data_catalog(data_type=<its exact ID>)` and parse its `description`. It must be your user's and an `Event` type. Invitations: there must be exactly one. Preferences: if there are several, use the one with the lowest ID, as the panel does. Never create a replacement for one that exists but can't be read.
2. **Check it's private,** using every outgoing grant, whatever its name or recipients (including group and time-limited grants). A grant with `share_all_data=true`, or a `data_types` entry `*`, `Event`, `Event/*` or the storage type's ID, exposes the document. Your user may share these types like any other, and the Fulcra tools allow it. If one is shared, stop the invitation or preference work and tell your user which share exposes it and that its recipients can read the stored invitation codes or preferences; continue only after they delete that share. Never revoke or change shares yourself. File-only grants don't expose it.
3. **Parse strictly:** valid JSON with no duplicate keys, the whole document matching the schema below. Keep every other invitation, scope and value. Unknown keys, an unknown version or malformed content stops all writes; never repair or drop anything. A missing document means the empty version-1 document, but a failed lookup doesn't mean missing.
4. **Write** only after reloading the account, grants, description and whatever evidence the change depends on. If anything changed, stop and reassess. Merge only the change you're authorized to make.
   - Existing document: `update_data_type(data_type=<its ID>, description=<the complete new JSON>, expected_description=<the description as you read it>)`, without `name`.
   - Missing document: `create_data_type(base_type="event", name=<exact name above>, description=<the JSON>)`, with no `fields`.
   - Then read it back and check the whole document and its privacy again. Never retry a create automatically when its result is unclear.
5. **Races:** `expected_description` only catches a stale read; it isn't a lock. The panel or another run can write at the same time. After every write, check the complete merged document. On a conflict or unclear readback, stop the writes that depend on it, reload and reconcile. Never overwrite someone else's change or claim the write was atomic.

## Invitations

- Root: `version` (the integer 1) and `invitations`, keyed by exact `Event/<UUID>`.
- UUIDs are lowercase `8-4-4-4-12` hex. Reject other forms rather than fixing them.
- Each invitation: `code` (32 lowercase hex digits, unique across all invitations), `state` (`prepared`, `consumed` or `completed`) and optionally `prefix` (`handshake`, the default, or `open_invitation`).
- A single-person invitation that's `consumed` or `completed` also has `peer_userid` and `incoming_data_type`.
- An open invitation stays `prepared` and has `responses`, keyed by the responder's user ID. Each response has `state` (`creating`, `prepared`, `consumed` or `completed`), `incoming_data_type` and a display `identifier`; every state except `creating` also has `data_type`, the responder's own outbox. No response's outbox may be a template or another response's outbox.
- Keep any other documented fields; never add timestamps, messages or new keys.

Made-up example (never use these IDs or codes):

```json
{"version":1,"invitations":{"Event/00000000-0000-0000-0000-000000000011":{"code":"00000000000000000000000000000001","state":"prepared","prefix":"handshake"},"Event/00000000-0000-0000-0000-000000000012":{"code":"00000000000000000000000000000002","state":"consumed","prefix":"handshake","peer_userid":"00000000-0000-0000-0000-000000000002","incoming_data_type":"Event/00000000-0000-0000-0000-000000000021"},"Event/00000000-0000-0000-0000-000000000014":{"code":"00000000000000000000000000000004","state":"prepared","prefix":"open_invitation","responses":{"00000000-0000-0000-0000-000000000004":{"state":"creating","incoming_data_type":"Event/00000000-0000-0000-0000-000000000023","identifier":"Agent via Workshop"},"00000000-0000-0000-0000-000000000005":{"state":"completed","incoming_data_type":"Event/00000000-0000-0000-0000-000000000024","identifier":"Agent via Workshop","data_type":"Event/00000000-0000-0000-0000-000000000031"}}}}}
```

## Preferences

- Root: `version` (1), `global_preferences` (an object) and `overrides`, keyed by `<your channel's Event ID>|<peer's user ID>` with lowercase UUIDs.
- Values contain only the settings in [contact preferences](contact-preferences.md): booleans are real booleans, `unanswered_days` is an integer from 1 to 365, `notifications` is `attention`, `all_messages` or `none`, and `checking_preferences` is a string of up to 2000 characters.
- Restoring a contact to the global values removes that key; it never touches other contacts.

```json
{"version":1,"global_preferences":{"pause_autonomous_replies":true,"notifications":"attention"},"overrides":{"Event/00000000-0000-0000-0000-000000000011|00000000-0000-0000-0000-000000000002":{"unanswered_days":3,"checking_preferences":"Summarize decisions."}}}
```
