# movie.cc

A full-stack Malayalam movie platform built with Flutter, Firebase, and Node.js. The app lets users discover movies, read entertainment news, post in a community feed, and chat in real-time — while a multi-layered backend automatically keeps the data fresh and moderates content.

---

## What makes this different

Most movie apps just call TMDB and display results. This one goes further:

- A custom web crawler scrapes Wikipedia, BookMyShow, and TMDB to build and maintain its own Malayalam-focused movie database in Firestore
- A scheduled news crawler (running every 6 hours) automatically fetches entertainment articles from Onmanorama, Filmibeat, and Cinema Express and posts them to the community feed
- A fake post detection engine analyses every user post for sensational language, unverified claims, and untrusted links — and automatically removes or flags suspicious content
- A user trust/strike system demotes users who repeatedly share misinformation

---

## Architecture overview

```
┌─────────────────────────────────────────────────────────┐
│                   Flutter App (mobile)                  │
│  Discover · Feed · Chat · Favourites · Profile          │
└──────────────────────┬──────────────────────────────────┘
                       │ REST + Firestore listeners
┌──────────────────────▼──────────────────────────────────┐
│           Firebase Cloud Functions (Node.js)            │
│                                                         │
│  API endpoints          Scheduled functions             │
│  ├─ getTrending         ├─ crawlNews (every 6h)         │
│  ├─ getNowPlaying       └─ cleanupOldFeeds (daily)      │
│  ├─ getPopular                                          │
│  ├─ getUpcoming         Firestore triggers              │
│  ├─ getMovie            └─ onPostCreated                │
│  ├─ searchMovies              └─ fake score analysis    │
│  ├─ voteMovie                 └─ user strike system     │
│  └─ getUserStatus                                       │
└──────────────────────┬──────────────────────────────────┘
                       │ Firestore (shared DB)
┌──────────────────────▼──────────────────────────────────┐
│              Crawler Service (Railway)                  │
│                                                         │
│  orchestrator.js — runs crawlers in sequence            │
│  scheduler.js    — cron-based scheduling                │
│                                                         │
│  crawlers/                                              │
│  ├─ wikipedia.js   scrapes Malayalam film lists         │
│  ├─ tmdb.js        enriches posters, ratings, OTT data  │
│  └─ bookmyshow.js  Puppeteer stealth — Kerala theaters  │
│                                                         │
│  Deployed on Railway, auto-restarts on crash            │
└─────────────────────────────────────────────────────────┘
```

---

## Project structure

```
moviecc_flutter/
│
├── lib/                          # Flutter app
│   ├── main.dart                 # Entry point, providers, nav bar
│   ├── models/                   # Movie, Post, Notification models
│   ├── providers/                # State management (Provider pattern)
│   │   ├── user_provider.dart
│   │   ├── feed_provider.dart
│   │   ├── favorites_provider.dart
│   │   ├── chat_provider.dart
│   │   ├── notification_provider.dart
│   │   └── connectivity_provider.dart
│   ├── screens/
│   │   ├── discover_screen.dart  # Movie search + carousels
│   │   ├── feed_screen.dart      # Community posts feed
│   │   ├── chat_screen.dart      # Real-time global chat rooms
│   │   ├── favorites_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── movie_details_screen.dart
│   │   ├── publish_screen.dart   # Create a post
│   │   ├── notifications_screen.dart
│   │   ├── auth_screen.dart      # Login / register
│   │   └── offline_screen.dart   # No internet handler
│   ├── services/
│   │   └── api_service.dart      # Firebase Functions API calls
│   └── widgets/
│       ├── movie_card.dart
│       ├── hero_carousel.dart
│       ├── media_carousel.dart
│       └── marquee_section.dart
│
├── functions/                    # Firebase Cloud Functions (backend server)
│   └── index.js                  # All API endpoints + scheduled jobs
│
├── crawler/                      # Standalone crawler service
│   ├── orchestrator.js           # Runs all crawlers in sequence
│   ├── scheduler.js              # Cron scheduling per crawler
│   ├── cron.js                   # Runs orchestrator every hour
│   ├── crawlers/
│   │   ├── wikipedia.js          # Scrapes Wikipedia film tables (cheerio)
│   │   ├── tmdb.js               # TMDB metadata + OTT enrichment
│   │   └── bookmyshow.js         # Puppeteer stealth — live theater data
│   └── lib/
│       ├── firebase.js           # Firestore connection (env-aware)
│       ├── merge.js              # Safe batch upsert helpers
│       └── delay.js              # Random delay between requests
│
├── seed.js                       # One-time Firestore seed from TMDB
├── firestore.rules               # Field-level security rules
├── Procfile                      # Railway process config
└── railway.json                  # Railway deployment config
```

