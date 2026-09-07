# Ability Link Admin Panel

Separate **web** console for Ability Link operators. Same Firebase project as the Flutter app (`abilitylink-3ac64`).

## How it connects to the mobile app

**You do not need the same Wi‑Fi.** Both apps talk to **Firebase in the cloud**:

```
Phone (Flutter)  ──┐
                   ├──►  Firestore / Auth / Storage  ◄──  Admin (this web app)
Laptop browser   ──┘
```

| Question | Answer |
|----------|--------|
| Same network required? | **No** — Firebase is the shared backend |
| Local / LAN sync? | Not used (and not needed) |
| How does a place approval show on the phone? | Admin writes `places` / `placeSubmissions` → phone already listens with Firestore streams |
| Who can log in? | UID must be in `platformConfig/settings.adminUids` or `moderatorUids` (same as in-app Admin console) |

Optional same-network use: only if you run the admin on `localhost` and open it from another device via LAN IP — that’s just how you **view** the web UI, not how data syncs.

## Setup

1. Firebase Console → add a **Web** app to project `abilitylink-3ac64` (if missing).
2. Copy `.env.example` → `.env.local` and paste the web config.
3. Authentication → enable **Email/Password** (or Google) for admin accounts.
4. Put your admin UID in `platformConfig/settings.adminUids` (same doc the Flutter admin uses).
5. Auth → Settings → Authorized domains → add `localhost`.

```bash
cd admin_web
npm install
npm run dev
```

Open http://localhost:5173

## What’s included (mockup-aligned)

- Dashboard KPIs, pending verifications (`placeSubmissions`), reports (`placeReports`), category chart, accessibility bars, map overview
- Places, Verification queue (approve/reject), Reports triage, Reviews, Users, Categories/config
- Role gate via `platformConfig` (admin / moderator)

## Deploy later

```bash
npm run build
# Host `dist/` on Firebase Hosting, Vercel, or Netlify
```
