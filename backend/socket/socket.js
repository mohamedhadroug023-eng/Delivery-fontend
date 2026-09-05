const {
  initializeNotificationService
} = require("../services/notification.service");

// =========================================================
// INITIALIZE SOCKET.IO
// =========================================================

function initializeSocket(io) {

  initializeNotificationService(io);

  io.on("connection", (socket) => {

    console.log(
      `Socket connected: ${socket.id}`
    );

    // -------------------------------------------------------
    // DRIVER ROOM
    // -------------------------------------------------------

    socket.on("driver_join", (driverId) => {

      if (!driverId) {
        return;
      }

      socket.join(`driver_${driverId}`);

      console.log(
        `Driver ${driverId} joined socket room`
      );
    });

    // -------------------------------------------------------
    // DISCONNECT
    // -------------------------------------------------------

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
