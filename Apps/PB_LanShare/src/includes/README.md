# PB_LanShare Includes

This folder contains the behavior split out of `PB_LanShare.pb`.

Modules:

- `PBLS_DiscoveryUI.pbi`: discovery list UI, quick-send actions, queue views, tray UI helpers, first-run help.
- `PBLS_Settings.pbi`: settings persistence, remembered peers, settings dialog state.
- `PBLS_DiscoveryScan.pbi`: network scan targets, live discovery, remembered/live peer updates.
- `PBLS_Protocol.pbi`: frame serialization, parsing, peer input buffers, shared protocol primitives.
- `PBLS_Transfers.pbi`: upload/download queues, transfer handlers, progress, file/folder transfer flow.
- `PBLS_Network.pbi`: server/client session lifecycle, connection polling, remote session helpers.
- `PBLS_Runtime.pbi`: main window construction, event loop, startup/runtime control flow.

Guidelines:

- Keep behavior changes as small as possible.
- Put UI text/layout changes in `PBLS_DiscoveryUI.pbi` or `PBLS_Runtime.pbi`.
- Put persistence changes in `PBLS_Settings.pbi`.
- Put scan/discovery changes in `PBLS_DiscoveryScan.pbi`.
- Put framing changes in `PBLS_Protocol.pbi`.
- Put file transfer state changes in `PBLS_Transfers.pbi`.
- Put socket/session changes in `PBLS_Network.pbi`.

Rule of thumb:

- If a change touches more than one module, prefer putting shared helpers in the lowest-level module that owns the behavior instead of duplicating logic.
