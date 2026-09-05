require("dotenv").config();

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const authRoutes = require("./routes/auth.routes");
const restaurantRoutes = require("./routes/restaurant.routes");
const orderRoutes = require("./routes/order.routes");

const errorHandler = require("./middleware/error.middleware");

const app = express();

// =========================================================
// MIDDLEWARE
// =========================================================

app.use(cors());
app.use(helmet());
app.use(express.json({ limit: "100kb" }));

// =========================================================
// ROUTES
// =========================================================

app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "HADROUG DELIVERY Backend is running 🚀"
  });
});

app.use("/api/auth", authRoutes);

app.use("/api/restaurant", restaurantRoutes);

app.use("/api/orders", orderRoutes);

// =========================================================
// ERROR HANDLER
// =========================================================

app.use(errorHandler);

// =========================================================
// SERVER
// =========================================================

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(
    `HADROUG DELIVERY Backend running on port ${PORT}`
  );
});  console.log(
    `HADROUG DELIVERY Backend running on port ${PORT}`
  );
});
