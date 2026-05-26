const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const cheerio = require("cheerio");
const crypto = require("crypto");
admin.initializeApp();
const db = admin.firestore();
// Reference to the secret you created with firebase functions:secrets:set
const TMDB_KEY = defineSecret("TMDB_KEY");
// Helper: build full poster URL from Firestore path
function posterUrl(path) {
  if (!path) return null;
  if (path.startsWith("http")) return path;
  return `https://image.tmdb.org/t/p/w500${path}`;
}
// Helper: format a movie doc for the API response
function formatMovie(doc) {
  const d = doc.data();
  return {
    id: doc.id,
    tmdb_id: d.tmdb_id || null,
    title: d.title,
    original_title: d.original_title || d.title,
    overview: d.overview || d.plot || "",
    poster_url: posterUrl(d.poster_path || d.image),
    backdrop_url: d.backdrop_path ?
      `https://image.tmdb.org/t/p/w1280${d.backdrop_path}` :
      (d.image || null),
    popularity: d.popularity || d.rating || 0,
    vote_average: d.vote_average || d.rating || 0,
    release_date: d.release_date || `${d.year}-01-01`,
    language: d.language || "ml",
    genre_ids: d.genre_ids || [],
    theatres: d.theatres || [],
    ott: d.ott || {},
    user_votes: d.user_votes || 0,
    total_score: d.total_score || 0,
  };
}
// ■■ CORS helper

function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
}

// GET TRENDING
// Returns movies sorted by total_score descending
exports.getTrending = onRequest(
    {secrets: [TMDB_KEY], region: "asia-south1", invoker: "public"},
    async (req, res) => {
      setCors(res);
      const lang = req.query.lang || "ml";
      let movies = [];
      try {
        const snap = await db
            .collection("movies")
            .where("language", "==", lang)
            .orderBy("total_score", "desc")
            .limit(20)
            .get();
        movies = snap.docs.map(formatMovie);
      } catch (err) {
        console.error(
            "getTrending failed, falling back to in-memory filter",
            err,
        );
        const snap = await db
            .collection("movies")
            .orderBy("total_score", "desc")
            .limit(100)
            .get();
        movies = snap.docs.map(formatMovie)
            .filter((movie) => movie.language === lang)
            .slice(0, 20);
      }
      res.json({results: movies});
    },
);

// get current now playing
exports.getNowPlaying = onRequest(
    {secrets: [TMDB_KEY], region: "asia-south1", invoker: "public"},
    async (req, res) => {
      setCors(res);
      const lang = req.query.lang || "ml";
      try {
        // We now rely purely on the `in_theaters` flag
        // updated by BookMyShow and TMDB crawlers
        const snap = await db
            .collection("movies")
            .where("language", "==", lang)
            .where("in_theaters", "==", true)
            .orderBy("total_score", "desc")
            .limit(20)
            .get();
        return res.json({results: snap.docs.map(formatMovie)});
      } catch (err) {
        console.error(
            "getNowPlaying failed, falling back to all movies",
            err,
        );
        const snap = await db
            .collection("movies")
            .where("language", "==", lang)
            .orderBy("total_score", "desc")
            .limit(20)
            .get();
        return res.json({results: snap.docs.map(formatMovie)});
      }
    },
);

// get upcoming movies
exports.getUpcoming = onRequest(
    {secrets: [TMDB_KEY], region: "asia-south1", invoker: "public"},
    async (req, res) => {
      setCors(res);
      const lang = req.query.lang || "ml";
      const today = new Date().toISOString().split("T")[0];
      const snap = await db
          .collection("movies")
          .where("language", "==", lang)
          .where("release_date", ">=", today)
          .orderBy("release_date", "asc")
          .limit(20)
          .get();
      res.json({results: snap.docs.map(formatMovie)});
    },
);

// get popular movies
exports.getPopular = onRequest(
    {secrets: [TMDB_KEY], region: "asia-south1", invoker: "public"},
    async (req, res) => {
      setCors(res);
      const lang = req.query.lang || "ml";
      let movies = [];
      try {
        const snap = await db
            .collection("movies")
            .where("language", "==", lang)
            .orderBy("total_score", "desc")
            .limit(20)
            .get();
        movies = snap.docs.map(formatMovie);
      } catch (err) {
        console.error(
            "getPopular failed, falling back to in-memory filter",
            err,
        );
        const snap = await db
            .collection("movies")
            .orderBy("total_score", "desc")
            .limit(100)
            .get();
        movies = snap.docs.map(formatMovie)
            .filter((movie) => movie.language === lang)
            .slice(0, 20);
      }
      res.json({results: movies});
    },
);

