const express = require("express");

const {
  getDashboard,
  getRestaurants,
  getDrivers,
  getOrders
} = require("../controllers/admin.controller");

const {
  authenticate,
  authorize
} = require("../middleware/auth.middleware");

const router = express.Router();

// =============================
// ADMIN DASHBOARD
// =============================

router.get(
  "/dashboard",
  authenticate,
  authorize("admin"),
  getDashboard
);

// =============================
// RESTAURANTS
// =============================

router.get(
  "/restaurants",
  authenticate,
  authorize("admin"),
  getRestaurants
);

// =============================
// DRIVERS
// =============================

router.get(
  "/drivers",
  authenticate,
  authorize("admin"),
  getDrivers
);

// =============================
// ALL ORDERS
// =============================

router.get(
  "/orders",
  authenticate,
  authorize("admin"),
  getOrders
);

module.exports = router;
