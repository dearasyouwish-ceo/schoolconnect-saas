# Security and acceptance checklist

This is a manual test plan for the initial schema. It is not a substitute for automated tests or a security review.

## Tenant isolation

Create two test schools (School A and School B) and separate authenticated users:
- A-owner is a member of School A only.
- B-owner is a member of School B only.
- A-user is a second member of School A with a limited role.

For every tenant-owned table — school_branches, school_classes, fee_plans, school_content, parents, students, admission_enquiries, visit_slots, visit_bookings, whatsapp_channels, and message_logs:

- [ ] A-owner can read School A rows.
- [ ] A-owner cannot read School B rows, even when they know a row UUID.
- [ ] A-owner cannot insert a row with School B's school_id.
- [ ] A-owner cannot move an existing School A row to School B by updating school_id.
- [ ] B-owner has the inverse result.
- [ ] A non-member cannot read or mutate either school's data.
- [ ] An unauthenticated (anon) request cannot read or write private school records.
- [ ] A user cannot add themselves to school_memberships through the client API.
- [ ] A user can read only their own membership rows.

## Role authorization — required before production

Current tenant policies permit all authenticated school members to perform CRUD on tenant tables. This is intentionally an initial development baseline, not a complete role model.

- [ ] owner can manage workspace, staff, fees, and integrations.
- [ ] admin can manage school operations but cannot transfer ownership.
- [ ] admissions can manage enquiries, parents, bookings, and approved content only.
- [ ] teacher can access only the student information needed for their work.
- [ ] viewer is read-only.
- [ ] Staff cannot grant themselves a higher role.
- [ ] Membership invitations and revocations happen through a trusted server-side workflow.

## Visit booking concurrency — required before enabling bookings

Do not expose direct client inserts into visit_bookings as a public booking flow. Build a server-side/database transaction that locks the slot row, checks that it is open, validates the requested party size, counts active bookings, and inserts only if capacity remains.

- [ ] Two simultaneous requests for the final available place cannot both succeed.
- [ ] Cancelled bookings release capacity exactly once.
- [ ] Closed slots reject new bookings.
- [ ] Booking parent and enquiry belong to the same school as the slot.
- [ ] Time zone and daylight-saving behavior are tested.
- [ ] Duplicate webhook deliveries do not create duplicate bookings.

## WhatsApp safety and reliability

- [ ] Verify Meta webhook signatures and challenge verification.
- [ ] Keep access tokens and app secrets server-side only.
- [ ] Store explicit opt-in timestamp, source, and notice version.
- [ ] Provide a clear opt-out path and suppress future marketing messages after opt-out.
- [ ] Use approved templates when required and respect the 24-hour customer-service window.
- [ ] Handle retries and duplicate inbound message IDs idempotently.
- [ ] Do not send unverified fees, classes, facilities, or school policies.
- [ ] Test Gujarati, Hindi, and English content with school-approved translations.

## Privacy and operations

- [ ] Publish a parent-facing privacy notice before collecting data.
- [ ] Collect only the minimum parent/child information needed for the requested action.
- [ ] Restrict access to children's records and avoid exposing them in public pages.
- [ ] Define retention, correction, export, and deletion procedures.
- [ ] Configure backups, monitoring, incident response, and access reviews.
- [ ] Use synthetic data in staging and screenshots.
- [ ] Confirm the applicable Indian privacy and child-data obligations with qualified counsel.

## Prototype acceptance

- [ ] Dashboard loads on desktop and mobile.
- [ ] Demo enquiry can be added, searched, and filtered in the browser.
- [ ] Demo mode and non-live integrations are clearly labelled.
- [ ] No real personal data is stored in the prototype.
- [ ] Fees and facilities remain unconfigured until school approval.