// VOTE MOVIE endpoint
exports.voteMovie = onRequest(
    {region: "asia-south1", invoker: "public"},
    async (req, res) => {
      setCors(res);
      if (req.method === "OPTIONS") {
        return res.status(204).send("");
      }
      if (req.method !== "POST") {
        return res.status(405).json({error: "Method not allowed, use POST"});
      }
      const id = req.body.id || req.query.id;
      if (!id) return res.status(400).json({error: "id param required"});
      try {
        const docRef = db.collection("movies").doc(String(id));
        await docRef.update({
          user_votes: admin.firestore.FieldValue.increment(1),
          total_score: admin.firestore.FieldValue.increment(50),
        });
        res.json({success: true});
      } catch (e) {
        res.status(500).json({error: e.message});
      }
    },
);

// get movies
exports.getMovie = onRequest(
    {secrets: [TMDB_KEY], region: "asia-south1", invoker: "public"},
    async (req, res) => {
      setCors(res);
      const id = req.query.id;
      if (!id) return res.status(400).json({error: "id param required"});
      // Try Firestore first
      const doc = await db.collection("movies").doc(String(id)).get();
      if (doc.exists) {
      // Also fetch extra details from TMDB for credits/videos
        try {
          const tmdbId = doc.data().tmdb_id || id;
          const {data} = await axios.get(
              `https://api.themoviedb.org/3/movie/${tmdbId}`,
              {
                params: {
                  api_key: TMDB_KEY.value(),
                  append_to_response: "credits,videos,watch/providers",
                },
              },
          );
          return res.json({...formatMovie(doc), details: data});
        } catch (e) {
          return res.json(formatMovie(doc));
        }
      }
      // Not in Firestore — fetch from TMDB directly
      const {data} = await axios.get(
          `https://api.themoviedb.org/3/movie/${id}`,
          {
            params: {
              api_key: TMDB_KEY.value(),
              append_to_response: "credits,videos,watch/providers",
            },
          },
      );
      res.json(data);
    },
);

// get serch movies

exports.searchMovies = onRequest(
    {secrets: [TMDB_KEY], region: "asia-south1", invoker: "public"},
    async (req, res) => {
      setCors(res);
      const q = (req.query.q || "").toLowerCase().trim();
      if (!q) return res.json({results: []});
      const snap = await db
          .collection("movies")
          .orderBy("title_lower")
          .startAt(q)
          .endAt(q + "\uf8ff")
          .limit(15)
          .get();
      res.json({results: snap.docs.map(formatMovie)});
    },
);

// weekly sync - DISABLED because crawlers are now the source of truth
// exports.weeklySync = onSchedule( ... );

// ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
// SYSTEM 1 — AUTO NEWS CRAWLER
// ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

const NEWS_SOURCES = [
  {
    name: "Onmanorama",
    url: "https://www.onmanorama.com/entertainment.html",
    articleLinkSelector: "a[href*=\"/entertainment/\"]",
    titleSelector: "h1.article-title, h1.story-title, h1",
    summarySelector: "p.article-summary, .story-intro p, article p",
    imageSelector: "meta[property=\"og:image\"]",
    baseUrl: "https://www.onmanorama.com",
  },
  {
    name: "Filmibeat Malayalam",
    url: "https://malayalam.filmibeat.com/malayalam-movies/",
    articleLinkSelector: "h2 a, .story-title a, .news-title a",
    titleSelector: "h1.story-title, h1",
    summarySelector: "div.story-content p, .article-body p",
    imageSelector: "meta[property=\"og:image\"]",
    baseUrl: "https://malayalam.filmibeat.com",
  },
  {
    name: "Cinema Express",
    url: "https://www.cinemaexpress.com/malayalam",
    articleLinkSelector: "a[href*=\"/malayalam/\"]",
    titleSelector: "h1.article-heading, h1",
    summarySelector: ".article-body p, .story-body p",
    imageSelector: "meta[property=\"og:image\"]",
    baseUrl: "https://www.cinemaexpress.com",
  },
];

const NEWS_HEADERS = {
  "User-Agent": "Mozilla/5.0 (compatible; MovieCC-NewsBot/1.0; +https://github.com/YOUR_USERNAME/moviecc)",
  "Accept": "text/html",
  "Accept-Language": "ml,en;q=0.9",
};

