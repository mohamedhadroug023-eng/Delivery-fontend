const bcrypt = require("bcrypt");

const pool = require("../config/database");

const {
  sendOrderOffer
} = require("../services/dispatch.service");

const {
  notifyDriverAccepted,
  notifyDriverArrived,
  notifyDeliveryStarted,
  notifyOrderDelivered
} = require("../services/notification.service");


/* =========================================================
   GET DRIVER PROFILE
========================================================= */

async function getProfile(req, res, next) {
  try {

    const [drivers] =
      await pool.execute(
        `
        SELECT
          d.id,
          d.user_id,
          d.phone,
          d.vehicle_type,
          d.is_online,
          d.is_available,
          d.current_orders_count,
          d.total_completed_orders,

          dl.latitude,
          dl.longitude,
          dl.accuracy,
          dl.updated_at,

          u.full_name,
          u.email,
          u.is_active

        FROM drivers d

        INNER JOIN users u
          ON u.id = d.user_id

        LEFT JOIN driver_locations dl
          ON dl.driver_id = d.id

        WHERE d.user_id = ?

        LIMIT 1
        `,
        [req.user.id]
      );


    if (drivers.length === 0) {
      return res.status(404).json({
        success: false,
        message:
          "Driver profile not found"
      });
    }


    return res.status(200).json({
      success: true,
      driver: drivers[0]
    });

  } catch (error) {
    next(error);
  }
}


/* =========================================================
   GET DRIVER ORDERS
========================================================= */

async function getOrders(req, res, next) {
  try {

    const [drivers] =
      await pool.execute(
        `
        SELECT id
        FROM drivers
        WHERE user_id = ?
        LIMIT 1
        `,
        [req.user.id]
      );


    if (drivers.length === 0) {
      return res.status(404).json({
        success: false,
        message:
          "Driver profile not found"
      });
    }


    const driverId =
      drivers[0].id;


    const [orders] =
      await pool.execute(
        `
        SELECT

          o.id,
          o.restaurant_id,

          r.name AS restaurant_name,
          r.address AS restaurant_address,
          r.latitude AS restaurant_latitude,
          r.longitude AS restaurant_longitude,

          o.customer_name,
          o.customer_phone,
          o.customer_address,
          o.customer_latitude,
          o.customer_longitude,

          o.food_amount,
          o.hadroug_fee,
          o.driver_fee,

          o.status,

          o.created_at,
          o.accepted_at,
          o.pickup_verified_at,
          o.picked_up_at,
          o.delivered_at,
          o.cancelled_at

        FROM orders o

        INNER JOIN restaurants r
          ON r.id = o.restaurant_id

        WHERE o.driver_id = ?

        ORDER BY o.created_at DESC
        `,
        [driverId]
      );


    return res.status(200).json({
      success: true,
      orders
    });

  } catch (error) {
    next(error);
  }
}


/* =========================================================
   UPDATE DRIVER ONLINE STATUS
========================================================= */

async function updateOnlineStatus(
  req,
  res,
  next
) {
  try {

    const {
      is_online
    } = req.body;


    if (
      typeof is_online !==
      "boolean"
    ) {
      return res.status(400).json({
        success: false,
        message:
          "is_online must be true or false"
      });
    }


    const [drivers] =
      await pool.execute(
        `
        SELECT
          id,
          is_available
        FROM drivers
        WHERE user_id = ?
        LIMIT 1
        `,
        [req.user.id]
      );


    if (drivers.length === 0) {
      return res.status(404).json({
        success: false,
        message:
          "Driver profile not found"
      });
    }


    const driverId =
      drivers[0].id;


    if (!is_online) {

      await pool.execute(
        `
        UPDATE drivers
        SET
          is_online = FALSE,
          is_available = FALSE
        WHERE id = ?
        `,
        [driverId]
      );

    } else {

      await pool.execute(
        `
        UPDATE drivers
        SET
          is_online = TRUE,
          is_available = TRUE
        WHERE id = ?
        `,
        [driverId]
      );
    }


    return res.status(200).json({
      success: true,
      message: is_online
        ? "Driver is now online"
        : "Driver is now offline"
    });

  } catch (error) {
    next(error);
  }
}


