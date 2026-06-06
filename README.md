# Voyagora

**From idea to itinerary in minutes.** A single-page travel-itinerary web app. Fill in a
trip-planning form, the app sends it to an [n8n](https://n8n.io) webhook, and renders the
returned itinerary as a polished, day-by-day plan with weather.

The entire app is one self-contained `index.html` (React + Babel from CDN, no build step).
It works by opening the file directly (`file://`) or hosted on any static host.

---

## Run locally

Just open `index.html` in a browser, or serve it:

```bash
# Python
python -m http.server 8080
# then visit http://localhost:8080

# or Node
npx serve .
```

Click **Load demo trip** to prefill the form and test the full flow.

---

## Configuration

The webhook URL lives in one constant at the top of the `<script type="text/babel">` block in `index.html`:

```js
const WEBHOOK_URL = "https://zeeshansaeed777.app.n8n.cloud/webhook/4ba21abf-25a1-48cd-bf30-07b299673352";
const ENABLE_OPEN_METEO_FALLBACK = true; // free, keyless weather enrichment when the model omits weather
```

The app POSTs the form as JSON and renders the returned itinerary. The response normalizer is
resilient: it unwraps common n8n / model shapes (top-level array, `{json}` wrapper, `output` /
`text` / `content` / `choices[0].message.content` fields, fenced ```` ```json ```` blocks), fills
missing fields with safe defaults, and **never crashes** — on any failure it shows a clear message
instead of a blank screen. If the model returns prose instead of JSON, the app renders that text
nicely as a fallback.

---

## Supabase setup (auth + saved trips)

Voyagora supports optional **email login** and **saved trip history** via Supabase. If the two
constants are left as placeholders the app still works fully — the auth UI is simply hidden.

1. Create a project at [supabase.com](https://supabase.com). Copy **Project URL** and the
   **anon public** key from **Project Settings → API**.
2. Paste them into the two constants at the top of the script in `index.html`:
   ```js
   const SUPABASE_URL = "https://YOUR-PROJECT.supabase.co";
   const SUPABASE_ANON_KEY = "your-anon-public-key";
   ```
3. Run the SQL in [`supabase-schema.sql`](supabase-schema.sql) in **Supabase → SQL Editor** to
   create the `itineraries` table and row-level-security policies.
4. **Auth → Providers → Email**: keep Email enabled. To let users use the app immediately after
   sign-up, turn **"Confirm email" OFF** (otherwise Supabase requires the confirmation link before
   a session is issued; the app handles both, showing "Check your email for a confirmation link.").
5. **Auth → URL Configuration**: add your site URL (e.g. `https://voyagora.netlify.app`) to the
   allowed redirect/site URLs.

> Note: the Supabase CDN library defines a global named `supabase`, so the client in this app is
> named `sb` to avoid a redeclaration clash — keep it that way.

---

## n8n setup (required for the full interactive layout)

The workflow is **Webhook → Message a model → Respond to Webhook**.

1. **Webhook node** — set **HTTP Method** to `POST`. Under **Options → Allowed Origins (CORS)**,
   set `*` (or your deployed domain) so the browser can call it.
2. **Message a model node** — paste the system prompt below so it returns **only** the itinerary
   JSON in the required schema (and respects the requested date range).
3. **Respond to Webhook node** — return the model output as-is; the frontend unwraps it.
4. **Activate / publish** the workflow. The **Production** webhook URL only responds when the
   workflow is active; the **Test** URL fires only once per "Listen for test event".

### System prompt for the "Message a model" node

```
You are a travel itinerary planner. You receive a JSON trip request and must
respond with ONLY a valid JSON object — no prose, no markdown, no code fences —
matching EXACTLY this schema:

{ destination, title, summary, dates, preferences[], days: [ {
  dayNumber, date, theme, weatherSummary,
  weather: { condition, icon, temperature, rainProbability, wind, travelAdvice },
  morning: [activity], afternoon: [activity], evening: [activity],
  restaurants: [ {name, cuisine, foodPreferenceMatch, location, estimatedCost, mapUrl} ],
  backupPlan, estimatedBudget, walkingLevel
} ] }

activity = { time, title, description, location, indoorOutdoor, estimatedCost, whyRecommended, mapUrl }
- "icon" is one of: rain | sun | cloud | partly | wind
- "indoorOutdoor" is one of: Indoor | Outdoor | Covered | Mixed
- Generate one entry in "days" per day between startDate and endDate (inclusive).
- Tailor every field to the destination, dates, travelers, travelerType, budget,
  pace, interests, foodPreference, mobilityPreference and specialNotes provided.
- Output JSON only.
```

> Tip: pass the incoming form data to the model as the user message, e.g.
> `={{ JSON.stringify($json.body) }}`, so it tailors the plan to the request.

---

## Deploy

It's a static file — host it anywhere:

- **GitHub Pages** — push to GitHub, then Settings → Pages → deploy from `main` / root.
- **Netlify / Vercel / Cloudflare Pages** — drag-and-drop the folder, or connect the repo
  (no build command, publish directory `.`).

After deploying, make sure the n8n Webhook node's **Allowed Origins (CORS)** includes your live
domain (or `*`).
