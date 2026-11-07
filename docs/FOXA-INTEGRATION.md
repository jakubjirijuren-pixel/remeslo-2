# FOXA ↔ ŘEMESLO 2.0

## Implemented

- Separate FOXA and REMESLO tables for supplier connections, orders and events.
- RLS on both projects; REMESLO `decide_incoming_order` checks manager/system administrator and only allows pending → accepted/rejected.
- REMESLO UI: incoming orders and accept/reject.
- FOXA reusable Next/React component: order drafts and supplier selection (`src/components/FoxaOrdersModule.tsx` in FOXA repository).

## Not yet live

- Cross-project server-to-server transport, pairing/approval, credentials, retries, status callbacks, and attachment transfer are NOT configured.
- Supplier directory remains empty and disabled until pairing is completed.
- FOXA component must be wired into the actual running FOXA app and environment variables configured.
- Do not send service-role keys to browser or commit secrets. Set up Edge Function secrets and a per-connection signed transport.
- End-to-end testing required before production use.
