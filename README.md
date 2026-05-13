# TubeMax

A Netflix-style YouTube player built for Roku sideloading and web. Clean dark UI, Google OAuth, real YouTube Data API v3 integration.

## Features

- Netflix-inspired dark UI with full-bleed hero, portrait cards, horizontal rows
- Google OAuth 2.0 sign-in — loads real subscriptions, liked videos, personalized feed
- Guest mode — browse trending, search, all public content
- 8 screens: Home, Trending, Watchlist, Subscriptions, History, Video Detail, Search, Player
- Persistent sidebar navigation
- Live YouTube thumbnails everywhere including hero

## Setup

### 1. YouTube API Key
Get a free key from [Google Cloud Console](https://console.cloud.google.com):
- Enable YouTube Data API v3
- Create an API key credential
- Paste into the app or it's pre-configured

### 2. Google OAuth (for sign-in)
- Create an OAuth 2.0 Client ID (Web application)
- Add your Netlify domain to Authorized redirect URIs
- Replace `GOOGLE_CLIENT_ID` in `index.html`

### 3. Deploy
Push to GitHub → connect to Netlify → auto-deploys on every push.

After deploying, add your Netlify URL to:
- Google Cloud Console → OAuth Client → Authorized redirect URIs
- Example: `https://tubemax.netlify.app`

## Roku Sideload

The `/roku` folder contains the BrightScript app for sideloading directly to a Roku device.

See [Roku Developer Docs](https://developer.roku.com/docs/developer-program/getting-started/developer-setup.md) for sideload instructions.

## Stack

- Vanilla HTML/CSS/JS — no framework, no build step
- YouTube Data API v3
- Google OAuth 2.0 (implicit flow)
- Netlify hosting
- BrightScript + SceneGraph for Roku

## Built by

[Revuity Systems](https://revuitysystems.com) — AI-first software studio.