/* =========================================================
   UPDATE DRIVER LOCATION
========================================================= */

async function updateLocation(
  req,
  res,
  next
) {
  try {

    const {
      latitude,
      longitude,
      accuracy
    } = req.body;


    if (
      latitude === undefined ||
      longitude === undefined
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Latitude and longitude are required"
      });
    }


    const lat =
      Number(latitude);

    const lng =
      Number(longitude);

    const acc =
      accuracy !== undefined
        ? Number(accuracy)
        : null;


    if (
      Number.isNaN(lat) ||
      Number.isNaN(lng)
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Invalid location"
      });
    }


    if (
      lat < -90 ||
      lat > 90 ||
      lng < -180 ||
      lng > 180
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Invalid coordinates"
      });
    }


    const [drivers] =
      await pool.execute(
        `
        SELECT id
        FROM drivers
        WHERE user_id = ?
        LIMIT 1
        `,
        [req.user.id]
      );


    if (drivers.length === 0) {
      return res.status(404).json({
        success: false,
        message:
          "Driver profile not found"
      });
    }


    const driverId =
      drivers[0].id;


    await pool.execute(
      `
      INSERT INTO driver_locations (
        driver_id,
        latitude,
        longitude,
        accuracy,
        updated_at
      )
      VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)

      ON DUPLICATE KEY UPDATE

        latitude = VALUES(latitude),
        longitude = VALUES(longitude),
        accuracy = VALUES(accuracy),
        updated_at = CURRENT_TIMESTAMP
      `,
      [
        driverId,
        lat,
        lng,
        acc
      ]
    );


    return res.status(200).json({
      success: true,
      message:
        "Location updated"
    });

  } catch (error) {
    next(error);
  }
}


/* =========================================================
   ACCEPT ORDER OFFER
========================================================= */

