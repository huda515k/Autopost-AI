# Image Generation Setup Guide

## Free & Open Source Image Generation Options

Your app now supports **3 free image generation services**. You only need **ONE** API key (optional).

### Option 1: Hugging Face (Recommended - Free & Open Source) ⭐

**Best for:** Free tier, open source, easy setup

1. Go to: https://huggingface.co/settings/tokens
2. Create a free account (if you don't have one)
3. Click "New token"
4. Name it (e.g., "autopost_ai")
5. Select "Read" permission
6. Copy the token
7. Paste it in the login screen under "Image Generation API Key"

**Free Tier:** 1000 requests/month

**Model Used:** Stable Diffusion XL

---

### Option 2: Replicate (Free Tier Available)

**Best for:** Easy API, multiple models

1. Go to: https://replicate.com/account/api-tokens
2. Sign up for free account
3. Create an API token
4. Copy the token
5. Paste it in the login screen

**Free Tier:** Limited requests, then pay-as-you-go

**Model Used:** Stable Diffusion

---

### Option 3: Stability AI (Free Tier Available)

**Best for:** High quality images

1. Go to: https://platform.stability.ai/account/keys
2. Sign up for free account
3. Generate API key
4. Copy the key
5. Paste it in the login screen

**Free Tier:** Limited credits per month

**Model Used:** Stable Diffusion XL

---

## How to Use in the App

1. **Login Screen:**
   - Enter your Gemini API key (required)
   - Click "Add Image Generation API Key (Optional)"
   - Enter any one of the above API keys

2. **AI Chat Screen:**
   - Type a description (e.g., "A beautiful sunset over mountains")
   - Click the **purple sparkle icon** (✨) to generate an image
   - Wait for the image to generate (10-30 seconds)
   - Once generated, you can generate a caption for it

3. **Features:**
   - Generate images from text descriptions
   - Upload your own images
   - Generate captions for both AI-generated and uploaded images

---

## Which Service to Choose?

- **Hugging Face:** Best for free tier, completely open source
- **Replicate:** Best for easy setup and multiple model options
- **Stability AI:** Best for highest quality images

**Recommendation:** Start with **Hugging Face** - it's free, open source, and easy to set up!

---

## Troubleshooting

**"Image generation API key not provided"**
- Make sure you added an API key in the login screen
- Check that the key is correct

**"Failed to generate image"**
- Check your internet connection
- Verify your API key is valid
- Some services may have rate limits - wait a few minutes and try again

**"Model is loading" (Hugging Face)**
- Hugging Face models load on first use
- Wait 30-60 seconds and try again
- The model will stay loaded for faster subsequent requests

