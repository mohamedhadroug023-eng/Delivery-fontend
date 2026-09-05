const express = require("express");

const {
  createOrder
} = require("../controllers/order.controller");

const {
  authenticate,
  authorize
} = require("../middleware/auth.middleware");

const router = express.Router();

// =========================================================
// CREATE ORDER
// =========================================================

// POST /api/orders
router.post(
  "/",
  authenticate,
  authorize("restaurant"),
  createOrder
);

module.exports = router;
