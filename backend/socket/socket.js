const jwt = require("jsonwebtoken");

const {
  initializeNotificationService
} = require("../services/notification.service");

// =========================================================
// INITIALIZE SOCKET.IO
// =========================================================

function initializeSocket(io) {

  initializeNotificationService(io);

  // -------------------------------------------------------
  // SOCKET AUTHENTICATION
  // -------------------------------------------------------

  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth?.token;

      if (!token) {
        return next(
          new Error("Authentication required")
        );
      }

      const decoded = jwt.verify(
        token,
        process.env.JWT_SECRET
      );

      if (decoded.role !== "driver") {
        return next(
          new Error("Driver access required")
        );
      }

      socket.user = decoded;

      next();

    } catch (error) {
      next(
        new Error("Invalid or expired token")
      );
    }
  });

  // -------------------------------------------------------
  // CONNECTION
  // -------------------------------------------------------

  io.on("connection", (socket) => {

    console.log(
      `Socket connected: ${socket.id} - Driver ${socket.user.id}`
    );

    // -----------------------------------------------------
    // DRIVER ROOM
    // -----------------------------------------------------

    socket.on("driver_join", () => {

      const driverId = socket.user.id;

      socket.join(`driver_${driverId}`);

      console.log(
        `Driver ${driverId} joined socket room`
      );

    });

    // -----------------------------------------------------
    // DISCONNECT
    // -----------------------------------------------------

    socket.on("disconnect", () => {

      console.log(
        `Socket disconnected: ${socket.id}`
      );

    });

  });
}

module.exports = {
  initializeSocket
};