---

## Tech stack

| Component | Technology |
|---|---|
| Mobile app | Flutter 3.x, Dart |
| State management | Provider |
| Auth | Firebase Auth (email/password + Google Sign-In) |
| Database | Cloud Firestore |
| Backend API | Firebase Cloud Functions v2 (Node.js) |
| Crawlers | Node.js, Axios, Cheerio, Puppeteer + Stealth plugin |
| Crawler deployment | Railway (auto-restart cron worker) |
| Trailer playback | youtube_player_iframe |
| Animations | flutter_animate, shimmer |
| ML | Google ML Kit Text Recognition |

---

## Backend systems in detail

### 1. REST API (Firebase Cloud Functions)

All movie data is served through Cloud Functions deployed in `asia-south1` (low latency for Indian users):

| Endpoint | Description |
|---|---|
| `GET /getTrending` | Movies sorted by `total_score` desc |
| `GET /getNowPlaying` | Movies where `in_theaters == true` |
| `GET /getPopular` | Top 20 by popularity score |
| `GET /getUpcoming` | Movies with future release dates |
| `GET /getMovie?id=` | Full details + TMDB credits/trailers |
| `GET /searchMovies?q=` | Firestore prefix search on `title_lower` |
| `POST /voteMovie` | Increments `user_votes` and `total_score` by 50 |
| `GET /getUserStatus?uid=` | Returns trust score, strike count, can_post flag |

### 2. Crawler service (deployed on Railway)

Three crawlers run on a cron schedule and write to the same Firestore database:

**Wikipedia crawler** (`crawlers/wikipedia.js`)
- Scrapes `List_of_Malayalam_films_of_{year}` pages for 2020–2025
- Uses Cheerio to parse wikitable rows and extract film titles and years
- Batch-upserts into Firestore with deduplication by `title_lower`

**TMDB enricher** (`crawlers/tmdb.js`)
- Runs after Wikipedia so it can enrich existing records
- Searches TMDB by title + year, falls back to title-only search
- Fetches poster, backdrop, vote_average, OTT availability, in-theaters status
- Calculates `total_score` = popularity + (user_votes × 50) + 300 if in theaters

**BookMyShow scraper** (`crawlers/bookmyshow.js`)
- Uses Puppeteer with the Stealth plugin to avoid bot detection
- Checks 4 Kerala cities: Kochi, Thiruvananthapuram, Kottayam, Kozhikode
- Cross-references scraped titles against Firestore to mark movies as `in_theaters: true`
- Updates `theatres` array and boosts `total_score` for currently showing films

**Cron schedule:**
- BookMyShow: every day at 8:00 AM IST
- OTT check: every day at 10:00 AM IST
- Wikipedia + TMDB enrich: every Sunday at 1:00 AM IST

### 3. Auto news crawler (Cloud Function, every 6 hours)

Crawls entertainment news from three Malayalam film sources:
- Onmanorama Entertainment
- Filmibeat Malayalam
- Cinema Express Malayalam

For each source it fetches article links, extracts title, summary, and image, deduplicates by URL hash, and posts to the `news_posts` Firestore collection automatically.

