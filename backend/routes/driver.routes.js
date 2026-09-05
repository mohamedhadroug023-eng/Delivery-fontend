const express = require("express");

const {
  getProfile,
  getOrders,
  updateOnlineStatus,
  updateLocation,
  acceptOrderOffer,
  rejectOrderOffer,
  arriveAtRestaurant,
  startDelivery,
  completeDelivery
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
// DRIVER ORDERS
// =========================================================

// GET /api/driver/orders
router.get(
  "/orders",
  authenticate,
  authorize("driver"),
  getOrders
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

// =========================================================
// DRIVER ARRIVED AT RESTAURANT
// =========================================================

// POST /api/driver/orders/arrive
router.post(
  "/orders/arrive",
  authenticate,
  authorize("driver"),
  arriveAtRestaurant
);

// =========================================================
// START DELIVERY
// =========================================================

// POST /api/driver/orders/start-delivery
router.post(
  "/orders/start-delivery",
  authenticate,
  authorize("driver"),
  startDelivery
);

// =========================================================
// COMPLETE DELIVERY
// =========================================================

// POST /api/driver/orders/deliver
router.post(
  "/orders/deliver",
  authenticate,
  authorize("driver"),
  completeDelivery
);

module.exports = router;
