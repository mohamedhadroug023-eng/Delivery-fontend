const express = require("express");

const { login, register } = require("../controllers/auth.controller");
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

// =========================================================
// REGISTER
// =========================================================

// POST /api/auth/register
router.post(
  "/register",
  authRateLimit,
  register
);

module.exports = router;
