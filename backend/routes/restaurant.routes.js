const express = require("express");

const {
  getProfile,
  getOrders
} = require("../controllers/restaurant.controller");

const {
  authenticate,
  authorize
} = require("../middleware/auth.middleware");

const router = express.Router();

// =========================================================
// RESTAURANT PROFILE
// =========================================================

// GET /api/restaurant/profile
router.get(
  "/profile",
  authenticate,
  authorize("restaurant"),
  getProfile
);

// =========================================================
// RESTAURANT ORDERS
// =========================================================

// GET /api/restaurant/orders
router.get(
  "/orders",
  authenticate,
  authorize("restaurant"),
  getOrders
);

module.exports = router;
