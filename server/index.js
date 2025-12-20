const express = require("express");
const admin = require("firebase-admin");
const cors = require("cors");
const path = require("path");

const app = express();
app.use(express.json());
app.use(cors());

// Initialize Firebase Admin
// For local dev put serviceAccountKey.json in server/ (DO NOT commit)
// Alternatively use GOOGLE_APPLICATION_CREDENTIALS env var for best security
const keyPath = path.join(__dirname, "serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(require(keyPath)),
});

const db = admin.firestore();
const USERS = db.collection("users");
const TUTORS = db.collection("tutors");

// Matching logic (same as your snippet)
function calculateMatchScore(student, tutor) {
  let score = 0;

  if (tutor.subjects?.includes(student.subject)) {
    score += 50;
  }
  if (tutor.levels?.includes(student.level)) {
    score += 20;
  }
  if (tutor.location && student.location && tutor.location === student.location) {
    score += 15;
  }
  if (tutor.rate !== undefined && student.budget !== undefined) {
    const diff = Math.abs(tutor.rate - student.budget);
    if (diff < 10) score += 15;
    else if (diff < 20) score += 10;
    else if (diff < 30) score += 5;
  }

  return score;
}

// POST /match { studentId }
app.post("/match", async (req, res) => {
  try {
    const { studentId } = req.body;
    if (!studentId) return res.status(400).json({ error: "studentId is required" });

    const studentDoc = await USERS.doc(studentId).get();
    if (!studentDoc.exists) return res.status(404).json({ error: "Student not found" });
    const student = studentDoc.data();

    const tutorsSnapshot = await TUTORS.get();
    let results = [];
    tutorsSnapshot.forEach((doc) => {
      const tutor = doc.data();
      const score = calculateMatchScore(student, tutor);
      results.push({
        tutorId: doc.id,
        score,
        tutor,
      });
    });

    results.sort((a, b) => b.score - a.score);
    res.json(results.slice(0, 5));
  } catch (error) {
    console.error("Matching error:", error);
    res.status(500).json({ error: "Server error" });
  }
});

// start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));