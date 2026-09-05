const bcrypt = require("bcrypt");

const pool = require("../config/database");


// =========================================================
// GET RESTAURANT PROFILE
// =========================================================

async function getProfile(req, res, next) {
  try {
    const [restaurants] = await pool.execute(
      `
      SELECT
        r.id,
        r.name,
        r.address,
        r.latitude,
        r.longitude,
        r.balance_due,
        r.is_active,
        r.created_at
      FROM restaurants r
      WHERE r.user_id = ?
      LIMIT 1
      `,
      [req.user.id]
    );

    if (restaurants.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Restaurant profile not found"
      });
    }

    return res.status(200).json({
      success: true,
      restaurant: restaurants[0]
    });

  } catch (error) {
    next(error);
  }
}


// =========================================================
// GET RESTAURANT ORDERS
// =========================================================

async function getOrders(req, res, next) {
  try {
    const [restaurants] = await pool.execute(
      `
      SELECT id
      FROM restaurants
      WHERE user_id = ?
      LIMIT 1
      `,
      [req.user.id]
    );

    if (restaurants.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Restaurant profile not found"
      });
    }

    const restaurantId = restaurants[0].id;

    const [orders] = await pool.execute(
      `
      SELECT
        id,
        customer_name,
        customer_phone,
        customer_address,
        customer_latitude,
        customer_longitude,
        food_amount,
        hadroug_fee,
        driver_fee,
        status,
        driver_id,
        created_at,
        accepted_at,
        pickup_verified_at,
        picked_up_at,
        delivered_at,
        cancelled_at
      FROM orders
      WHERE restaurant_id = ?
      ORDER BY created_at DESC
      `,
      [restaurantId]
    );

    return res.status(200).json({
      success: true,
      orders
    });

  } catch (error) {
    next(error);
  }
}


// =========================================================
// VERIFY PICKUP OTP
// =========================================================

async function verifyPickupOtp(req, res, next) {
  const connection = await pool.getConnection();

  try {
    const {
      order_id,
      otp
    } = req.body;

    // -----------------------------------------------------
    // VALIDATION
    // -----------------------------------------------------

    if (!order_id || otp === undefined) {
      return res.status(400).json({
        success: false,
        message: "order_id and otp are required"
      });
    }

    const cleanOtp = String(otp).trim();

    if (!/^\d{4}$/.test(cleanOtp)) {
      return res.status(400).json({
        success: false,
        message: "OTP must contain exactly 4 digits"
      });
    }

    await connection.beginTransaction();

    // -----------------------------------------------------
    // GET RESTAURANT
    // -----------------------------------------------------

    const [restaurants] =
      await connection.execute(
        `
        SELECT
          id,
          is_active
        FROM restaurants
        WHERE user_id = ?
        LIMIT 1
        FOR UPDATE
        `,
        [req.user.id]
      );

    if (restaurants.length === 0) {
      await connection.rollback();

      return res.status(404).json({
        success: false,
        message: "Restaurant profile not found"
      });
    }

    const restaurant = restaurants[0];

    if (!restaurant.is_active) {
      await connection.rollback();

      return res.status(403).json({
        success: false,
        message: "Restaurant account is inactive"
      });
    }

    const restaurantId = restaurant.id;

    // -----------------------------------------------------
    // GET ORDER
    // -----------------------------------------------------

    const [orders] =
      await connection.execute(
        `
        SELECT
          id,
          restaurant_id,
          driver_id,
          status,
          pickup_otp_hash,
          pickup_otp_expires_at
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

    // -----------------------------------------------------
    // CHECK RESTAURANT OWNERSHIP
    // -----------------------------------------------------

    if (
      Number(order.restaurant_id) !==
      Number(restaurantId)
    ) {
      await connection.rollback();

      return res.status(403).json({
        success: false,
        message:
          "This order does not belong to your restaurant"
      });
    }

    // -----------------------------------------------------
    // CHECK STATUS
    // -----------------------------------------------------

    if (order.status !== "driver_arrived") {
      await connection.rollback();

      return res.status(409).json({
        success: false,
        message:
          "Driver must arrive at the restaurant first"
      });
    }

    // -----------------------------------------------------
    // CHECK OTP EXISTENCE
    // -----------------------------------------------------

    if (!order.pickup_otp_hash) {
      await connection.rollback();

      return res.status(409).json({
        success: false,
        message:
          "Pickup OTP is not available"
      });
    }

    // -----------------------------------------------------
    // CHECK OTP EXPIRATION
    // -----------------------------------------------------

    if (
      !order.pickup_otp_expires_at ||
      new Date(
        order.pickup_otp_expires_at
      ).getTime() <= Date.now()
    ) {
      await connection.rollback();

      return res.status(409).json({
        success: false,
        message:
          "Pickup OTP has expired"
      });
    }

    // -----------------------------------------------------
    // VERIFY OTP
    // -----------------------------------------------------

    const validOtp =
      await bcrypt.compare(
        cleanOtp,
        order.pickup_otp_hash
      );

    if (!validOtp) {
      await connection.rollback();

      return res.status(401).json({
        success: false,
        message: "Invalid OTP"
      });
    }

    // -----------------------------------------------------
    // MARK ORDER AS PICKED UP
    // -----------------------------------------------------

    await connection.execute(
      `
      UPDATE orders
      SET
        status = 'picked_up',
        pickup_verified_at = CURRENT_TIMESTAMP,
        picked_up_at = CURRENT_TIMESTAMP
      WHERE id = ?
      `,
      [order_id]
    );

    // -----------------------------------------------------
    // ORDER EVENT
    // -----------------------------------------------------

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
        "pickup_verified",
        "driver_arrived",
        "picked_up",
        "Pickup verified successfully using OTP"
      ]
    );

    await connection.commit();

    // -----------------------------------------------------
    // SUCCESS
    // -----------------------------------------------------

    return res.status(200).json({
      success: true,
      message:
        "Pickup verified successfully",
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


// =========================================================
// EXPORTS
// =========================================================

module.exports = {
  getProfile,
  getOrders,
  verifyPickupOtp
};
