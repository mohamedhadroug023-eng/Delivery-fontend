
require("dotenv").config();

const express = require("express");
const http = require("http");
const cors = require("cors");
const helmet = require("helmet");
const { Server } = require("socket.io");
const cron = require("node-cron");

const authRoutes = require("./routes/auth.routes");
const restaurantRoutes = require("./routes/restaurant.routes");
const orderRoutes = require("./routes/order.routes");
const driverRoutes = require("./routes/driver.routes");
const adminRoutes = require("./routes/admin.routes");

const { initializeSocket } = require("./socket/socket");

const {
  processExpiredOffers
} = require("./services/offer-expiration.service");

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

app.use("/api/driver", driverRoutes);

app.use("/api/admin", adminRoutes);

// =========================================================
// ERROR HANDLER
// =========================================================

app.use(errorHandler);

// =========================================================
// HTTP SERVER
// =========================================================

const PORT = process.env.PORT || 3000;

const server = http.createServer(app);

// =========================================================
// SOCKET.IO
// =========================================================

const io = new Server(server, {
  cors: {
    origin: "*"
  }
});

initializeSocket(io);

// =========================================================
// EXPIRED OFFERS WORKER
// =========================================================

cron.schedule("*/2 * * * * *", async () => {
  try {
    await processExpiredOffers();
  } catch (error) {
    console.error(
      "Expired offers worker error:",
      error
    );
  }
});

// =========================================================
// START SERVER
// =========================================================

server.listen(PORT, () => {
  console.log(
    `HADROUG DELIVERY Backend running on port ${PORT}`
  );

  console.log(
    `Socket.IO server is ready`
  );
});
