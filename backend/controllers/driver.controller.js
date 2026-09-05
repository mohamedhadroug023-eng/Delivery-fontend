const pool = require("../config/database");

// =========================================================
// GET DRIVER PROFILE
// =========================================================

async function getProfile(req, res, next) {
  try {
    const [drivers] = await pool.execute(
      `
      SELECT
        d.id,
        d.phone,
        d.vehicle_type,
        d.is_online,
        d.is_available,
        d.current_orders_count,
        d.total_completed_orders,
        d.created_at
      FROM drivers d
      WHERE d.user_id = ?
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

    return res.status(200).json({
      success: true,
      driver: drivers[0]
    });

  } catch (error) {
    next(error);
  }
}

// =========================================================
// UPDATE DRIVER ONLINE STATUS
// =========================================================

async function updateOnlineStatus(req, res, next) {
  try {
    const { is_online } = req.body;

    if (typeof is_online !== "boolean") {
      return res.status(400).json({
        success: false,
        message: "is_online must be a boolean"
      });
    }

    const [result] = await pool.execute(
      `
      UPDATE drivers
      SET
        is_online = ?,
        is_available = ?
      WHERE user_id = ?
      `,
      [
        is_online,
        is_online,
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
      message: is_online
        ? "Driver is now online"
        : "Driver is now offline"
    });

  } catch (error) {
    next(error);
  }
}

// =========================================================
// UPDATE DRIVER LOCATION
// =========================================================

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
        message: "Latitude and longitude are required"
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
      message: "Location updated successfully"
    });

  } catch (error) {
    next(error);
  }
}

// =========================================================
// ACCEPT ORDER OFFER
// =========================================================

async function acceptOrderOffer(req, res, next) {
  const connection = await pool.getConnection();

  try {
    const { order_id } = req.body;

    if (!order_id) {
      return res.status(400).json({
        success: false,
        message: "order_id is required"
      });
    }

    await connection.beginTransaction();

    // -------------------------------------------------------
    // GET DRIVER
    // -------------------------------------------------------

    const [drivers] = await connection.execute(
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
        message: "Driver profile not found"
      });
    }

    const driverId = drivers[0].id;

    // -------------------------------------------------------
    // LOCK ORDER
    // -------------------------------------------------------

    const [orders] = await connection.execute(
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

    // -------------------------------------------------------
    // VERIFY OFFER OWNER
    // -------------------------------------------------------

    if (
      order.status !== "offered" ||
      Number(order.current_offer_driver_id) !== Number(driverId)
    ) {
      await connection.rollback();

      return res.status(409).json({
        success: false,
        message: "This order is no longer offered to you"
      });
    }

    // -------------------------------------------------------
    // VERIFY OFFER EXPIRATION
    // -------------------------------------------------------

    if (
      !order.offer_expires_at ||
      new Date(order.offer_expires_at).getTime() <= Date.now()
    ) {
      await connection.rollback();

      return res.status(409).json({
        success: false,
        message: "This offer has expired"
      });
    }

    // -------------------------------------------------------
    // ACCEPT ORDER
    // -------------------------------------------------------

    const [updateResult] = await connection.execute(
      `
      UPDATE orders
      SET
        driver_id = ?,
        status = 'accepted',
        current_offer_driver_id = NULL,
        offer_expires_at = NULL,
        accepted_at = CURRENT_TIMESTAMP
      WHERE
        id = ?
        AND status = 'offered'
        AND current_offer_driver_id = ?
      `,
      [
        driverId,
        order_id,
        driverId
      ]
    );

    if (updateResult.affectedRows === 0) {
      await connection.rollback();

      return res.status(409).json({
        success: false,
        message: "Order could not be accepted"
      });
    }

    // -------------------------------------------------------
    // UPDATE OFFER HISTORY
    // -------------------------------------------------------

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

    // -------------------------------------------------------
    // UPDATE DRIVER
    // -------------------------------------------------------

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

    // -------------------------------------------------------
    // ORDER EVENT
    // -------------------------------------------------------

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

    return res.status(200).json({
      success: true,
      message: "Order accepted successfully",
      order_id: Number(order_id)
    });

  } catch (error) {

    try {
      await connection.rollback();
    } catch (rollbackError) {
      console.error(
        "Rollback error:",
        rollbackError
      );
    }

    next(error);

  } finally {
    connection.release();
  }
}

// =========================================================
// REJECT ORDER OFFER
// =========================================================

async function rejectOrderOffer(req, res, next) {
  try {

    const { order_id } = req.body;

    if (!order_id) {
      return res.status(400).json({
        success: false,
        message: "order_id is required"
      });
    }

    // -------------------------------------------------------
    // GET DRIVER
    // -------------------------------------------------------

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

    // -------------------------------------------------------
    // GET ORDER
    // -------------------------------------------------------

    const [orders] = await pool.execute(
      `
      SELECT
        id,
        status,
        current_offer_driver_id
      FROM orders
      WHERE id = ?
      LIMIT 1
      `,
      [order_id]
    );

    if (orders.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Order not found"
      });
    }

    const order = orders[0];

    // -------------------------------------------------------
    // VERIFY OFFER
    // -------------------------------------------------------

    if (
      order.status !== "offered" ||
      Number(order.current_offer_driver_id) !== Number(driverId)
    ) {
      return res.status(409).json({
        success: false,
        message: "This order is no longer offered to you"
      });
    }

    // -------------------------------------------------------
    // MARK OFFER AS REJECTED
    // -------------------------------------------------------

    await pool.execute(
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

    // -------------------------------------------------------
    // RETURN ORDER TO DISPATCHING
    // -------------------------------------------------------

    await pool.execute(
      `
      UPDATE orders
      SET
        status = 'dispatching',
        current_offer_driver_id = NULL,
        offer_expires_at = NULL
      WHERE
        id = ?
        AND status = 'offered'
        AND current_offer_driver_id = ?
      `,
      [
        order_id,
        driverId
      ]
    );

    // -------------------------------------------------------
    // ORDER EVENT
    // -------------------------------------------------------

    await pool.execute(
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
        "order_rejected",
        "offered",
        "dispatching",
        `Driver ${driverId} rejected the order`
      ]
    );

    return res.status(200).json({
      success: true,
      message: "Order rejected successfully",
      order_id: Number(order_id)
    });

  } catch (error) {
    next(error);
  }
}

// =========================================================
// EXPORTS
// =========================================================

module.exports = {
  getProfile,
  updateOnlineStatus,
  updateLocation,
  acceptOrderOffer,
  rejectOrderOffer
};