### 4. Fake post detection engine (Cloud Function trigger)

Fires automatically when any user creates a post (`onPostCreated` Firestore trigger).

Scoring signals:
- **Link analysis** — checks URLs against a trusted domain list (Onmanorama, Mathrubhumi, The Hindu, NDTV, etc.)
- **Sensational language** — regex patterns for BREAKING, SHOCKING, "share before delete", Malayalam fake news phrases
- **News cross-reference** — checks if the claim matches any recently crawled verified news titles
- **User trust multiplier** — users with low trust scores have their fake score amplified

Outcomes:
- Score ≥ 70 → post removed, user gets a strike
- Score 40–69 → post marked `under_review`
- Score < 40 → post visible

### 5. User strike system

Users who repeatedly post flagged content receive:
- Strike 1: warning notification
- Strike 2: serious warning, one more removal = suspension
- Strike 3: posting privilege suspended
- Strike 5+: account restricted

User trust scores (0–100) are maintained separately and affect future fake score calculations.

---

## Getting started

### Flutter app

```bash
git clone https://github.com/aswinb77/anapp.git
cd anapp

# Connect Firebase
dart pub global activate flutterfire_cli
flutterfire configure

# Add your config files
# android/app/google-services.json
# ios/Runner/GoogleService-Info.plist
# See CREDENTIALS_SETUP.md for details

flutter pub get
flutter run
```

### Firebase Functions

```bash
cd functions
npm install

# Set your TMDB key as a Firebase secret
firebase functions:secrets:set TMDB_KEY

# Deploy
firebase deploy --only functions
```

### Crawler (local)

```bash
cd crawler
npm install

# Create .env with:
# TMDB_KEY=your_tmdb_api_key
# FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}  ← paste JSON string

# Run all crawlers once
node orchestrator.js

# Run a specific crawler only
node orchestrator.js --only=wikipedia
node orchestrator.js --only=tmdb

# Start the cron scheduler
node scheduler.js
```

### Seed Firestore from scratch

```bash
# At project root
cp serviceAccountKey.json.example serviceAccountKey.json  # fill in your values
TMDB_KEY=your_key node seed.js
```

---

## Environment variables

| Variable | Used in | Description |
|---|---|---|
| `TMDB_KEY` | Crawler + Functions | TMDB API key |
| `FIREBASE_SERVICE_ACCOUNT` | Crawler (Railway) | Full service account JSON as string |

Never commit `serviceAccountKey.json`, `.env`, or `firebase_options.dart` — all are in `.gitignore`.

---

## Firestore security

Field-level rules prevent client-side abuse:
- Users cannot modify their own `trust_score`, `strike_count`, or `restricted` fields
- Posts cannot have `status`, `fake_score`, or `reviewed_by` changed by clients — only Cloud Functions
- Notifications can only be read and marked-as-read by their owner
- Movies and news posts are read-only from the client

---

## Deployment

| Service | Platform | Config |
|---|---|---|
| Mobile app | Android / iOS | `flutter build apk --release` |
| Backend API | Firebase Cloud Functions | `firebase deploy --only functions` |
| Crawler worker | Railway | `railway.json` + `Procfile` — auto-restarts |

---

## What I built and learned

- Designing a multi-source data pipeline: Wikipedia → TMDB → BookMyShow → Firestore, with each crawler enriching the same documents
- Stealth web scraping with Puppeteer and anti-bot plugins for live theater data
- Writing a fake post detection system using heuristics, domain trust, news cross-referencing, and per-user trust scoring — entirely serverless in Cloud Functions
- Field-level Firestore security rules that block client-side tampering of moderation data
- Structuring a mid-size Flutter app with Provider across interconnected async state (auth, connectivity, chat, notifications)
- Deploying a persistent Node.js cron worker on Railway alongside Firebase Functions

---

## License

Personal and educational use.
