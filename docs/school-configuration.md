# School configuration and verified-content register

## Purpose

This is the working source-of-truth checklist for school facts used by the SchoolConnect WhatsApp assistant. It is for the first pilot workspace, Little Blue and Yellow Learning Center, Dhrangadhra, Gujarat.

**This is not a public school brochure and is not a live configuration.** The school must review and approve every public-facing fact and every translation before the bot can show it to parents.

## 1. Status rules

Use these states for every school fact and message:

| Status | Meaning | May the bot publish it? |
|---|---|---|
| `NOT_PROVIDED` | No value has been supplied | No |
| `DRAFT` | A sample or proposed value exists | No |
| `NEEDS_VERIFICATION` | Supplied, but school approval is not recorded | No |
| `APPROVED` | An authorised school representative verified it | Not yet |
| `PUBLISHED` | Approved, effective, and enabled for parent-facing use | Yes |
| `ARCHIVED` | Old or withdrawn content | No |

A value can move to `PUBLISHED` only when it has an identified source, an authorised approver, an approval timestamp, and (where relevant) an effective-from date. Translations must be reviewed separately; approval of English text does not approve Gujarati or Hindi text.

## 2. Current pilot register

| Item | Current value | Status | Public use |
|---|---|---|---|
| Working school label | Little Blue and Yellow Learning Center | `NEEDS_VERIFICATION` for public display | No |
| Pilot locality | Dhrangadhra, Gujarat | `NEEDS_VERIFICATION` for public display | No |
| Nursery class | Nursery (first sample class) | `NEEDS_VERIFICATION` | No |
| Nursery tuition fee | ₹7,800 per quarter | `DRAFT` — supplied as a sample; school approval not recorded | No |
| Admission fee | Not supplied | `NOT_PROVIDED` | No |
| Annual / activity / transport / other charges | Not supplied | `NOT_PROVIDED` | No |
| Facilities | No approved list supplied | `NOT_PROVIDED` | No |
| School address and map link | Not supplied | `NOT_PROVIDED` | No |
| Official phone / WhatsApp number | Not supplied | `NOT_PROVIDED` | No |
| Working hours and admission timings | Not supplied | `NOT_PROVIDED` | No |
| Visit days and slot duration | Not supplied | `NOT_PROVIDED` | No |
| Visit-slot capacity and holidays | Not supplied | `NOT_PROVIDED` | No |
| Admissions staff / escalation contact | Not supplied | `NOT_PROVIDED` | No |
| Age criteria, documents and admission policy | Not supplied | `NOT_PROVIDED` | No |
| Gujarati, Hindi and English translations | Planned; not approved | `DRAFT` | No |

The ₹7,800 Nursery amount is retained only as the sample entered in the prototype dashboard. Do not quote it to parents, include it in a template, or mark Nursery fees as published until the school confirms the amount, what it includes, payment dates, any additional charges, and the effective academic year/term.

## 3. Required content fields before publication

For each item, store:

- `school_id` and a stable content key
- Content type (profile, class, fee, facility, FAQ, policy, visit rule, contact, or message)
- Value and language
- Status from the table above
- Source / evidence note (for example, written confirmation from the school)
- `verified_by` (authorised staff identity and role)
- `verified_at` timestamp
- `effective_from` and optional `effective_until`
- `approved_for_publication` boolean
- Last editor and update timestamp

Do not treat a value as approved just because it is present in the dashboard or database. The publication check must require `status = PUBLISHED`, `approved_for_publication = true`, and a valid effective date.

### Content checklist

| Content group | Required details |
|---|---|
| School profile | Approved display name, address, map URL, official phone, website/social links if authorised |
| Classes | Active classes, admission availability, age criteria, academic year |
| Fees | Class, fee type, amount, frequency, inclusions, due dates, additional charges, effective dates |
| Facilities | Each facility's approved name, description, availability by class, and any restrictions |
| Admission process | Steps, documents, application method, deadlines, and any applicable charges |
| FAQs and policies | Answer, language, approval, effective date, and escalation rule |
| Visits | Visit days, exact dates, slot times, slot duration, capacity, holidays, reschedule/cancel rules |
| Staff handoff | Approved team name, operating hours, and authorised contact route |
| Messages | Approved Gujarati, Hindi and English text; template name/category/status where a Meta template is required |

## 4. Agreed example conversation

This is the conversation logic to implement. The Saturday 10:00 AM value is a **parent preference example**, not a published slot or a confirmed appointment.

