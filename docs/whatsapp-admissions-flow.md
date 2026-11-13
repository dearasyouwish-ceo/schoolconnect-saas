# WhatsApp admissions journey

## Status

Design specification only. No WhatsApp number, Meta app, webhook, or live messaging integration is connected.

Supported language choices planned: Gujarati, Hindi, and English. The school must approve every translation before publishing.

## Parent journey

1. Parent starts a conversation with the school's WhatsApp Business number.
2. Bot sends a short welcome and asks the parent to choose Gujarati, Hindi, or English.
3. Bot offers approved information categories: school overview, facilities, classes, fees, admission process, or book a school visit.
4. For class-specific information, show only active classes configured and approved by school management.
5. For fees, show only published fee plans with an effective date. If no approved fee plan exists, offer to connect the parent with admissions staff; never estimate or invent a fee.
6. For a visit, collect the minimum parent contact details needed, show only open slots with remaining capacity, and ask the parent to confirm.
7. Confirm the booking only after the server-side booking transaction succeeds.
8. Send the parent a confirmation with date, time, school contact details, and a cancellation/change route.
9. Create or update the admission enquiry in the correct school workspace and notify authorised staff.

## Data minimisation and consent

- Explain why contact details are requested before collecting them.
- Store the privacy notice version and consent/opt-in evidence.
- Record WhatsApp opt-in timestamp and source before sending proactive messages.
- Do not ask for a child's sensitive information in the first enquiry unless it is necessary.
- Provide a clear human handoff and an opt-out path.
- Keep school tenant identifiers on all records; never trust a tenant ID supplied by an untrusted client.

## Meta WhatsApp Platform requirements

- Use the official WhatsApp Business Platform / Cloud API.
- Verify webhook challenge requests and validate webhook signatures.
- Keep tokens, app secrets, and phone-number credentials in server-side secret storage.
- Deduplicate inbound events by provider message ID.
- Respect the 24-hour customer-service window and use approved message templates when required.
- Handle rate limits, delivery statuses, retries, and opt-outs.

## Booking safety

The client must never calculate capacity and then insert a booking directly. A trusted server-side operation should:

1. Lock the selected visit slot row in a transaction.
2. Confirm the slot belongs to the school and remains open.
3. Validate the slot time and party size.
4. Count active bookings (or reserved capacity) while holding the lock.
5. Reject the request if capacity would be exceeded.
6. Insert the booking and return a confirmation only after commit.

The initial SQL schema does not yet implement this booking operation. Do not enable automated visit booking until it is implemented and concurrency-tested.

## School configuration required before launch

- Approved school name, address, phone number, map link, and working hours
- Verified classes and age criteria
- Published fee structure, payment schedule, and additional charges
- Approved facilities, FAQs, admission documents, and policies
- Visit days, slot length, capacity, holidays, and cancellation rules
- Staff escalation contacts and working hours
- Approved Gujarati, Hindi, and English messages
