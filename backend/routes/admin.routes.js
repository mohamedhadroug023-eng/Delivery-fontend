const express = require("express");

const {
  getDashboard,
  getRestaurants,
  getDrivers,
  getOrders,
  updateRestaurantStatus,
  updateDriverStatus
} = require("../controllers/admin.controller");

const {
  authenticate,
  authorize
} = require("../middleware/auth.middleware");

const router = express.Router();

/* =========================================================
   DASHBOARD
========================================================= */

router.get(
  "/dashboard",
  authenticate,
  authorize("admin"),
  getDashboard
);


/* =========================================================
   RESTAURANTS
========================================================= */

router.get(
  "/restaurants",
  authenticate,
  authorize("admin"),
  getRestaurants
);

router.patch(
  "/restaurants/:id/status",
  authenticate,
  authorize("admin"),
  updateRestaurantStatus
);


/* =========================================================
   DRIVERS
========================================================= */

router.get(
  "/drivers",
  authenticate,
  authorize("admin"),
  getDrivers
);

router.patch(
  "/drivers/:id/status",
  authenticate,
  authorize("admin"),
  updateDriverStatus
);


/* =========================================================
   ORDERS
========================================================= */

router.get(
  "/orders",
  authenticate,
  authorize("admin"),
  getOrders
);


module.exports = router;
