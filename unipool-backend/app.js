const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(require('./serviceAccountKey.json')),
});

const db = admin.firestore();

// ==============================
// TEST API
// ==============================
app.get('/', (req, res) => {
    res.send('UniPool Backend is running!');
});

// ==============================
// TEST: Get all users
// ==============================
app.get('/users', async (req, res) => {
    try {
        const snapshot = await db.collection('users').get();
        const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        res.json(users);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ==============================
// MATCHING ENGINE FUNCTIONS
// ==============================

/**
 * Calculate distance between two coordinates using Haversine formula
 * @param {number} lat1 - Latitude of point 1
 * @param {number} lon1 - Longitude of point 1
 * @param {number} lat2 - Latitude of point 2
 * @param {number} lon2 - Longitude of point 2
 * @returns {number} Distance in kilometers
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Earth's radius in km
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos((lat1 * Math.PI) / 180) *
            Math.cos((lat2 * Math.PI) / 180) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

/**
 * Calculate time difference in minutes
 * @param {*} time1 - First time (timestamp or Date)
 * @param {*} time2 - Second time (timestamp or Date)
 * @returns {number} Absolute difference in minutes
 */
function calculateTimeDifference(time1, time2) {
    const t1 = time1.toMillis ? time1.toMillis() : new Date(time1).getTime();
    const t2 = time2.toMillis ? time2.toMillis() : new Date(time2).getTime();
    return Math.abs(t1 - t2) / (1000 * 60);
}

/**
 * Calculate match score between two rides
 * @param {Object} rideA - First ride object
 * @param {Object} rideB - Second ride object
 * @returns {Object} Match score and details
 */
function calculateMatchScore(rideA, rideB) {
    let score = 0;
    const details = {};

    // 1. Route proximity (max 40 points)
    const pickupDistance = calculateDistance(
        rideA.pickupLocation.latitude,
        rideA.pickupLocation.longitude,
        rideB.pickupLocation.latitude,
        rideB.pickupLocation.longitude
    );
    const dropoffDistance = calculateDistance(
        rideA.dropoffLocation.latitude,
        rideA.dropoffLocation.longitude,
        rideB.dropoffLocation.latitude,
        rideB.dropoffLocation.longitude
    );

    const MAX_PICKUP_DISTANCE = 2; // km
    const MAX_DROPOFF_DISTANCE = 2; // km

    if (pickupDistance <= MAX_PICKUP_DISTANCE) {
        score += (1 - pickupDistance / MAX_PICKUP_DISTANCE) * 20;
    }
    if (dropoffDistance <= MAX_DROPOFF_DISTANCE) {
        score += (1 - dropoffDistance / MAX_DROPOFF_DISTANCE) * 20;
    }
    details.pickupDistance = pickupDistance;
    details.dropoffDistance = dropoffDistance;

    // 2. Time compatibility (max 30 points)
    const timeDifference = calculateTimeDifference(
        rideA.departureTime,
        rideB.departureTime
    );
    const MAX_TIME_DIFFERENCE = 30; // minutes

    if (timeDifference <= MAX_TIME_DIFFERENCE) {
        score += (1 - timeDifference / MAX_TIME_DIFFERENCE) * 30;
    }
    details.timeDifference = timeDifference;

    // 3. Direction alignment (max 20 points)
    const routeOverlap = calculateRouteOverlap(rideA, rideB);
    score += routeOverlap * 20;
    details.routeOverlap = routeOverlap;

    // 4. Gender preference (max 10 points)
    if (rideA.genderPreference === 'any' || rideB.genderPreference === 'any') {
        score += 10;
    } else if (rideA.genderPreference === rideB.genderPreference) {
        score += 10;
    }
    details.genderMatch = rideA.genderPreference === rideB.genderPreference;

    return {
        totalScore: Math.round(score * 100) / 100,
        maxScore: 100,
        percentage: Math.round((score / 100) * 100),
        details
    };
}

/**
 * Calculate route overlap percentage
 * @param {Object} rideA
 * @param {Object} rideB
 * @returns {number} Overlap percentage (0-1)
 */
function calculateRouteOverlap(rideA, rideB) {
    // Simple linear route overlap calculation
    const pickupA = rideA.pickupLocation;
    const dropoffA = rideA.dropoffLocation;
    const pickupB = rideB.pickupLocation;
    const dropoffB = rideB.dropoffLocation;

    const totalDistanceA = calculateDistance(
        pickupA.latitude,
        pickupA.longitude,
        dropoffA.latitude,
        dropoffA.longitude
    );

    // Estimate overlap by checking if one ride is somewhat on the way of the other
    const detourDistance = Math.min(
        calculateDistance(
            pickupA.latitude,
            pickupA.longitude,
            pickupB.latitude,
            pickupB.longitude
        ) +
            calculateDistance(
                pickupB.latitude,
                pickupB.longitude,
                dropoffA.latitude,
                dropoffA.longitude
            ),
        calculateDistance(
            pickupB.latitude,
            pickupB.longitude,
            pickupA.latitude,
            pickupA.longitude
        ) +
            calculateDistance(
                pickupA.latitude,
                pickupA.longitude,
                dropoffB.latitude,
                dropoffB.longitude
            )
    );

    const directDistance = calculateDistance(
        pickupA.latitude,
        pickupA.longitude,
        dropoffA.latitude,
        dropoffA.longitude
    );

    const overlap = Math.max(0, 1 - (detourDistance - directDistance) / directDistance);
    return Math.min(1, overlap);
}

// ==============================
// MATCHING API ENDPOINTS
// ==============================

/**
 * GET /matches/:userId
 * Get all potential matches for a specific ride
 */
app.get('/matches/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const { minScore = 50 } = req.query;

        // Get user's ride request
        const userRideSnapshot = await db
            .collection('rides')
            .where('userId', '==', userId)
            .where('status', '==', 'pending')
            .get();

        if (userRideSnapshot.empty) {
            return res.json({
                message: 'No pending ride found for this user',
                matches: []
            });
        }

        const userRide = userRideSnapshot.docs[0];
        const userRideData = { id: userRide.id, ...userRide.data() };

        // Get all other pending rides
        const allRidesSnapshot = await db
            .collection('rides')
            .where('status', '==', 'pending')
            .get();

        const matches = [];

        allRidesSnapshot.forEach(doc => {
            const otherRide = { id: doc.id, ...doc.data() };

            // Don't match with itself
            if (otherRide.id === userRideData.id) return;

            // Don't match if user already matched
            if (userRideData.matchedWith?.includes(otherRide.id)) return;

            const matchScore = calculateMatchScore(userRideData, otherRide);

            if (matchScore.percentage >= minScore) {
                matches.push({
                    rideId: otherRide.id,
                    userId: otherRide.userId,
                    ...otherRide,
                    matchScore
                });
            }
        });

        // Sort by match score (highest first)
        matches.sort((a, b) => b.matchScore.percentage - a.matchScore.percentage);

        res.json({
            userRide: userRideData,
            totalMatches: matches.length,
            matches
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * POST /match-accept
 * Accept a match between two rides
 */
app.post('/match-accept', async (req, res) => {
    try {
        const { userId1, rideId1, userId2, rideId2 } = req.body;

        if (!userId1 || !rideId1 || !userId2 || !rideId2) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        // Create a match document
        const matchRef = db.collection('matches').doc();
        const matchData = {
            user1Id: userId1,
            ride1Id: rideId1,
            user2Id: userId2,
            ride2Id: rideId2,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'pending_confirmation',
            confirmations: {
                [userId1]: false,
                [userId2]: false
            }
        };

        await matchRef.set(matchData);

        // Update both rides with match info
        await db.collection('rides').doc(rideId1).update({
            matchedWith: admin.firestore.FieldValue.arrayUnion(rideId2),
            status: 'matched'
        });

        await db.collection('rides').doc(rideId2).update({
            matchedWith: admin.firestore.FieldValue.arrayUnion(rideId1),
            status: 'matched'
        });

        res.json({
            success: true,
            matchId: matchRef.id,
            message: 'Match created successfully'
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * POST /confirm-match
 * Confirm a match by user
 */
app.post('/confirm-match', async (req, res) => {
    try {
        const { matchId, userId } = req.body;

        if (!matchId || !userId) {
            return res.status(400).json({ error: 'Missing matchId or userId' });
        }

        const matchRef = db.collection('matches').doc(matchId);
        const matchDoc = await matchRef.get();

        if (!matchDoc.exists) {
            return res.status(404).json({ error: 'Match not found' });
        }

        const matchData = matchDoc.data();

        // Update confirmation status
        await matchRef.update({
            [`confirmations.${userId}`]: true
        });

        // Check if both users confirmed
        const updatedMatch = await matchRef.get();
        const allConfirmed = Object.values(updatedMatch.data().confirmations).every(
            v => v === true
        );

        if (allConfirmed) {
            await matchRef.update({ status: 'confirmed' });

            // Update ride statuses
            await db.collection('rides').doc(matchData.ride1Id).update({
                status: 'confirmed'
            });
            await db.collection('rides').doc(matchData.ride2Id).update({
                status: 'confirmed'
            });
        }

        res.json({
            success: true,
            matchStatus: updatedMatch.data().status,
            allConfirmed
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * POST /create-ride
 * Create a new ride request
 */
app.post('/create-ride', async (req, res) => {
    try {
        const {
            userId,
            pickupLocation,
            dropoffLocation,
            departureTime,
            seatsAvailable,
            maxFare,            
            genderPreference,
            vehicleInfo
        } = req.body;

        if (!userId || !pickupLocation || !dropoffLocation || !departureTime) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        const rideData = {
            userId,
            pickupLocation,
            dropoffLocation,
            departureTime: new Date(departureTime),
            seatsAvailable,
            maxFare: maxFare || 0,        // now correctly references the extracted value
            genderPreference: genderPreference || 'any',
            vehicleInfo: vehicleInfo || null,
            status: 'pending',
            matchedWith: [],
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        const rideRef = await db.collection('rides').add(rideData);

        res.json({
            success: true,
            rideId: rideRef.id,
            ride: rideData
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * GET /ride/:rideId
 * Get specific ride details
 */
app.get('/ride/:rideId', async (req, res) => {
    try {
        const { rideId } = req.params;
        const rideDoc = await db.collection('rides').doc(rideId).get();

        if (!rideDoc.exists) {
            return res.status(404).json({ error: 'Ride not found' });
        }

        res.json({
            id: rideDoc.id,
            ...rideDoc.data()
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * GET /user-rides/:userId
 * Get all rides for a specific user
 */
app.get('/user-rides/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const ridesSnapshot = await db
            .collection('rides')
            .where('userId', '==', userId)
            .orderBy('createdAt', 'desc')
            .get();

        const rides = ridesSnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        res.json({
            userId,
            totalRides: rides.length,
            rides
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/**
 * GET /stats
 * Get system statistics
 */
app.get('/stats', async (req, res) => {
    try {
        const usersCount = (await db.collection('users').get()).size;
        const ridesCount = (await db.collection('rides').get()).size;
        const matchesCount = (await db.collection('matches').get()).size;
        const pendingRidesCount = (
            await db.collection('rides').where('status', '==', 'pending').get()
        ).size;

        res.json({
            stats: {
                totalUsers: usersCount,
                totalRides: ridesCount,
                totalMatches: matchesCount,
                pendingRides: pendingRidesCount
            }
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ==============================
// Server Start
// ==============================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`UniPool backend running on http://localhost:${PORT}`);
});

module.exports = app;