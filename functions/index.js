/**
 * ChipDrop Firebase Cloud Function
 *
 * Runs every 5 minutes, scrapes freechipswsop.com,
 * and sends an FCM push notification to all subscribed devices
 * if new chip links are found.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const https = require("https");

admin.initializeApp();

const db = admin.firestore();
const CACHE_WINDOW_DAYS = 7;

// ─────────────────────────────────────────────
// Scheduled function: check for new chips
// ─────────────────────────────────────────────
exports.checkForNewChips = functions.pubsub
  .schedule("every 5 minutes")
  .timeZone("America/New_York")
  .onRun(async (context) => {
    console.log("⏱ ChipDrop check triggered");

    const html = await fetchPage("https://freechipswsop.com");
    if (!html) {
      console.error("❌ Failed to fetch freechipswsop.com");
      return null;
    }

    const parsedLinks = parseChipLinks(html);
    if (parsedLinks.length === 0) {
      console.error("❌ Parsed 0 chip links from page");
      await db.collection("chip_data").doc("cached_links").set(
        {
          lastFetchStatus: "parse_failed",
          lastFetchAttempt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return null;
    }

    const cachedLinks = filterLinksToRecentDays(parsedLinks, CACHE_WINDOW_DAYS);
    console.log(`🗂 Keeping ${cachedLinks.length} links from the last ${CACHE_WINDOW_DAYS} days`);

    const uniqueUrls = Array.from(new Set(parsedLinks.map((link) => link.url)));
    console.log(`🔍 Found ${uniqueUrls.length} total URLs on page`);

    // Load previously seen URLs from Firestore
    const docRef = db.collection("chip_data").doc("seen_urls");
    const cacheRef = db.collection("chip_data").doc("cached_links");
    const doc = await docRef.get();
    const seenUrls = new Set(doc.exists ? (doc.data().urls || []) : []);

    // Find brand-new URLs not seen before
    const newUrls = uniqueUrls.filter((url) => !seenUrls.has(url));
    console.log(`🆕 New URLs detected: ${newUrls.length}`);

    const batch = db.batch();

    if (newUrls.length > 0) {
      batch.set(
        docRef,
        {
          urls: uniqueUrls,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          lastNewCount: newUrls.length,
          totalSeen: uniqueUrls.length,
        },
        { merge: true }
      );
    } else {
      batch.set(
        docRef,
        { lastChecked: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true }
      );
    }

    batch.set(
      cacheRef,
      {
        links: cachedLinks.map((link) => ({
          title: link.title,
          url: link.url,
          dateString: link.dateString,
          datePosted: admin.firestore.Timestamp.fromDate(link.datePosted),
          chipAmount: link.chipAmount,
          rewardType: link.rewardType,
          isNew: link.isNew,
        })),
        linkCount: cachedLinks.length,
        cacheWindowDays: CACHE_WINDOW_DAYS,
        lastFetchStatus: "success",
        lastFetchAttempt: admin.firestore.FieldValue.serverTimestamp(),
        lastFetchedAt: admin.firestore.FieldValue.serverTimestamp(),
        ...(newUrls.length > 0
          ? { contentUpdatedAt: admin.firestore.FieldValue.serverTimestamp() }
          : {}),
      },
      { merge: true }
    );

    if (newUrls.length > 0) {
      // Build FCM message — all devices subscribed to "new_chips" topic receive it
      const message = {
        notification: {
          title: "🎰 New Chips Available!",
          body:
            newUrls.length === 1
              ? "1 new chip link just dropped! Tap to collect before it expires."
              : `${newUrls.length} new chip links just dropped! Tap to collect before they expire.`,
        },
        topic: "new_chips",
        apns: {
          payload: {
            aps: {
              sound: "default",
              "content-available": 1,
            },
          },
          headers: {
            "apns-priority": "10",
          },
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "chip_drops",
          },
        },
        data: {
          newCount: String(newUrls.length),
          type: "new_chips",
        },
      };

      try {
        const response = await admin.messaging().send(message);
        console.log(`✅ Notification sent: ${response}`);
      } catch (err) {
        console.error("❌ FCM send error:", err);
      }
    }

    await batch.commit();
    console.log(`📦 Firestore cache updated with ${cachedLinks.length} links from the last ${CACHE_WINDOW_DAYS} days`);

    return null;
  });

function filterLinksToRecentDays(links, days) {
  const cutoff = new Date();
  cutoff.setUTCHours(0, 0, 0, 0);
  cutoff.setUTCDate(cutoff.getUTCDate() - (days - 1));

  return links.filter((link) => link.datePosted >= cutoff);
}

function parseChipLinks(html) {
  const headingRegex = /<h([1-6])[^>]*>([\s\S]*?)<\/h\1>/gi;
  const headings = [];
  let match;

  while ((match = headingRegex.exec(html)) !== null) {
    const rawHeading = stripHtml(match[2]);
    const parsedDate = parseHeadingDate(rawHeading);
    if (!parsedDate) continue;

    headings.push({
      startIndex: match.index,
      endIndex: headingRegex.lastIndex,
      dateString: rawHeading,
      datePosted: parsedDate,
    });
  }

  if (headings.length === 0) return [];

  const links = [];
  for (let i = 0; i < headings.length; i += 1) {
    const current = headings[i];
    const next = headings[i + 1];
    const sectionHtml = html.slice(current.endIndex, next ? next.startIndex : html.length);
    links.push(...extractLinksFromSection(sectionHtml, current.dateString, current.datePosted));
  }

  const unique = new Map();
  for (const link of links) {
    if (!unique.has(link.url)) {
      unique.set(link.url, link);
    }
  }

  return Array.from(unique.values()).sort((a, b) => b.datePosted - a.datePosted);
}

function extractLinksFromSection(sectionHtml, dateString, datePosted) {
  const links = [];
  const linkRegex = /<a[^>]*href="(https:\/\/www\.wsopga\.me\/[^\"]+)"[^>]*>([\s\S]*?)<\/a>/gi;
  let match;

  while ((match = linkRegex.exec(sectionHtml)) !== null) {
    const url = match[1].trim();
    const title = stripHtml(match[2]);
    if (!title) continue;

    links.push(buildChipLink(title, url, dateString, datePosted));
  }

  return links;
}

function buildChipLink(title, url, dateString, datePosted) {
  const lower = title.toLowerCase();
  let rewardType = "other";
  let chipAmount = 0;

  if (lower.includes("free chips")) {
    rewardType = "chips";
    const digits = title.replace(/\D/g, "");
    chipAmount = parseInt(digits || "450000", 10);
    if (chipAmount < 1000) chipAmount = 450000;
  } else if (lower.includes("free spins")) {
    rewardType = "freeSpins";
  } else if (lower.includes("coffee mug")) {
    rewardType = "coffeeMug";
  } else if (lower.includes("ribbon")) {
    rewardType = "ribbons";
  }

  return {
    title,
    url,
    dateString,
    datePosted,
    chipAmount,
    rewardType,
    isNew: isToday(datePosted) || isYesterday(datePosted),
  };
}

function parseHeadingDate(text) {
  const cleaned = text
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  const normalized = cleaned
    .replace(/(\d+)(st|nd|rd|th)/gi, "$1")
    .replace(/Feburary/gi, "February")
    .trim();

  if (!/^\d{1,2}\s+[A-Za-z]+\s+\d{4}$/.test(normalized) &&
      !/^[A-Za-z]+\s+\d{1,2},?\s+\d{4}$/.test(normalized)) {
    return null;
  }

  const parsed = new Date(`${normalized} UTC`);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed;
}

function stripHtml(value) {
  return value
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/gi, " ")
    .replace(/&#8211;/g, "-")
    .replace(/&amp;/g, "&")
    .replace(/\s+/g, " ")
    .trim();
}

function isToday(date) {
  const now = new Date();
  return date.getUTCFullYear() === now.getUTCFullYear() &&
    date.getUTCMonth() === now.getUTCMonth() &&
    date.getUTCDate() === now.getUTCDate();
}

function isYesterday(date) {
  const yesterday = new Date();
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  return date.getUTCFullYear() === yesterday.getUTCFullYear() &&
    date.getUTCMonth() === yesterday.getUTCMonth() &&
    date.getUTCDate() === yesterday.getUTCDate();
}

// ─────────────────────────────────────────────
// Helper: fetch a URL and return HTML string
// ─────────────────────────────────────────────
function fetchPage(url) {
  return new Promise((resolve) => {
    const options = {
      headers: {
        "User-Agent":
          "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) " +
          "AppleWebKit/605.1.15 (KHTML, like Gecko) " +
          "Version/17.0 Mobile/15E148 Safari/604.1",
        Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      },
      timeout: 30000,
    };

    https
      .get(url, options, (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => resolve(data));
      })
      .on("error", (err) => {
        console.error("Fetch error:", err.message);
        resolve(null);
      });
  });
}
