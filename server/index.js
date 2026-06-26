// AutoPost AI — backend
//
// Wraps a unified social-posting API (Ayrshare) so the Flutter app can
// auto-post to X / Instagram / Facebook / LinkedIn from ANY platform
// (including desktop, where the OS share sheet can't reach those apps).
//
// The unified-API key lives ONLY here (server-side) — never in the app.
//
// Endpoints:
//   GET  /health        — liveness check
//   POST /api/connect    — returns a link for the user to connect their accounts
//   POST /api/post       — uploads the image (if any) and publishes the post
//
// Run:  npm install && npm start   (set AYRSHARE_API_KEY in .env first)

import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
// Generated images can be large; allow a generous JSON body.
app.use(express.json({ limit: '25mb' }));
app.use(cors());

const API_URL = process.env.AYRSHARE_API_URL || 'https://app.ayrshare.com/api';
const API_KEY = process.env.AYRSHARE_API_KEY;
const PORT = process.env.PORT || 3000;

// Valid platform keys for the unified API.
const VALID_PLATFORMS = ['twitter', 'instagram', 'facebook', 'linkedin'];

function authHeaders(profileKey) {
  const headers = {
    Authorization: `Bearer ${API_KEY}`,
    'Content-Type': 'application/json',
  };
  // Multi-user (Business plan): each user's accounts live under a profileKey.
  if (profileKey) headers['Profile-Key'] = profileKey;
  return headers;
}

function requireApiKey(res) {
  if (!API_KEY) {
    res.status(500).json({
      error:
        'AYRSHARE_API_KEY is not set. Copy .env.example to .env and add your key.',
    });
    return false;
  }
  return true;
}

app.get('/health', (_req, res) => {
  res.json({ ok: true, configured: Boolean(API_KEY) });
});

// Upload a base64 image to the unified API's media host, returning a public URL.
async function uploadImage(imageBase64, contentType = 'image/jpeg') {
  const resp = await fetch(`${API_URL}/media/upload`, {
    method: 'POST',
    headers: authHeaders(),
    body: JSON.stringify({
      file: imageBase64.startsWith('data:')
        ? imageBase64
        : `data:${contentType};base64,${imageBase64}`,
      fileName: `autopost_${Date.now()}.jpg`,
    }),
  });
  const data = await resp.json();
  if (!resp.ok) {
    throw new Error(data?.message || 'Media upload failed');
  }
  // The API returns the hosted URL under one of these keys depending on version.
  return data.url || data.accessUrl || data.mediaUrl;
}

// POST /api/post
// body: {
//   caption: string,
//   platforms: string[]            // e.g. ["twitter","instagram"]
//   imageBase64?: string,          // raw base64 (no data: prefix needed)
//   imageUrl?: string,             // already-public image URL (alternative)
//   profileKey?: string            // multi-user only
// }
app.post('/api/post', async (req, res) => {
  if (!requireApiKey(res)) return;

  try {
    const { caption, platforms, imageBase64, imageUrl, profileKey } = req.body || {};

    const selected = (platforms || []).filter((p) => VALID_PLATFORMS.includes(p));
    if (selected.length === 0) {
      return res.status(400).json({
        error: `No valid platforms. Use any of: ${VALID_PLATFORMS.join(', ')}`,
      });
    }

    // Resolve media to a public URL the platforms can fetch.
    let mediaUrls;
    if (imageUrl) {
      mediaUrls = [imageUrl];
    } else if (imageBase64) {
      mediaUrls = [await uploadImage(imageBase64)];
    }

    const payload = {
      post: caption || '',
      platforms: selected,
    };
    if (mediaUrls) payload.mediaUrls = mediaUrls;

    const resp = await fetch(`${API_URL}/post`, {
      method: 'POST',
      headers: authHeaders(profileKey),
      body: JSON.stringify(payload),
    });
    const data = await resp.json();

    if (!resp.ok) {
      return res.status(resp.status).json({ error: data?.message || 'Post failed', detail: data });
    }
    return res.json({ ok: true, result: data });
  } catch (err) {
    return res.status(500).json({ error: String(err?.message || err) });
  }
});

// POST /api/connect
// Returns a URL where the user links their social accounts.
// - Business plan: a per-user SSO link (requires AYRSHARE_PRIVATE_KEY + profileKey).
// - Free / single-account: the Ayrshare dashboard.
app.post('/api/connect', async (req, res) => {
  if (!requireApiKey(res)) return;

  const { profileKey } = req.body || {};
  const privateKey = process.env.AYRSHARE_PRIVATE_KEY;

  if (privateKey && profileKey) {
    try {
      const resp = await fetch(`${API_URL}/profiles/generateJWT`, {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify({ privateKey, profileKey }),
      });
      const data = await resp.json();
      if (!resp.ok) {
        return res.status(resp.status).json({ error: data?.message || 'Could not create SSO link' });
      }
      return res.json({ url: data.url, mode: 'sso' });
    } catch (err) {
      return res.status(500).json({ error: String(err?.message || err) });
    }
  }

  // Fallback: link accounts directly in the dashboard (free / single-account).
  return res.json({
    url: 'https://app.ayrshare.com/social-accounts',
    mode: 'dashboard',
    note: 'Log in and connect your social accounts. For per-user linking, set AYRSHARE_PRIVATE_KEY and pass a profileKey.',
  });
});

app.listen(PORT, () => {
  console.log(`AutoPost AI backend listening on :${PORT} (configured=${Boolean(API_KEY)})`);
});
