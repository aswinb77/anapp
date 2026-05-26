# MovieCC Crawler - Railway Deployment Guide

## Setup Instructions

### 1. **Firebase Configuration**
The crawler needs Firebase credentials to run. You have two options:

**Option A: Local Development (using serviceAccountKey.json)**
- Copy your Firebase service account JSON to: `crawler/serviceAccountKey.json`
- The crawler will automatically load it locally

**Option B: Railway Production (using environment variable)**
- In Railway dashboard, add environment variable: `FIREBASE_SERVICE_ACCOUNT`
- Value: Your entire Firebase service account JSON as a single JSON string
- Example:
  ```
  {"type":"service_account","project_id":"your-project-id",...}
  ```

### 2. **Deploy to Railway**

```bash
# 1. Connect your GitHub repo to Railway
# Go to railway.app → Create Project → GitHub → Select repository

# 2. Railway will automatically:
# - Detect Node.js project
# - Install dependencies from crawler/package.json
# - Run the worker specified in Procfile

# 3. In Railway Dashboard, add environment variables:
FIREBASE_SERVICE_ACCOUNT=<your-service-account-json-here>
TMDB_KEY=<optional-tmdb-api-key>
```

### 3. **Procfile Configuration**

The root `Procfile` contains:
```
worker: cd crawler && node scheduler.js
```

This tells Railway to:
- Start a worker process (runs continuously, not HTTP server)
- Navigate to crawler directory
- Run the scheduler which runs crawlers on a cron schedule

### 4. **Crawler Schedule**

Once running, the scheduler will automatically execute:
- **BookMyShow Crawler**: Every day at 8:00 AM IST (2:30 UTC)
- **OTT Crawler**: Every day at 10:00 AM IST (4:30 UTC)  
- **Wikipedia Crawler**: Every Sunday at 1:00 AM IST (19:30 Sat UTC)
- **IMDb Enrichment**: Every Sunday after Wikipedia

### 5. **Running Locally**

```bash
# Install dependencies
cd crawler
npm install

# Run all crawlers once
npm run crawl

# Run scheduler (with cron jobs)
npm run schedule

# Run individual crawlers
npm run wiki      # Wikipedia only
npm run imdb      # IMDb enrichment
npm run bms       # BookMyShow
npm run ott       # OTT platforms
```

### 6. **Troubleshooting**

**No Firebase connection:**
- Check that `FIREBASE_SERVICE_ACCOUNT` env var is set correctly
- Verify it's valid JSON (use JSONLint to validate)
- Check Firebase project ID matches in credentials

**Crawlers not running on schedule:**
- Check Railway logs for errors
- Verify system time/timezone is correct
- Confirm Firebase database is accessible

**High memory usage:**
- Puppeteer (BookMyShow crawler) is memory-intensive
- Consider reducing batch sizes in crawler code
- Monitor Railway metrics dashboard

### 7. **Next Steps**

1. Add `FIREBASE_SERVICE_ACCOUNT` to Railway environment
2. Connect GitHub repo to Railway
3. Railway will automatically start the worker process
4. Monitor logs in Railway dashboard
5. Verify data is being written to Firestore

## Files Structure

```
crawler/
├── orchestrator.js      # Runs all crawlers sequentially
├── scheduler.js         # Manages cron schedules
├── package.json         # Dependencies
├── crawlers/
│   ├── wikipedia.js     # Scrapes Malayalam films from Wikipedia
│   ├── imdb.js          # Enriches with IMDb data
│   ├── bookmyshow.js    # Tracks theatre listings
│   └── ott.js           # Checks OTT availability
└── lib/
    ├── firebase.js      # Firebase initialization
    ├── delay.js         # Utility functions
    └── merge.js         # Database operations
```

## Environment Variables Reference

| Variable | Required | Example | Notes |
|----------|----------|---------|-------|
| `FIREBASE_SERVICE_ACCOUNT` | Yes (Railway) | `{"type":"service_account",...}` | Firebase credentials as JSON string |
| `TMDB_KEY` | No | `abc123xyz` | Optional: For OTT crawler enhancements |

## Important Notes

- ✅ Procfile is configured to run `scheduler.js` which manages all cron jobs
- ✅ Crawler runs asynchronously with exponential backoff for retries
- ✅ All crawlers merge data into Firestore automatically
- ✅ No manual API required - everything runs on schedule
- ⚠️ Don't commit `serviceAccountKey.json` to GitHub (already in .gitignore)
- ⚠️ Keep `FIREBASE_SERVICE_ACCOUNT` secure in Railway secrets

For more information, visit [Railway.app Documentation](https://docs.railway.app)
