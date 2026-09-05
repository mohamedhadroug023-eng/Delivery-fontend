const rateLimit = require("express-rate-limit");

// =========================================================
// AUTH RATE LIMIT
// =========================================================

const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Maximum 10 attempts
  standardHeaders: true,
  legacyHeaders: false,

  message: {
    success: false,
    message: "Too many attempts. Please try again later."
  }
});

module.exports = {
  authRateLimit
};