function urlHash(url) {
  return crypto.createHash("sha256").update(url).digest("hex").substring(0, 20);
}

async function fetchArticleLinks(source, maxLinks = 5) {
  try {
    const {data: html} = await axios.get(source.url, {
      headers: NEWS_HEADERS, timeout: 15000,
    });
    const $ = cheerio.load(html);
    const links = new Set();
    $(source.articleLinkSelector).each((_, el) => {
      let href = $(el).attr("href") || "";
      if (!href) return;
      if (href.startsWith("/")) href = source.baseUrl + href;
      if (href.startsWith("http") && !href.includes("?")) links.add(href);
    });
    return [...links].slice(0, maxLinks);
  } catch (err) {
    console.warn(`fetchArticleLinks failed for ${source.name}: ${err.message}`);
    return [];
  }
}

async function fetchArticleContent(source, articleUrl) {
  try {
    const {data: html} = await axios.get(articleUrl, {
      headers: NEWS_HEADERS, timeout: 15000,
    });
    const $ = cheerio.load(html);
    const title = $(source.titleSelector).first().text().trim();
    if (!title || title.length < 5) return null;

    const paragraphs = [];
    $(source.summarySelector).each((i, el) => {
      if (i >= 3) return false;
      const text = $(el).text().trim();
      if (text.length > 20) paragraphs.push(text);
    });

    const imageUrl = $(source.imageSelector).attr("content") || null;
    return {
      title,
      body: paragraphs.join(" "),
      image_url: imageUrl,
      source_url: articleUrl,
    };
  } catch (err) {
    console.warn(`fetchArticleContent failed: ${err.message}`);
    return null;
  }
}

exports.crawlNews = onSchedule(
    {schedule: "0 */6 * * *", region: "asia-south1"},
    async () => {
      console.log("[crawlNews] Starting news crawl...");
      let totalPosted = 0;

      for (const source of NEWS_SOURCES) {
        console.log(`Processing source: ${source.name}`);
        const links = await fetchArticleLinks(source, 5);
        console.log(`Found ${links.length} article links`);

        for (const articleUrl of links) {
          const hash = urlHash(articleUrl);
          const existing = await db.collection("news_posts").doc(hash).get();
          if (existing.exists) {
            console.log(`Already posted: ${articleUrl.substring(0, 60)}`);
            continue;
          }

          const content = await fetchArticleContent(source, articleUrl);
          if (!content || !content.title) continue;

          await new Promise((r) => setTimeout(r, 1500));

          await db.collection("news_posts").doc(hash).set({
            title: content.title,
            body: content.body,
            source_name: source.name,
            source_url: content.source_url,
            image_url: content.image_url,
            category: "news",
            verified: true,
            posted_by: "system",
            language: "ml",
            article_hash: hash,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
          });

          console.log(`Posted: ${content.title.substring(0, 50)}`);
          totalPosted++;
        }
        await new Promise((r) => setTimeout(r, 3000));
      }
      console.log(`[crawlNews] Done. Posted ${totalPosted} new articles.`);
    },
);

// ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
// SYSTEM 2 — FAKE POST DETECTION ENGINE
// ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

const TRUSTED_DOMAINS = [
  "onmanorama.com", "mathrubhumi.com", "manoramaonline.com",
  "filmibeat.com", "cinemaexpress.com", "thehindu.com",
  "ndtv.com", "indiatoday.in", "hindustantimes.com",
  "timesofindia.com", "deccanherald.com", "newsminute.com",
];

const FAKE_PATTERNS = [
  /BREAKING/i, /SHOCKING/i, /EXCLUSIVE/i, /VIRAL/i,
  /share before delete/i, /share before removed/i,
  /100% confirmed/i, /you won't believe/i,
  /big news/i, /huge news/i, /exposed/i, /leaked/i,
  /secret revealed/i, /insider source/i,
  /shock ayi/i, /viral aakuka/i, /share cheyyuka/i,
  /ellavarum share/i, /confirm ayi/i,
];

function extractUrls(text) {
  const urlRegex = /https?:\/\/[^\s]+/g;
  return text.match(urlRegex) || [];
}

function isTrustedUrl(url) {
  try {
    const hostname = new URL(url).hostname.replace("www.", "");
    return TRUSTED_DOMAINS.some((d) => hostname.includes(d));
  } catch (e) {
    return false;
  }
}

