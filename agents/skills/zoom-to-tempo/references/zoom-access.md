# Zoom access

The connected Zoom tools were validated on 2026-10-29. Discover the current tool schemas in each session, and prefer `search` over the deprecated `search_meetings`. The connector's OAuth connection handles authentication, so no local Zoom token is needed. If the tools disappear, find the Zoom integration among the installed plugins or connectors and reconnect it.

## Steps

1. Call `search_describe_capabilities` for both `zoom_meeting` and `zoom_my_notes` before building date or metadata filters. Use the user's time zone (Europe/London by default) and convert each local date boundary to UTC, accounting for daylight saving time.
2. Search `zoom_meeting` with `meeting_start_time >= start` and `< end-boundary`, and run a separate notes filter for each data source. Keep paging until `has_more` is false. Actual and scheduled meeting times are different fields. Check `meeting_roles` and the attendee list, because being invited does not prove attendance. Meetings that cross midnight need overlap-aware handling.
3. Search `zoom_my_notes` with `doc_view=my_docs`, then again with `doc_view=shared_with_me`. The `recent` view helps discovery but doesn't prove the inventory is complete. A note's `create_time`/`modify_time` are file timestamps, not attendance times. Filtering by creation date finds likely candidates quickly, but it can miss notes created later, so widen the search when needed. Keep colleague-hosted notes, and don't filter by `created_by=@me` as a shortcut.
4. Retrieve each relevant note with `my_notes_get_note_content(noteId=<search file_id>, include="transcript")`. This returns the manual and generated content plus transcript items with speaker names. Empty manual content does **not** mean an empty transcript. `hub_get_file_content` has returned an empty body for notes that did have a full transcript, so use the dedicated My Notes tool for meeting content.
5. Transcript `start_time`/`end_time` are offsets from the start of the recording, not UTC timestamps, and they aren't a reliable attendance duration. Match each note to the actual meeting metadata. Fall back to the browser's Zoom reports when per-user join and leave times are missing, or when a room session outlasted the user's attendance. Use recording or asset tools only when their prerequisites are met. A permission flag or error can explain content that isn't available.

## Lessons from validation

- A meeting search returns the actual start and end, plus each person's role and the attendee list. When the user's role was only `invitee` and other evidence (such as a later call's transcript) shows they missed it, don't log it. A meeting record existing doesn't mean the user attended.
- Notes from colleague-hosted calls returned full transcripts with speaker names, so attendee-side access works beyond the user's own hosted meetings.
- The `shared_with_me` search can legitimately return nothing.
- `ask` returns HTTP 403 without a Zoom Ask license. Use search and dedicated retrieval instead, and don't retry `ask` or suggest an upgrade for routine time reconciliation.
- Discovering meetings and retrieving notes and transcripts works without a browser. Exact per-user join and leave reports, and summary or recording retrieval, are not fully validated through the connector, so use the browser for those specific gaps.

Sources: [Zoom Meetings MCP](https://developers.zoom.us/docs/mcp/zoom-meetings-mcp-server/), [Zoom MCP authentication](https://developers.zoom.us/docs/mcp/servers/). Prefer the connected tools' live schemas over older endpoint documentation.
