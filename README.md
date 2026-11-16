# SchoolConnect SaaS

A reusable school-management workspace with admissions tracking and a WhatsApp-assisted parent enquiry journey.

## Current status

**Prototype stage.** The dashboard uses local demo data only. It is not connected to a live school database, WhatsApp number, or production booking service.

The first pilot workspace is intended for Little Blue and Yellow Learning Center, Dhrangadhra, Gujarat. School facts must be confirmed by the school before publication. The Nursery tuition sample of ₹7,800 per quarter is stored as an unverified draft only; it must not be shown to parents. Other fees, classes, facilities, timings, address, and policies remain unconfigured. See [the school configuration and verified-content register](docs/school-configuration.md) for statuses, bot fallback rules, and launch gates.

## Modules

- Multi-school workspaces and staff membership
- Admissions enquiry pipeline
- Parent and student directory
- Class and fee configuration
- Facilities and frequently asked questions
- Visit-slot scheduling and capacity-aware booking
- WhatsApp conversation and template management
- Reports, audit history, and school settings

## Technology direction

- Frontend: responsive web app
- Backend: Supabase Postgres, Auth, and Row Level Security
- Messaging: Meta WhatsApp Cloud API through a server-side webhook / n8n
- Hosting: static hosting for the prototype; managed deployment for production

## Preview

Open `index.html` in a browser. The prototype uses browser-local demo data. Do not enter real student or parent data.

## Database

The initial schema is in `supabase/migrations/0001_schoolconnect_core.sql`. Review it with a Supabase engineer before applying it to a production project. It intentionally does not include public anonymous write access or a privileged booking function.

## Before production

1. Configure Supabase Auth and secure school-membership provisioning.
2. Review grants and RLS policies for every exposed table and every role.
3. Add role-specific access controls and audit logging.
4. Build a server-side public enquiry endpoint with validation and abuse protection.
5. Implement visit booking as a database transaction that safely enforces slot capacity under concurrency.
6. Connect WhatsApp Cloud API using server-side secrets only.
7. Capture explicit WhatsApp opt-in; follow Meta's approved-template and 24-hour customer-service-window rules.
8. Add privacy notices, retention/deletion workflows, backups, monitoring, and incident procedures.
9. Obtain school approval for all published classes, fees, facilities, operating hours, and admission policies.

Never expose Supabase service-role keys or WhatsApp access tokens in browser code.
