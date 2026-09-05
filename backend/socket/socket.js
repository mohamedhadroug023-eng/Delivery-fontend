const jwt = require("jsonwebtoken");

const pool = require("../config/database");

const {
  initializeNotificationService
} = require("../services/notification.service");


/* =========================================================
   SOCKET INITIALIZATION
========================================================= */

function initializeSocket(io) {

  initializeNotificationService(io);


  /* =======================================================
     SOCKET AUTHENTICATION
  ======================================================= */

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


      /* =====================================================
         DRIVER
      ===================================================== */

      if (decoded.role === "driver") {

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


        socket.user = decoded;

        socket.driver = {
          id: drivers[0].id,
          user_id: drivers[0].user_id
        };


        return next();
      }


      /* =====================================================
         RESTAURANT
      ===================================================== */

      if (decoded.role === "restaurant") {

        const [restaurants] =
          await pool.execute(
            `
            SELECT
              id,
              user_id
            FROM restaurants
            WHERE user_id = ?
            LIMIT 1
            `,
            [decoded.id]
          );


        if (restaurants.length === 0) {
          return next(
            new Error(
              "Restaurant profile not found"
            )
          );
        }


        socket.user = decoded;

        socket.restaurant = {
          id: restaurants[0].id,
          user_id:
            restaurants[0].user_id
        };


        return next();
      }


      /* =====================================================
         ADMIN
      ===================================================== */

      if (decoded.role === "admin") {

        socket.user = decoded;

        return next();
      }


      return next(
        new Error(
          "Invalid user role"
        )
      );

    } catch (error) {

      console.error(
        "Socket authentication error:",
        error
      );

      return next(
        new Error(
          "Invalid or expired token"
        )
      );
    }
  });


  /* =========================================================
     CONNECTION
  ========================================================= */

  io.on(
    "connection",
    (socket) => {

      console.log(
        `Socket connected: ${socket.id} - ` +
        `User ${socket.user.id} - ` +
        `Role ${socket.user.role}`
      );


      /* =====================================================
         DRIVER
      ===================================================== */

      if (
        socket.user.role ===
        "driver"
      ) {

        const driverId =
          socket.driver.id;


        socket.join(
          `driver_${driverId}`
        );


        console.log(
          `Driver ${driverId} joined room`
        );


        socket.on(
          "driver_join",
          () => {

            socket.join(
              `driver_${driverId}`
            );

            console.log(
              `Driver ${driverId} joined socket room`
            );
          }
        );
      }


      /* =====================================================
         RESTAURANT
      ===================================================== */

      if (
        socket.user.role ===
        "restaurant"
      ) {

        const restaurantId =
          socket.restaurant.id;


        socket.join(
          `restaurant_${restaurantId}`
        );


        console.log(
          `Restaurant ${restaurantId} joined room`
        );
      }


      /* =====================================================
         ADMIN
      ===================================================== */

      if (
        socket.user.role ===
        "admin"
      ) {

        socket.join(
          "admins"
        );


        console.log(
          `Admin ${socket.user.id} joined admin room`
        );
      }


      /* =====================================================
         DISCONNECT
      ===================================================== */

      socket.on(
        "disconnect",
        () => {

          console.log(
            `Socket disconnected: ${socket.id} - ` +
            `User ${socket.user.id} - ` +
            `Role ${socket.user.role}`
          );
        }
      );
    }
  );
}


module.exports = {
  initializeSocket
};
