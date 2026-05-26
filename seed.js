require("dotenv").config();
const admin = require("firebase-admin");
const axios = require("axios");
const service = require("./serviceAccountKey.json");
// Connect to your Firestore
admin.initializeApp({ credential: admin.credential.cert(service) });
const db = admin.firestore();
const TMDB_KEY = process.env.TMDB_KEY;
const BASE = "https://api.themoviedb.org/3";
// Languages to seed — Malayalam is primary, also include Tamil and Hindi
// for users who watch multiple languages
const LANGUAGES = ["ml", "ta"];
async function fetchMovies(lang, page) {
  const { data } = await axios.get(`${BASE}/discover/movie`, {
    params: {
      api_key: TMDB_KEY,
      with_original_language: lang,
      sort_by: "popularity.desc",
      region: "IN",
      page,
    },
  });
  return data;
}
async function seedLanguage(lang) {
  console.log(`\nSeeding language: ${lang}`);
  const first = await fetchMovies(lang, 1);
  const totalPages = Math.min(first.total_pages, 20); // max 20 pages per

  for (let page = 1; page <= totalPages; page++) {
    const data = page === 1 ? first : await fetchMovies(lang, page);
    const batch = db.batch();
    for (const movie of data.results) {
      const ref = db.collection("movies").doc(String(movie.id));
      batch.set(
        ref,
        {
          tmdb_id: movie.id,
          title: movie.title || "",
          title_lower: (movie.title || "").toLowerCase(),
          original_title: movie.original_title || "",
          overview: movie.overview || "",
          poster_path: movie.poster_path || null,
          backdrop_path: movie.backdrop_path || null,
          popularity: movie.popularity || 0,
          vote_average: movie.vote_average || 0,
          vote_count: movie.vote_count || 0,
          release_date: movie.release_date || "",
          language: movie.original_language || lang,
          genre_ids: movie.genre_ids || [],
          adult: movie.adult || false,
          synced_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      ); // merge:true means re-runs won't duplicate
    }
    await batch.commit();
    console.log(
      ` ${lang} page ${page}/${totalPages} done (${data.results.length} movies)`,
    );
    // Small delay to be respectful to TMDB rate limits
    await new Promise((r) => setTimeout(r, 250));
  }
}
async function main() {
  console.log("Starting MovieCC seed...");
  for (const lang of LANGUAGES) {
    await seedLanguage(lang);
  }
  console.log("\nSeed complete! Check your Firestore console.");
  process.exit(0);
}
main().catch((err) => {
  console.error("Seed failed:", err.message);
  process.exit(1);
});
