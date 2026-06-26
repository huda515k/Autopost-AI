# AutoPost AI — Backend (auto-posting)

This small Node + Express server lets the Flutter app **automatically publish**
posts to X, Instagram, Facebook and LinkedIn from **any** platform (including
desktop, where the OS share sheet can't reach those apps).

It wraps a **unified social-posting API** ([Ayrshare](https://www.ayrshare.com/))
so you don't have to register and get four separate platform APIs approved.
The API key lives only here — never in the app.

```
Flutter app  →  this backend (holds the key)  →  Ayrshare  →  X / IG / FB / LinkedIn
```

## 1. Get an API key

1. Sign up at https://www.ayrshare.com/ and open the dashboard.
2. Copy your **API Key**.
3. **Connect your social accounts** in the dashboard (Social Accounts page).
   - Free tier links **one** set of accounts (good for testing with your own).
   - Multi-user (each app user links their own) needs the **Business plan**
     (user "Profiles" + JWT) — then also set `AYRSHARE_PRIVATE_KEY`.

> Platform rules the API can't bypass: **Instagram** posting requires a
> Business/Creator account; **Facebook** posts go to a **Page**, not a personal
> profile.

## 2. Run locally

```bash
cd server
cp .env.example .env          # then put your key in AYRSHARE_API_KEY
npm install
npm start                     # listens on http://localhost:3000
```

Check it: `curl http://localhost:3000/health` → `{"ok":true,"configured":true}`

## 3. Point the app at it

Run the Flutter app with the backend URL defined:

```bash
# local backend, app on the same machine (desktop)
flutter run -d macos --dart-define=BACKEND_URL=http://localhost:3000

# a deployed backend (use this for phones)
flutter run --dart-define=BACKEND_URL=https://your-backend.onrender.com
```

When `BACKEND_URL` is set, the **Post to X/Instagram/Facebook/LinkedIn** buttons
publish automatically (with a share-sheet fallback if a call fails). When it's
**not** set, the app behaves exactly as before (share sheet only). Use
**Profile → Connect Social Accounts** to link accounts.

## 4. Deploy (so phones can reach it)

Any Node host works — e.g. [Render](https://render.com), Railway, Fly.io:
- Root/working dir: `server`
- Build: `npm install` · Start: `npm start`
- Set env var `AYRSHARE_API_KEY` (and `AYRSHARE_PRIVATE_KEY` for multi-user).

Then rebuild the app with `--dart-define=BACKEND_URL=https://<your-host>`.

## Endpoints

| Method | Path           | Purpose                                            |
|--------|----------------|----------------------------------------------------|
| GET    | `/health`      | Liveness + whether the key is configured           |
| POST   | `/api/connect` | Returns a URL to link social accounts              |
| POST   | `/api/post`    | Uploads the image (if any) and publishes the post  |

`POST /api/post` body:
```json
{
  "caption": "Hello world",
  "platforms": ["twitter", "instagram", "facebook", "linkedin"],
  "imageBase64": "<base64 image, optional>",
  "imageUrl": "<public image url, optional alternative>",
  "profileKey": "<multi-user only, optional>"
}
```

> Endpoint paths follow Ayrshare's current API. If Ayrshare changes a route
> (e.g. media upload), update the URLs in `index.js`.