async function acceptOrderOffer(
  req,
  res,
  next
) {
  const connection =
    await pool.getConnection();


  try {

    const {
      order_id
    } = req.body;


    if (!order_id) {
      return res.status(400).json({
        success: false,
        message:
          "order_id is required"
      });
    }


    await connection.beginTransaction();


    /* -------------------------------------------------------
       GET DRIVER
    ------------------------------------------------------- */

    const [drivers] =
      await connection.execute(
        `
        SELECT
          id,
          is_online,
          is_available,
          current_orders_count
        FROM drivers
        WHERE user_id = ?
        LIMIT 1
        FOR UPDATE
        `,
        [req.user.id]
      );


    if (drivers.length === 0) {

      await connection.rollback();

      return res.status(404).json({
        success: false,
        message:
          "Driver profile not found"
      });
    }


    const driver =
      drivers[0];

    const driverId =
      driver.id;


    /* -------------------------------------------------------
       DRIVER STATUS
    ------------------------------------------------------- */

    if (!driver.is_online) {

      await connection.rollback();

      return res.status(409).json({
        success: false,
        message:
          "Driver is offline"
      });
    }


    if (!driver.is_available) {

      await connection.rollback();

      return res.status(409).json({
        success: false,
        message:
          "Driver is not available"
      });
    }


    if (
      Number(
        driver.current_orders_count
      ) >= 1
    ) {

      await connection.rollback();

      return res.status(409).json({
        success: false,
        message:
          "Driver already has an active order"
      });
    }


    /* -------------------------------------------------------
       GET ORDER
    ------------------------------------------------------- */

    const [orders] =
      await connection.execute(
        `
        SELECT
          id,
          restaurant_id,
          status,
          current_offer_driver_id,
          offer_expires_at
        FROM orders
        WHERE id = ?
        LIMIT 1
        FOR UPDATE
        `,
        [order_id]
      );


    if (orders.length === 0) {

      await connection.rollback();

      return res.status(404).json({
        success: false,
        message:
          "Order not found"
      });
    }


    const order =
      orders[0];


    /* -------------------------------------------------------
       CHECK OFFER
    ------------------------------------------------------- */

    if (
      order.status !== "offered"
    ) {

      await connection.rollback();

      return res.status(409).json({
        success: false,
        message:
          "Order is no longer available"
      });
    }


    if (
      Number(
        order.current_offer_driver_id
      ) !== Number(driverId)
    ) {

      await connection.rollback();

      return res.status(403).json({
        success: false,
        message:
          "This order was not offered to you"
      });
    }


    if (
      !order.offer_expires_at ||
      new Date(
        order.offer_expires_at
      ).getTime() <= Date.now()
    ) {

      await connection.rollback();

      return res.status(409).json({
        success: false,
        message:
          "Order offer has expired"
      });
    }


    /* -------------------------------------------------------
       GENERATE OTP
    ------------------------------------------------------- */

    const otp =
      Math.floor(
        1000 +
        Math.random() * 9000
      ).toString();


    const otpHash =
      await bcrypt.hash(
        otp,
        10
      );


    const otpExpiresAt =
      new Date(
        Date.now() +
        30 * 60 * 1000
      );


    /* -------------------------------------------------------
       UPDATE ORDER
    ------------------------------------------------------- */

    await connection.execute(
      `
      UPDATE orders
      SET
        driver_id = ?,
        status = 'accepted',

        pickup_otp_hash = ?,
        pickup_otp_expires_at = ?,

        accepted_at = CURRENT_TIMESTAMP,

        current_offer_driver_id = NULL,
        offer_expires_at = NULL

      WHERE id = ?
      `,
      [
        driverId,
        otpHash,
        otpExpiresAt,
        order_id
      ]
    );


    /* -------------------------------------------------------
       UPDATE DRIVER
    ------------------------------------------------------- */

    await connection.execute(
      `
      UPDATE drivers
      SET
        current_orders_count =
          current_orders_count + 1,

        is_available = FALSE

      WHERE id = ?
      `,
      [driverId]
    );


    /* -------------------------------------------------------
       UPDATE OFFER
    ------------------------------------------------------- */

    await connection.execute(
      `
      UPDATE order_offers
      SET
        status = 'accepted',
        responded_at = CURRENT_TIMESTAMP

      WHERE
        order_id = ?
        AND driver_id = ?
        AND status = 'offered'

      ORDER BY id DESC

      LIMIT 1
      `,
      [
        order_id,
        driverId
      ]
    );


    /* -------------------------------------------------------
       EVENT
    ------------------------------------------------------- */

    await connection.execute(
      `
      INSERT INTO order_events (
        order_id,
        actor_user_id,
        event_type,
        old_status,
        new_status,
        description
      )
      VALUES (?, ?, ?, ?, ?, ?)
      `,
      [
        order_id,
        req.user.id,
        "order_accepted",
        "offered",
        "accepted",
        `Driver ${driverId} accepted the order`
      ]
    );


    await connection.commit();


    /* -------------------------------------------------------
       REAL-TIME NOTIFICATION
    ------------------------------------------------------- */

    try {

      await notifyDriverAccepted(
        order_id,
        driverId
      );

    } catch (notificationError) {

      console.error(
        "Driver accepted notification error:",
        notificationError
      );
    }


    return res.status(200).json({

      success: true,

      message:
        "Order accepted successfully",

      order_id,

      otp,

      otp_expires_at:
        otpExpiresAt
    });

  } catch (error) {

    try {
      await connection.rollback();
    } catch (_) {}

    next(error);

  } finally {

    connection.release();
  }
}


/* =========================================================
   REJECT ORDER OFFER
========================================================= */

