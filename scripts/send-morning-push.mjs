// Sends the daily Morning Flight notification through OneSignal.
// One message per reminder slot (05:00 to 10:45, every 15 minutes), each delivered at that time in the person's own time zone.
// Needs ONESIGNAL_APP_ID and ONESIGNAL_REST_API_KEY; without them it prints what it would send.
const APP_ID = process.env.ONESIGNAL_APP_ID;
const KEY = process.env.ONESIGNAL_REST_API_KEY;
const SITE_URL = 'https://themorningflight.co.uk/';

const LINES = [
  'Two minutes. Breathe, then pick one thing for today.',
  "Today's word is waiting. Two slow minutes first.",
  'Before the inbox: two minutes for you.',
  "Your flight is ready. What's one thing for today?",
  'Slow breath in, slower breath out. Your two minutes are here.',
];
const day = Math.floor(Date.now() / 864e5);
const body = LINES[day % LINES.length];

const slots = [];
for (let h = 5; h <= 10; h++) for (const m of [0, 15, 30, 45]) slots.push([h, m]);
const label = (h, m) => `${h > 12 ? h - 12 : h}:${String(m).padStart(2, '0')}${h < 12 ? 'AM' : 'PM'}`;
const tag = (h, m) => `${String(h).padStart(2, '0')}${String(m).padStart(2, '0')}`;

let failed = 0;
for (const [h, m] of slots) {
  const payload = {
    app_id: APP_ID,
    target_channel: 'push',
    filters: [{ field: 'tag', key: 'remind_time', relation: '=', value: tag(h, m) }],
    headings: { en: 'Morning Flight' },
    contents: { en: body },
    url: SITE_URL,
    delayed_option: 'timezone',
    delivery_time_of_day: label(h, m),
    web_push_topic: 'morning-flight-daily',
  };
  if (!APP_ID || !KEY) { console.log('[dry run]', tag(h, m), payload.delivery_time_of_day, body); continue; }
  const res = await fetch('https://api.onesignal.com/notifications?c=push', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Key ${KEY}` },
    body: JSON.stringify(payload),
  });
  const json = await res.json().catch(() => ({}));
  // A slot nobody has picked comes back with no recipients; that's fine.
  const empty = JSON.stringify(json.errors || '').includes('not subscribed');
  if (!res.ok && !empty) { failed++; console.error(tag(h, m), res.status, JSON.stringify(json)); }
  else console.log(tag(h, m), empty ? 'no one at this time' : `sent ${json.id || ''}`);
}
if (failed) process.exit(1);
