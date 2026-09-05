require("dotenv").config();

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const app = express();

// ===============================
// Middleware
// ===============================

app.use(cors());
app.use(helmet());
app.use(express.json({ limit: "100kb" }));

// ===============================
// Health Check
// ===============================

app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "HADROUG DELIVERY Backend is running 🚀"
  });
});

// ===============================
// Server
// ===============================

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`HADROUG DELIVERY Backend running on port ${PORT}`);
});