async function rejectOrderOffer(
  req,
  res,
  next
) {
  const connection =
    await pool.getConnection();


  try {

    const {
      order_id
    } = req.body;


    if (!order_id) {
      return res.status(400).json({
        success: false,
        message:
          "order_id is required"
      });
    }


    await connection.beginTransaction();


    const [drivers] =
      await connection.execute(
        `
        SELECT id
        FROM drivers
        WHERE user_id = ?
        LIMIT 1
        FOR UPDATE
        `,
        [req.user.id]
      );


    if (drivers.length === 0) {

      await connection.rollback();

      return res.status(404).json({
        success: false,
        message:
          "Driver profile not found"
      });
    }


    const driverId =
      drivers[0].id;


    const [orders] =
      await connection.execute(
        `
        SELECT
          id,
          status,
          current_offer_driver_id
        FROM orders
        WHERE id = ?
        LIMIT 1
        FOR UPDATE
        `,
        [order_id]
      );


    if (orders.length === 0) {

      await connection.rollback();

      return res.status(404).json({
        success: false,
        message:
          "Order not found"
      });
    }


    const order =
      orders[0];


    if (
      order.status !== "offered"
    ) {

      await connection.rollback();

      return res.status(409).json({
        success: false,
        message:
          "Order is no longer available"
      });
    }


    if (
      Number(
        order.current_offer_driver_id
      ) !== Number(driverId)
    ) {

      await connection.rollback();

      return res.status(403).json({
        success: false,
        message:
          "This order was not offered to you"
      });
    }


    await connection.execute(
      `
      UPDATE order_offers
      SET
        status = 'rejected',
        responded_at = CURRENT_TIMESTAMP

      WHERE
        order_id = ?
        AND driver_id = ?
        AND status = 'offered'

      ORDER BY id DESC

      LIMIT 1
      `,
      [
        order_id,
        driverId
      ]
    );


    await connection.execute(
      `
      UPDATE orders
      SET
        status = 'dispatching',
        current_offer_driver_id = NULL,
        offer_expires_at = NULL

      WHERE id = ?
      `,
      [order_id]
    );


    await connection.execute(
      `
      INSERT INTO order_events (
        order_id,
        actor_user_id,
        event_type,
        old_status,
        new_status,
        description
      )
      VALUES (?, ?, ?, ?, ?, ?)
      `,
      [
        order_id,
        req.user.id,
        "driver_offer_rejected",
        "offered",
        "dispatching",
        `Driver ${driverId} rejected the order`
      ]
    );


    await connection.commit();


    /* -------------------------------------------------------
       SEND TO NEXT DRIVER
    ------------------------------------------------------- */

    let dispatchResult = null;

    try {

      dispatchResult =
        await sendOrderOffer(
          order_id
        );

    } catch (dispatchError) {

      console.error(
        "Redispatch error:",
        dispatchError
      );
    }


    return res.status(200).json({

      success: true,

      message:
        "Order rejected successfully",

      order_id,

      dispatch:
        dispatchResult
    });

  } catch (error) {

    try {
      await connection.rollback();
    } catch (_) {}

    next(error);

  } finally {

    connection.release();
  }
}


/* =========================================================
   DRIVER ARRIVED AT RESTAURANT
========================================================= */