function scoreLinks(text) {
  const urls = extractUrls(text);
  const signals = [];
  let score = 0;

  if (urls.length === 0) {
    const claimWords = /announced|confirmed|revealed|breaking|exclusive/i;
    if (claimWords.test(text)) {
      score += 20;
      signals.push("claim_without_source");
    }
  }

  for (const url of urls) {
    if (isTrustedUrl(url)) {
      score -= 15;
      signals.push("trusted_source");
    } else {
      score += 30;
      signals.push("unverified_link");
    }
  }

  return {score: Math.max(0, score), signals};
}

function scoreSensational(text) {
  const matches = FAKE_PATTERNS.filter((p) => p.test(text));
  const signals = [];
  let score = 0;
  if (matches.length === 1) {
    score = 15; signals.push("sensational_language");
  }
  if (matches.length >= 2) {
    score = 25; signals.push("highly_sensational");
  }
  return {score, signals};
}

async function scoreNewsCheck(text) {
  const signals = [];
  let score = 0;

  const words = text.toLowerCase()
      .split(/\s+/)
      .filter((w) => w.length > 4)
      .slice(0, 5);

  if (words.length === 0) return {score: 0, signals: []};

  const recentNews = await db.collection("news_posts")
      .orderBy("created_at", "desc")
      .limit(100)
      .get();

  const newsTitles = recentNews.docs.map((d) =>
    (d.data().title || "").toLowerCase(),
  );
  const found = words.some((word) =>
    newsTitles.some((title) => title.includes(word)),
  );

  if (found) {
    score -= 20;
    signals.push("matches_verified_news");
  } else {
    const claimWords = /announced|confirmed|revealed|retired|died|arrested/i;
    if (claimWords.test(text)) {
      score += 35;
      signals.push("unverified_claim");
    }
  }

  return {score: Math.max(0, score), signals};
}

async function calculateFakeScore(text, uid) {
  const linkResult = scoreLinks(text);
  const sensResult = scoreSensational(text);
  const newsResult = await scoreNewsCheck(text);

  const userDoc = await db.collection("users").doc(uid).get();
  const trustScore = userDoc.exists ?
    (userDoc.data().trust_score !== undefined ?
      userDoc.data().trust_score : 100) : 60;

  let multiplier = 1.0;
  if (trustScore < 50) multiplier = 1.3;
  if (trustScore > 90) multiplier = 0.8;

  const rawScore = linkResult.score + sensResult.score + newsResult.score;
  const finalScore = Math.min(100, Math.round(rawScore * multiplier));

  const allSignals = [
    ...linkResult.signals,
    ...sensResult.signals,
    ...newsResult.signals,
  ];

  return {score: finalScore, signals: allSignals, trustScore};
}

exports.onPostCreated = onDocumentCreated(
    {document: "posts/{postId}", region: "asia-south1"},
    async (event) => {
      const postId = event.params.postId;
      const postData = event.data.data();
      if (!postData) return;
      const text = postData.text || postData.content || postData.body || "";
      const uid = postData.userId || postData.uid ||
        postData.authorId || postData.user_id;

      if (!text || !uid) return;
      if (postData.posted_by === "system") return; // skip auto news posts

      console.log(`[FakeDetector] Analysing post ${postId} by user ${uid}`);

      const {score, signals} = await calculateFakeScore(text, uid);
      console.log(`Score: ${score}, Signals: ${signals.join(", ")}`);

      const postRef = db.collection("posts").doc(postId);

      if (score >= 70) {
        await postRef.update({
          fake_score: score,
          fake_signals: signals,
          status: "removed",
          reviewed_by: "system",
          reviewed_at: admin.firestore.FieldValue.serverTimestamp(),
          removal_reason: `Fake score ${score}/100: ${signals.join(", ")}`,
        });
        await moderateUser(uid, postId, text, score, signals);
      } else if (score >= 40) {
        await postRef.update({
          fake_score: score,
          fake_signals: signals,
          status: "under_review",
        });
      } else {
        await postRef.update({
          fake_score: score,
          fake_signals: signals,
          status: "visible",
        });
      }
    },
);

// ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
// SYSTEM 3 — USER MODERATION & STRIKE SYSTEM
// ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

