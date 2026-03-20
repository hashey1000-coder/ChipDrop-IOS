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

    // Extract all wsopga.me chip links from the page
    const urlRegex = /href="(https:\/\/www\.wsopga\.me\/[^"]+)"/gi;
    const foundUrls = new Set();
    let match;
    while ((match = urlRegex.exec(html)) !== null) {
      foundUrls.add(match[1]);
    }
    const uniqueUrls = Array.from(foundUrls);
    console.log(`🔍 Found ${uniqueUrls.length} total URLs on page`);

    // Load previously seen URLs from Firestore
    const docRef = db.collection("chip_data").doc("seen_urls");
    const doc = await docRef.get();
    const seenUrls = new Set(doc.exists ? (doc.data().urls || []) : []);

    // Find brand-new URLs not seen before
    const newUrls = uniqueUrls.filter((url) => !seenUrls.has(url));
    console.log(`🆕 New URLs detected: ${newUrls.length}`);

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

      // Persist updated full URL list to Firestore
      await docRef.set({
        urls: uniqueUrls,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        lastNewCount: newUrls.length,
        totalSeen: uniqueUrls.length,
      });

      console.log(`📦 Firestore updated with ${uniqueUrls.length} URLs`);
    } else {
      // No new chips — just update the last-checked timestamp
      await docRef.set(
        { lastChecked: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true }
      );
      console.log("✓ No new chips. Timestamp updated.");
    }

    return null;
  });

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