async function arriveAtRestaurant(
  req,
  res,
  next
) {
  const connection =
    await pool.getConnection();


  try {

    const {
      order_id
    } = req.body;


    if (!order_id) {
      return res.status(400).json({
        success: false,
        message:
          "order_id is required"
      });
    }


    await connection.beginTransaction();


    const [drivers] =
      await connection.execute(
        `
        SELECT id
        FROM drivers
        WHERE user_id = ?
        LIMIT 1
        `,
        [req.user.id]
      );


    if (drivers.length === 0) {

      await connection.rollback();

      return res.status(404).json({
        success: false,
        message:
          "Driver profile not found"
      });
    }


    const driverId =
      drivers[0].id;


    const [orders] =
      await connection.execute(
        `
        SELECT
          id,
          driver_id,
          status
        FROM orders
        WHERE id = ?
        LIMIT 1
        FOR UPDATE
        `,
        [order_id]
      );


    if (orders.length === 0) {

      await connection.rollback();

      return res.status(404).json({
        success: false,
        message:
          "Order not found"
      });
    }


    const order =
      orders[0];


    if (
      Number(order.driver_id) !==
      Number(driverId)
    ) {

      await connection.rollback();

      return res.status(403).json({
        success: false,
        message:
          "This order is not assigned to you"
      });
    }


    if (
      order.status !== "accepted"
    ) {

      await connection.rollback();

      return res.status(409).json({
        success: false,
        message:
          "Order cannot be marked as arrived"
      });
    }


    await connection.execute(
      `
      UPDATE orders
      SET
        status = 'driver_arrived'

      WHERE id = ?
      `,
      [order_id]
    );


    await connection.execute(
      `
      INSERT INTO order_events (
        order_id,
        actor_user_id,
        event_type,
        old_status,
        new_status,
        description
      )
      VALUES (?, ?, ?, ?, ?, ?)
      `,
      [
        order_id,
        req.user.id,
        "driver_arrived",
        "accepted",
        "driver_arrived",
        `Driver ${driverId} arrived at restaurant`
      ]
    );


    await connection.commit();


    try {

      await notifyDriverArrived(
        order_id,
        driverId
      );

    } catch (notificationError) {

      console.error(
        "Driver arrived notification error:",
        notificationError
      );
    }


    return res.status(200).json({

      success: true,

      message:
        "Restaurant arrival recorded",

      order_id
    });

  } catch (error) {

    try {
      await connection.rollback();
    } catch (_) {}

    next(error);

  } finally {

    connection.release();
  }
}


/* =========================================================
   START DELIVERY
========================================================= */

async function startDelivery(
  req,
  res,
  next
) {
  const connection =
    await pool.getConnection();


  try {

    const {
      order_id
    } = req.body;


    if (!order_id) {
      return res.status(400).json({
        success: false,
        message:
          "order_id is required"
      });
    }


    await connection.beginTransaction();


    const [drivers] =
      await connection.execute(
        `
        SELECT id
        FROM drivers
        WHERE user_id = ?
        LIMIT 1
        `,
        [req.user.id]
      );


    if (drivers.length === 0) {

      await connection.rollback();

      return res.status(404).json({
        success: false,
        message:
          "Driver profile not found"
      });
    }


    const driverId =
      drivers[0].id;


    const [orders] =
      await connection.execute(
        `
        SELECT
          id,
          driver_id,
          status
        FROM orders
        WHERE id = ?
        LIMIT 1
        FOR UPDATE
        `,
        [order_id]
      );


    if (orders.length === 0) {

      await connection.rollback();

      return res.status(404).json({
        success: false,
        message:
          "Order not found"
      });
    }


    const order =
      orders[0];


    if (
      Number(order.driver_id) !==
      Number(driverId)
    ) {

      await connection.rollback();

      return res.status(403).json({
        success: false,
        message:
          "This order is not assigned to you"
      });
    }


    if (
      order.status !== "picked_up"
    ) {

      await connection.rollback();

      return res.status(409).json({
        success: false,
        message:
          "Pickup must be verified first"
      });
    }


    await connection.execute(
      `
      UPDATE orders
      SET
        status = 'delivering'

      WHERE id = ?
      `,
      [order_id]
    );


    await connection.execute(
      `
      INSERT INTO order_events (
        order_id,
        actor_user_id,
        event_type,
        old_status,
        new_status,
        description
      )
      VALUES (?, ?, ?, ?, ?, ?)
      `,
      [
        order_id,
        req.user.id,
        "delivery_started",
        "picked_up",
        "delivering",
        `Driver ${driverId} started delivery`
      ]
    );


    await connection.commit();


    try {

      await notifyDeliveryStarted(
        order_id,
        driverId
      );

    } catch (notificationError) {

      console.error(
        "Delivery started notification error:",
        notificationError
      );
    }


    return res.status(200).json({

      success: true,

      message:
        "Delivery started",

      order_id
    });

  } catch (error) {

    try {
      await connection.rollback();
    } catch (_) {}

    next(error);

  } finally {

    connection.release();
  }
}