const WARNING_MESSAGES = {
  1: {
    title: "Your post was removed",
    message: "Your recent post was removed — it was flagged as potentially " +
      "misleading. Please verify news before sharing. " +
      "This is your first warning.",
    severity: "warning",
  },
  2: {
    title: "Second warning — posting at risk",
    message: "This is your second warning. Another post was removed for " +
      "unverified content. One more removal will suspend your posting " +
      "privilege.",
    severity: "serious",
  },
  3: {
    title: "Posting privilege suspended",
    message: "Your posting privilege has been suspended due to repeated " +
      "sharing of unverified content. You can still view and use other " +
      "features.",
    severity: "ban",
  },
  5: {
    title: "Account restricted",
    message: "Your account has been restricted for continued guideline " +
      "violations. Please contact support to appeal.",
    severity: "restricted",
  },
};

async function moderateUser(uid, postId, postText, fakeScore, signals) {
  const userRef = db.collection("users").doc(uid);
  const userDoc = await userRef.get();
  if (!userDoc.exists) return;

  const userData = userDoc.data();
  const currentStrikes = (userData.strike_count || 0) + 1;
  const currentTrust = userData.trust_score || 100;

  const trustReduction = Math.min(20, fakeScore / 5);
  const newTrust = Math.max(0, currentTrust - trustReduction);

  let canPost = userData.can_post !== false;
  let restricted = userData.restricted || false;
  let action = "warned";

  if (currentStrikes >= 5) {
    restricted = true;
    canPost = false;
    action = "restricted";
  } else if (currentStrikes >= 3) {
    canPost = false;
    action = "posting_banned";
  }

  await userRef.update({
    strike_count: currentStrikes,
    trust_score: newTrust,
    can_post: canPost,
    restricted: restricted,
    last_strike_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  await db.collection("user_strikes").add({
    uid,
    post_id: postId,
    post_text: postText.substring(0, 200),
    fake_score: fakeScore,
    fake_signals: signals,
    action_taken: action,
    strike_number: currentStrikes,
    warning_sent: false,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  const msgKey = WARNING_MESSAGES[currentStrikes] ? currentStrikes :
    currentStrikes >= 5 ? 5 : 3;
  const msgData = WARNING_MESSAGES[msgKey] || WARNING_MESSAGES[3];

  await db.collection("users").doc(uid)
      .collection("notifications").add({
        type: "moderation_warning",
        title: msgData.title,
        message: msgData.message,
        severity: msgData.severity,
        post_id: postId,
        read: false,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

  console.log(`[Moderation] User ${uid}: strike ` +
    `${currentStrikes}, action: ${action}`);
}

exports.getUserStatus = onRequest(
    {region: "asia-south1"},
    async (req, res) => {
      setCors(res);
      const uid = req.query.uid;
      if (!uid) return res.status(400).json({error: "uid required"});

      const doc = await db.collection("users").doc(uid).get();
      if (!doc.exists) return res.json({can_post: true, restricted: false});

      const data = doc.data();
      res.json({
        can_post: data.can_post !== false,
        restricted: data.restricted || false,
        strike_count: data.strike_count || 0,
        trust_score: data.trust_score || 100,
      });
    },
);

// ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
// SYSTEM 4 — FEED CLEANUP
// ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

exports.cleanupOldFeeds = onSchedule(
    {schedule: "0 0 * * *", region: "asia-south1"},
    async (event) => {
      console.log("[Cleanup] Starting daily feed cleanup...");

      const collections = [
        {name: "posts", orderBy: "createdAt"},
        {name: "news_posts", orderBy: "created_at"},
      ];

      for (const col of collections) {
        try {
          const snapshot = await db.collection(col.name)
              .orderBy(col.orderBy, "desc")
              .limit(100)
              .get();

          if (snapshot.empty || snapshot.docs.length < 100) continue;

          const oldestDoc = snapshot.docs[snapshot.docs.length - 1];
          const oldestDate = oldestDoc.data()[col.orderBy];

          const deleteSnap = await db.collection(col.name)
              .orderBy(col.orderBy, "desc")
              .startAfter(oldestDate)
              .limit(300)
              .get();

          if (deleteSnap.empty) continue;

          const batch = db.batch();
          deleteSnap.docs.forEach((doc) => {
            batch.delete(doc.ref);
          });
          await batch.commit();

          console.log(`[Cleanup] Deleted ${deleteSnap.docs.length} ` +
              `old documents from ${col.name}`);
        } catch (err) {
          console.error(`[Cleanup] Error cleaning up ${col.name}:`, err);
        }
      }
    },
);