1. **Welcome:** identify the school assistant and ask the parent to choose Gujarati, Hindi, or English.
2. **Main menu:** School Facilities, Classes, Fees, Admission Process, or Book a School Visit.
3. **Facilities:** parent chooses **School Facilities**.
4. **Class:** bot displays only active, published classes; parent chooses **Nursery** if it has been approved and published.
5. **Facilities answer:** show only facilities published for Nursery. If none are approved, say that the information is being updated and offer to record a request for school staff. Never fill the gap with assumed facilities.
6. **Visit request:** parent chooses **Book a School Visit**.
7. **Date and time:** ask for a date, then query the server for slots. If the parent says **Saturday at 10:00 AM**, treat it as a requested preference until a specific date and an open slot are returned by the booking service.
8. **Contact:** use the inbound WhatsApp number as the contact number where available; ask for the parent's name. Do not request the child's name, date of birth, or other details unless the school has a clear operational need.
9. **Review:** show the exact date, time, and any details being stored; ask the parent to confirm the request.
10. **Booking:** call the trusted server-side booking operation. Only show “confirmed” after its database transaction commits successfully.
11. **If not bookable:** create a visit request / enquiry marked `PENDING_STAFF_CONFIRMATION`; clearly tell the parent that no appointment has been confirmed.
12. **Follow-up:** create or update the enquiry in the correct school workspace and notify authorised staff through the configured internal channel.

### Safe wording for the example preference

> Saturday at 10:00 AM is your preferred visit time. I have not confirmed a slot yet. I will check the school's available dates and times before confirming your visit.

Use this wording until the booking service returns a real available slot. If no visit calendar has been configured, record a request only and do not claim that the school will respond by a particular time.

## 5. Booking states and safeguards

Recommended states:

- `REQUESTED` — parent expressed a preference
- `PENDING_STAFF_CONFIRMATION` — no self-service slot is configured or available
- `AWAITING_PARENT_CONFIRMATION` — an actual slot was offered, awaiting parent acceptance
- `CONFIRMED` — server transaction committed and capacity was reserved
- `CANCELLED` / `RESCHEDULE_REQUESTED` / `COMPLETED`

The booking API must validate the school, slot, date, status, and capacity inside one database transaction. Lock the slot row (or use an equivalent atomic capacity reservation), count active reservations while holding the lock, insert the booking, and commit. A unique idempotency key should prevent duplicate bookings from webhook retries. Never confirm based only on a client-side availability check.

## 6. WhatsApp consent and messaging rules

- Respond to an inbound parent message within the active customer-service window using the permitted message types.
- Record explicit opt-in before sending business-initiated or later proactive messages. Store the opt-in wording/version, timestamp, source, and phone number; do not infer marketing consent from a parent simply asking a question.
- Outside the 24-hour customer-service window, use an applicable Meta-approved message template. Template approval and delivery are separate from appointment confirmation.
- Validate webhook signatures, deduplicate inbound provider message IDs, and keep access tokens and app secrets server-side.
- Provide a clear opt-out path and suppress further non-essential messages after opt-out.
- Keep demo messages in a local/test mode. Never send a real WhatsApp message from the prototype.

## 7. Fallback and handoff behaviour

| Situation | Bot behaviour |
|---|---|
| Facility/class/fee content is missing or not published | Say approved information is not available yet; offer to record an enquiry |
| Parent asks about an unconfigured charge | Do not estimate; create a staff follow-up request |
| Saturday 10:00 AM is not a configured slot | Record it as a preference only; do not confirm |
| Slot is full or booking transaction conflicts | Apologise, refresh availability, and offer another real slot or staff follow-up |
| Duplicate webhook event | Return the prior processing result; do not create a second enquiry or booking |
| Staff contact is not configured | Record the handoff in the admin queue; do not invent a phone number |
| Parent opts out | Record suppression and stop non-essential outbound messaging |

## 8. Launch gate

Do not enable public answers or live booking until all relevant items below are complete:

- [ ] School representative confirms the public display name and locality.
- [ ] School provides and approves address, map link, official contact, and operating hours.
- [ ] School confirms the active class list and Nursery admission availability.
- [ ] School signs off on the full fee schedule, including the ₹7,800 quarterly Nursery sample or a corrected amount.
- [ ] School supplies and approves facilities, admission steps, FAQs, policies, and documents.
- [ ] School defines visit dates, Saturday availability, slot duration, capacity, holidays, and cancellation rules.
- [ ] Staff handoff owner and escalation hours are configured.
- [ ] Gujarati, Hindi, and English parent-facing copy is reviewed and approved.
- [ ] Meta WhatsApp Business Platform setup, opt-in records, webhook verification, and approved templates are tested.
- [ ] Server-side atomic booking, tenant isolation, idempotency, and audit tests pass.

Until then, keep the product in demo/test mode and label all sample data clearly.