/* =========================================================
   COMPLETE DELIVERY
========================================================= */

async function completeDelivery(
  req,
  res,
  next
) {
  const connection =
    await pool.getConnection();


  try {

    const {
      order_id
    } = req.body;


    if (!order_id) {
      return res.status(400).json({
        success: false,
        message:
          "order_id is required"
      });
    }


    await connection.beginTransaction();


    const [drivers] =
      await connection.execute(
        `
        SELECT id
        FROM drivers
        WHERE user_id = ?
        LIMIT 1
        FOR UPDATE
        `,
        [req.user.id]
      );


    if (drivers.length === 0) {

      await connection.rollback();

      return res.status(404).json({
        success: false,
        message:
          "Driver profile not found"
      });
    }


    const driverId =
      drivers[0].id;


    const [orders] =
      await connection.execute(
        `
        SELECT
          id,
          driver_id,
          restaurant_id,
          status,
          driver_fee
        FROM orders
        WHERE id = ?
        LIMIT 1
        FOR UPDATE
        `,
        [order_id]
      );


    if (orders.length === 0) {

      await connection.rollback();

      return res.status(404).json({
        success: false,
        message:
          "Order not found"
      });
    }


    const order =
      orders[0];


    if (
      Number(order.driver_id) !==
      Number(driverId)
    ) {

      await connection.rollback();

      return res.status(403).json({
        success: false,
        message:
          "This order is not assigned to you"
      });
    }


    if (
      order.status !== "delivering"
    ) {

      await connection.rollback();

      return res.status(409).json({
        success: false,
        message:
          "Order is not currently being delivered"
      });
    }


    await connection.execute(
      `
      UPDATE orders
      SET
        status = 'delivered',
        delivered_at = CURRENT_TIMESTAMP

      WHERE id = ?
      `,
      [order_id]
    );


    await connection.execute(
      `
      UPDATE drivers
      SET
        current_orders_count =
          GREATEST(
            current_orders_count - 1,
            0
          ),

        total_completed_orders =
          total_completed_orders + 1,

        is_available = TRUE

      WHERE id = ?
      `,
      [driverId]
    );


    await connection.execute(
      `
      INSERT INTO transactions (
        order_id,
        restaurant_id,
        driver_id,
        type,
        amount,
        description
      )
      VALUES (?, ?, ?, 'driver_income', ?, ?)
      `,
      [
        order_id,
        order.restaurant_id,
        driverId,
        Number(order.driver_fee || 0),
        "Driver delivery income"
      ]
    );


    await connection.execute(
      `
      INSERT INTO order_events (
        order_id,
        actor_user_id,
        event_type,
        old_status,
        new_status,
        description
      )
      VALUES (?, ?, ?, ?, ?, ?)
      `,
      [
        order_id,
        req.user.id,
        "order_delivered",
        "delivering",
        "delivered",
        `Driver ${driverId} completed delivery`
      ]
    );


    await connection.commit();


    try {

      await notifyOrderDelivered(
        order_id,
        driverId
      );

    } catch (notificationError) {

      console.error(
        "Order delivered notification error:",
        notificationError
      );
    }


    return res.status(200).json({

      success: true,

      message:
        "Order delivered successfully",

      order_id
    });

  } catch (error) {

    try {
      await connection.rollback();
    } catch (_) {}

    next(error);

  } finally {

    connection.release();
  }
}


/* =========================================================
   EXPORTS
========================================================= */

module.exports = {

  getProfile,

  getOrders,

  updateOnlineStatus,

  updateLocation,

  acceptOrderOffer,

  rejectOrderOffer,

  arriveAtRestaurant,

  startDelivery,

  completeDelivery

};
