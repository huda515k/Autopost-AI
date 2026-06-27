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

app.get('/', (_req, res) => {
  res.json({
    service: 'AutoPost AI backend',
    status: 'running',
    endpoints: ['/health', '/api/post', '/api/connect'],
  });
});

app.get('/health', (_req, res) => {
  res.json({ ok: true, configured: Boolean(API_KEY) });
});

// Host a base64 image on imgbb (free) and return its public URL.
//
// The platforms (esp. Instagram) need a publicly-reachable image URL. Ayrshare's
// own media upload is a paid feature, so we host on imgbb instead — free, and
// works on Ayrshare's free Basic plan.
async function uploadImage(imageBase64) {
  const key = process.env.IMGBB_API_KEY;
  if (!key) {
    throw new Error(
      'IMGBB_API_KEY is not set. Add a free key from https://api.imgbb.com/ to host images.',
    );
  }
  // imgbb wants raw base64 (strip any "data:image/...;base64," prefix).
  const raw = imageBase64.includes(',') ? imageBase64.split(',').pop() : imageBase64;

  const body = new URLSearchParams();
  body.set('image', raw);

  const resp = await fetch(`https://api.imgbb.com/1/upload?key=${key}`, {
    method: 'POST',
    body,
  });
  const data = await resp.json();
  if (!resp.ok || !data?.data?.url) {
    throw new Error(data?.error?.message || 'Image hosting (imgbb) failed');
  }
  return data.data.url;
}

// --- Direct LinkedIn posting (free, official) ---
// Bypasses Ayrshare for LinkedIn so it doesn't consume the Ayrshare quota.
// Requires a member access token (scope w_member_social) + the author URN.
function linkedinConfigured() {
  return Boolean(process.env.LINKEDIN_ACCESS_TOKEN && process.env.LINKEDIN_AUTHOR_URN);
}

async function postToLinkedIn({ caption, imageBase64, imageUrl }) {
  const token = process.env.LINKEDIN_ACCESS_TOKEN;
  const author = process.env.LINKEDIN_AUTHOR_URN; // e.g. urn:li:person:XXXX
  const headers = {
    Authorization: `Bearer ${token}`,
    'X-Restli-Protocol-Version': '2.0.0',
    'Content-Type': 'application/json',
  };

  // Resolve image bytes (LinkedIn needs the raw image, not a URL).
  let imgBuffer = null;
  if (imageBase64) {
    const raw = imageBase64.includes(',') ? imageBase64.split(',').pop() : imageBase64;
    imgBuffer = Buffer.from(raw, 'base64');
  } else if (imageUrl) {
    const r = await fetch(imageUrl);
    imgBuffer = Buffer.from(await r.arrayBuffer());
  }

  let mediaAsset = null;
  if (imgBuffer) {
    // 1) Register the upload.
    const reg = await fetch('https://api.linkedin.com/v2/assets?action=registerUpload', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        registerUploadRequest: {
          recipes: ['urn:li:digitalmediaRecipe:feedshare-image'],
          owner: author,
          serviceRelationships: [
            { relationshipType: 'OWNER', identifier: 'urn:li:userGeneratedContent' },
          ],
        },
      }),
    });
    const regData = await reg.json();
    if (!reg.ok) throw new Error(regData?.message || 'LinkedIn registerUpload failed');
    const uploadUrl =
      regData.value.uploadMechanism[
        'com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest'
      ].uploadUrl;
    mediaAsset = regData.value.asset;

    // 2) Upload the image bytes.
    const up = await fetch(uploadUrl, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: imgBuffer,
    });
    if (!up.ok) throw new Error(`LinkedIn image upload failed (${up.status})`);
  }

  // 3) Create the post.
  const shareContent = {
    shareCommentary: { text: caption || '' },
    shareMediaCategory: mediaAsset ? 'IMAGE' : 'NONE',
  };
  if (mediaAsset) {
    shareContent.media = [{ status: 'READY', media: mediaAsset, title: { text: 'Image' } }];
  }
  const postResp = await fetch('https://api.linkedin.com/v2/ugcPosts', {
    method: 'POST',
    headers,
    body: JSON.stringify({
      author,
      lifecycleState: 'PUBLISHED',
      specificContent: { 'com.linkedin.ugc.ShareContent': shareContent },
      visibility: { 'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC' },
    }),
  });
  const postData = await postResp.json().catch(() => ({}));
  if (!postResp.ok) throw new Error(postData?.message || `LinkedIn post failed (${postResp.status})`);
  const id = postResp.headers.get('x-restli-id') || postData.id;
  return {
    status: 'success',
    platform: 'linkedin',
    id,
    postUrl: id ? `https://www.linkedin.com/feed/update/${id}` : undefined,
  };
}

// POST /api/post
// body: {
//   caption: string,
//   platforms: string[]            // e.g. ["twitter","instagram"]
//   imageBase64?: string,          // raw base64 (no data: prefix needed)
//   imageUrl?: string,             // already-public image URL (alternative)
//   scheduleDate?: string,         // ISO 8601 UTC — Ayrshare publishes at this time
//   profileKey?: string            // multi-user only
// }
// LinkedIn is routed to the free direct API when configured; other platforms go via Ayrshare.
app.post('/api/post', async (req, res) => {
  if (!requireApiKey(res)) return;

  try {
    const { caption, platforms, imageBase64, imageUrl, scheduleDate, profileKey } =
      req.body || {};

    const selected = (platforms || []).filter((p) => VALID_PLATFORMS.includes(p));
    if (selected.length === 0) {
      return res.status(400).json({
        error: `No valid platforms. Use any of: ${VALID_PLATFORMS.join(', ')}`,
      });
    }

    // Route LinkedIn to the free direct API when configured; the rest via Ayrshare.
    const useLinkedInDirect = selected.includes('linkedin') && linkedinConfigured();
    const ayrsharePlatforms = useLinkedInDirect
        ? selected.filter((p) => p !== 'linkedin')
        : selected;

    const postIds = [];
    const errors = [];

    // LinkedIn — direct, free, off the Ayrshare quota.
    if (useLinkedInDirect) {
      try {
        postIds.push(await postToLinkedIn({ caption, imageBase64, imageUrl }));
      } catch (e) {
        errors.push({ platform: 'linkedin', error: String(e?.message || e) });
      }
    }

    // Remaining platforms via Ayrshare.
    if (ayrsharePlatforms.length > 0) {
      let mediaUrls;
      if (imageUrl) {
        mediaUrls = [imageUrl];
      } else if (imageBase64) {
        mediaUrls = [await uploadImage(imageBase64)];
      }

      const payload = { post: caption || '', platforms: ayrsharePlatforms };
      if (mediaUrls) payload.mediaUrls = mediaUrls;
      if (scheduleDate) payload.scheduleDate = scheduleDate;

      const resp = await fetch(`${API_URL}/post`, {
        method: 'POST',
        headers: authHeaders(profileKey),
        body: JSON.stringify(payload),
      });
      const data = await resp.json();
      if (!resp.ok) {
        errors.push({ platform: ayrsharePlatforms.join(','), error: data?.message || 'Post failed', detail: data });
      } else if (Array.isArray(data.postIds)) {
        postIds.push(...data.postIds);
      } else {
        postIds.push({ status: 'success', ayrshare: data });
      }
    }

    // All targets failed → surface the error.
    if (postIds.length === 0 && errors.length > 0) {
      return res.status(502).json({
        error: errors.map((e) => `${e.platform}: ${e.error}`).join('; '),
        detail: errors,
      });
    }
    return res.json({ ok: true, result: { postIds, errors } });
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
