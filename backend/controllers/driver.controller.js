const pool = require("../config/database");

const {
  sendOrderOffer
} = require("../services/dispatch.service");


/* =========================================================
   GET DRIVER PROFILE
========================================================= */

async function getProfile(req, res, next) {
  try {
    const [rows] = await pool.execute(
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
        u.full_name,
        u.phone AS user_phone,
        u.email
      FROM drivers d
      INNER JOIN users u
        ON u.id = d.user_id
      WHERE d.user_id = ?
      LIMIT 1
      `,
      [req.user.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Driver profile not found"
      });
    }

    const driver = rows[0];

    return res.status(200).json({
      success: true,
      driver
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
    const [drivers] = await pool.execute(
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
        message: "Driver profile not found"
      });
    }

    const driverId = drivers[0].id;

    const [orders] = await pool.execute(
      `
      SELECT
        o.id,
        o.restaurant_id,
        o.driver_id,

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
        o.picked_up_at,
        o.delivered_at,
        o.cancelled_at,

        r.name AS restaurant_name,
        r.address AS restaurant_address,
        r.latitude AS restaurant_latitude,
        r.longitude AS restaurant_longitude

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
   UPDATE ONLINE STATUS
========================================================= */

async function updateOnlineStatus(req, res, next) {
  try {
    const { is_online } = req.body;

    if (
      typeof is_online !== "boolean" &&
      is_online !== 0 &&
      is_online !== 1
    ) {
      return res.status(400).json({
        success: false,
        message: "is_online must be boolean"
      });
    }

    const online =
      is_online === true ||
      is_online === 1;

    const [result] = await pool.execute(
      `
      UPDATE drivers
      SET
        is_online = ?,
        is_available = ?
      WHERE user_id = ?
      `,
      [
        online,
        online,
        req.user.id
      ]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: "Driver profile not found"
      });
    }

    return res.status(200).json({
      success: true,
      message: online
        ? "Driver is now online"
        : "Driver is now offline",
      is_online: online
    });

  } catch (error) {
    next(error);
  }
}


/* =========================================================
   UPDATE DRIVER LOCATION
========================================================= */

async function updateLocation(req, res, next) {
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

    const lat = Number(latitude);
    const lon = Number(longitude);

    const acc =
      accuracy === undefined
        ? null
        : Number(accuracy);

    if (
      !Number.isFinite(lat) ||
      !Number.isFinite(lon) ||
      lat < -90 ||
      lat > 90 ||
      lon < -180 ||
      lon > 180
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid GPS coordinates"
      });
    }

    if (
      accuracy !== undefined &&
      (!Number.isFinite(acc) || acc < 0)
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid GPS accuracy"
      });
    }

    const [drivers] = await pool.execute(
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
        message: "Driver profile not found"
      });
    }

    const driverId = drivers[0].id;

    await pool.execute(
      `
      INSERT INTO driver_locations (
        driver_id,
        latitude,
        longitude,
        accuracy
      )
      VALUES (?, ?, ?, ?)

      ON DUPLICATE KEY UPDATE
        latitude = VALUES(latitude),
        longitude = VALUES(longitude),
        accuracy = VALUES(accuracy),
        updated_at = CURRENT_TIMESTAMP
      `,
      [
        driverId,
        lat,
        lon,
        acc
      ]
    );

    return res.status(200).json({
      success: true,
      message:
        "Location updated successfully"
    });

  } catch (error) {
    next(error);
  }
}


/* =========================================================
   ACCEPT ORDER OFFER
========================================================= */

async function acceptOrderOffer(req, res, next) {
  const connection =
    await pool.getConnection();

  try {
    const { order_id } = req.body;

    if (!order_id) {
      return res.status(400).json({
        success: false,
        message: "order_id is required"
      });
    }

    const [drivers] =
      await connection.execute(
        `
        SELECT
          id,
          current_orders_count,
          is_online,
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
        message: "Driver profile not found"
      });
    }

    const driver = drivers[0];
    const driverId = driver.id;

    await connection.beginTransaction();

    const [orders] =
      await connection.execute(
        `
        SELECT
          id,
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
        message: "Order not found"
      });
    }

    const order = orders[0];

    if (order.status !== "offered") {
      await connection.rollback();

      return res.status(409).json({
        success: false,
        message:
          "This order is no longer available"
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
      new Date(order.offer_expires_at)
        .getTime() <= Date.now()
    ) {
      await connection.rollback();

      return res.status(409).json({
        success: false,
        message:
          "The offer has expired"
      });
    }

    await connection.execute(
      `
      UPDATE orders
      SET
        status = 'accepted',
        driver_id = ?,
        current_offer_driver_id = NULL,
        offer_expires_at = NULL,
        accepted_at = CURRENT_TIMESTAMP
      WHERE id = ?
      `,
      [
        driverId,
        order_id
      ]
    );

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

    await connection.execute(
      `
      INSERT INTO order_events (
        order_id,
        event_type,
        old_status,
        new_status,
        description
      )
      VALUES (?, ?, ?, ?, ?)
      `,
      [
        order_id,
        "order_accepted",
        "offered",
        "accepted",
        `Driver ${driverId} accepted order`
      ]
    );

    await connection.commit();

    return res.status(200).json({
      success: true,
      message: "Order accepted successfully",
      order_id: order_id
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

async function rejectOrderOffer(req, res, next) {
  try {
    const { order_id } = req.body;

    if (!order_id) {
      return res.status(400).json({
        success: false,
        message: "order_id is required"
      });
    }

    const [drivers] = await pool.execute(
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
        message: "Driver profile not found"
      });
    }

    const driverId = drivers[0].id;

    const connection =
      await pool.getConnection();

    try {
      await connection.beginTransaction();

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
          message: "Order not found"
        });
      }

      const order = orders[0];

      if (
        order.status !== "offered" ||
        Number(
          order.current_offer_driver_id
        ) !== Number(driverId)
      ) {
        await connection.rollback();

        return res.status(409).json({
          success: false,
          message:
            "This offer is no longer available"
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
          event_type,
          old_status,
          new_status,
          description
        )
        VALUES (?, ?, ?, ?, ?)
        `,
        [
          order_id,
          "driver_offer_rejected",
          "offered",
          "dispatching",
          `Driver ${driverId} rejected order`
        ]
      );

      await connection.commit();

    } catch (error) {
      await connection.rollback();
      throw error;

    } finally {
      connection.release();
    }

    /* Send the order to the next driver */
    try {
      await sendOrderOffer(order_id);
    } catch (error) {
      console.error(
        `Failed to dispatch rejected order ${order_id}:`,
        error
      );
    }

    return res.status(200).json({
      success: true,
      message: "Order rejected successfully"
    });

  } catch (error) {
    next(error);
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
  rejectOrderOffer
};
