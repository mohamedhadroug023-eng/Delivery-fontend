const express = require("express");

const {
  getProfile,
  getOrders,
  verifyPickupOtp
} = require("../controllers/restaurant.controller");

const {
  authenticate,
  authorize
} = require("../middleware/auth.middleware");

const router = express.Router();


// =========================================================
// RESTAURANT PROFILE
// =========================================================

router.get(
  "/profile",
  authenticate,
  authorize("restaurant"),
  getProfile
);


// =========================================================
// RESTAURANT ORDERS
// =========================================================

router.get(
  "/orders",
  authenticate,
  authorize("restaurant"),
  getOrders
);


// =========================================================
// VERIFY PICKUP OTP
// =========================================================

router.post(
  "/orders/verify-pickup",
  authenticate,
  authorize("restaurant"),
  verifyPickupOtp
);


module.exports = router;
