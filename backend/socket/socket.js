const jwt = require("jsonwebtoken");

const pool = require("../config/database");

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

  io.use(async (socket, next) => {
    try {
      const token =
        socket.handshake.auth?.token;

      if (!token) {
        return next(
          new Error(
            "Authentication required"
          )
        );
      }

      const decoded =
        jwt.verify(
          token,
          process.env.JWT_SECRET
        );

      if (decoded.role !== "driver") {
        return next(
          new Error(
            "Driver access required"
          )
        );
      }

      // ---------------------------------------------------
      // GET DRIVER ID FROM USER ID
      // ---------------------------------------------------

      const [drivers] =
        await pool.execute(
          `
          SELECT
            id,
            user_id
          FROM drivers
          WHERE user_id = ?
          LIMIT 1
          `,
          [decoded.id]
        );

      if (drivers.length === 0) {
        return next(
          new Error(
            "Driver profile not found"
          )
        );
      }

      // ---------------------------------------------------
      // SAVE AUTHENTICATED DATA
      // ---------------------------------------------------

      socket.user = decoded;

      socket.driver = {
        id: drivers[0].id,
        user_id: drivers[0].user_id
      };

      next();

    } catch (error) {

      console.error(
        "Socket authentication error:",
        error
      );

      next(
        new Error(
          "Invalid or expired token"
        )
      );
    }
  });

  // -------------------------------------------------------
  // CONNECTION
  // -------------------------------------------------------

  io.on(
    "connection",
    (socket) => {

      console.log(
        `Socket connected: ${socket.id} - ` +
        `User ${socket.user.id} - ` +
        `Driver ${socket.driver.id}`
      );

      // ---------------------------------------------------
      // DRIVER ROOM
      // ---------------------------------------------------

      socket.on(
        "driver_join",
        () => {

          const driverId =
            socket.driver.id;

          socket.join(
            `driver_${driverId}`
          );

          console.log(
            `Driver ${driverId} joined socket room`
          );
        }
      );

      // ---------------------------------------------------
      // DISCONNECT
      // ---------------------------------------------------

      socket.on(
        "disconnect",
        () => {

          console.log(
            `Socket disconnected: ${socket.id} - ` +
            `Driver ${socket.driver.id}`
          );
        }
      );
    }
  );
}

module.exports = {
  initializeSocket
};
