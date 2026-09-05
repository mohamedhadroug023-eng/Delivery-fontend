const express = require("express");

const {
  getProfile,
  updateOnlineStatus,
  updateLocation,
  acceptOrderOffer,
  rejectOrderOffer
} = require("../controllers/driver.controller");

const {
  authenticate,
  authorize
} = require("../middleware/auth.middleware");

const router = express.Router();

// =========================================================
// DRIVER PROFILE
// =========================================================

// GET /api/driver/profile
router.get(
  "/profile",
  authenticate,
  authorize("driver"),
  getProfile
);

// =========================================================
// DRIVER ONLINE STATUS
// =========================================================

// PATCH /api/driver/online
router.patch(
  "/online",
  authenticate,
  authorize("driver"),
  updateOnlineStatus
);

// =========================================================
// DRIVER LOCATION
// =========================================================

// PATCH /api/driver/location
router.patch(
  "/location",
  authenticate,
  authorize("driver"),
  updateLocation
);

// =========================================================
// ACCEPT ORDER OFFER
// =========================================================

// POST /api/driver/orders/accept
router.post(
  "/orders/accept",
  authenticate,
  authorize("driver"),
  acceptOrderOffer
);

// =========================================================
// REJECT ORDER OFFER
// =========================================================

// POST /api/driver/orders/reject
router.post(
  "/orders/reject",
  authenticate,
  authorize("driver"),
  rejectOrderOffer
);

module.exports = router;
