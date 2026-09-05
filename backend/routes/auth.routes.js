const express = require("express");

const { login } = require("../controllers/auth.controller");
const { authRateLimit } = require("../middleware/rateLimit.middleware");

const router = express.Router();

// =========================================================
// LOGIN
// =========================================================

// POST /api/auth/login
router.post(
  "/login",
  authRateLimit,
  login
);

module.exports = router;
