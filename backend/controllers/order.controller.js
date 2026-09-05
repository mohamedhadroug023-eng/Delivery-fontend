const pool = require("../config/database");

const {
  sendOrderOffer
} = require("../services/dispatch.service");

// =========================================================
// CREATE DELIVERY ORDER
// =========================================================

async function createOrder(req, res, next) {
  const connection = await pool.getConnection();

  try {
    const {
      customer_name,
      customer_phone,
      customer_address,
      customer_latitude,
      customer_longitude,
      food_amount,
      driver_fee
    } = req.body;

    // -------------------------------------------------------
    // VALIDATION
    // -------------------------------------------------------

    if (
      !customer_address ||
      customer_latitude === undefined ||
      customer_longitude === undefined ||
      food_amount === undefined
    ) {
      return res.status(400).json({
        success: false,
        message: "Required order information is missing"
      });
    }

    if (
      Number.isNaN(Number(customer_latitude)) ||
      Number.isNaN(Number(customer_longitude)) ||
      Number.isNaN(Number(food_amount)) ||
      Number(food_amount) <= 0
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid order data"
      });
    }

    if (
      driver_fee !== undefined &&
      (
        Number.isNaN(Number(driver_fee)) ||
        Number(driver_fee) < 0
      )
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid driver fee"
      });
    }

    // -------------------------------------------------------
    // START TRANSACTION
    // -------------------------------------------------------

    await connection.beginTransaction();

    // -------------------------------------------------------
    // FIND RESTAURANT
    // -------------------------------------------------------

    const [restaurants] = await connection.execute(
      `
      SELECT id, is_active
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

    // -------------------------------------------------------
    // CREATE ORDER
    // -------------------------------------------------------

    const hadrougFee = 1.000;
    const driverFee = Number(driver_fee || 0);

    const [result] = await connection.execute(
      `
      INSERT INTO orders (
        restaurant_id,
        customer_name,
        customer_phone,
        customer_address,
        customer_latitude,
        customer_longitude,
        food_amount,
        hadroug_fee,
        driver_fee,
        status
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
      `,
      [
        restaurant.id,
        customer_name || null,
        customer_phone || null,
        customer_address,
        Number(customer_latitude),
        Number(customer_longitude),
        Number(food_amount),
        hadrougFee,
        driverFee
      ]
    );

    // -------------------------------------------------------
    // ADD 1 TND TO RESTAURANT BALANCE
    // -------------------------------------------------------

    await connection.execute(
      `
      UPDATE restaurants
      SET balance_due = balance_due + ?
      WHERE id = ?
      `,
      [
        hadrougFee,
        restaurant.id
      ]
    );

    // -------------------------------------------------------
    // CREATE TRANSACTION RECORD
    // -------------------------------------------------------

    await connection.execute(
      `
      INSERT INTO transactions (
        order_id,
        restaurant_id,
        type,
        amount,
        description
      )
      VALUES (?, ?, 'restaurant_fee', ?, ?)
      `,
      [
        result.insertId,
        restaurant.id,
        hadrougFee,
        "HADROUG DELIVERY order fee"
      ]
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
        result.insertId,
        req.user.id,
        "order_created",
        null,
        "pending",
        "Order created by restaurant"
      ]
    );

    // -------------------------------------------------------
    // COMMIT DATABASE TRANSACTION
    // -------------------------------------------------------

    await connection.commit();

    // -------------------------------------------------------
    // START DRIVER DISPATCH
    // -------------------------------------------------------

    const dispatchResult = await sendOrderOffer(
      result.insertId
    );

    // -------------------------------------------------------
    // RESPONSE
    // -------------------------------------------------------

    return res.status(201).json({
      success: true,
      message: "Order created successfully",
      order_id: result.insertId,
      dispatch: dispatchResult
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
// EXPORTS
// =========================================================

module.exports = {
  createOrder
};
