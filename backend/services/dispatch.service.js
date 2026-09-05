const pool = require("../config/database");
const { calculateDistance } = require("./location.service");

// =========================================================
// DISPATCH CONFIGURATION
// =========================================================

const MAX_DISTANCE_KM = 2.5;
const OFFER_DURATION_SECONDS = 20;

// =========================================================
// FIND NEAREST AVAILABLE DRIVER
// =========================================================

async function findNearestDriver(orderId) {
  const [orders] = await pool.execute(
    `
    SELECT
      id,
      restaurant_id,
      status
    FROM orders
    WHERE id = ?
    LIMIT 1
    `,
    [orderId]
  );

  if (orders.length === 0) {
    throw new Error("Order not found");
  }

  const order = orders[0];

  if (order.status !== "pending" && order.status !== "dispatching") {
    return null;
  }

  // -------------------------------------------------------
  // GET RESTAURANT LOCATION
  // -------------------------------------------------------

  const [restaurants] = await pool.execute(
    `
    SELECT latitude, longitude
    FROM restaurants
    WHERE id = ?
    LIMIT 1
    `,
    [order.restaurant_id]
  );

  if (restaurants.length === 0) {
    throw new Error("Restaurant not found");
  }

  const restaurant = restaurants[0];

  // -------------------------------------------------------
  // GET AVAILABLE DRIVERS
  // -------------------------------------------------------

  const [drivers] = await pool.execute(
    `
    SELECT
      d.id,
      d.current_orders_count,
      dl.latitude,
      dl.longitude
    FROM drivers d
    INNER JOIN driver_locations dl
      ON dl.driver_id = d.id
    WHERE
      d.is_online = TRUE
      AND d.is_available = TRUE
      AND d.current_orders_count = 0
    `
  );

  if (drivers.length === 0) {
    return null;
  }

  // -------------------------------------------------------
  // CALCULATE DISTANCES
  // -------------------------------------------------------

  const driversWithDistance = drivers
    .map((driver) => ({
      ...driver,
      distance: calculateDistance(
        restaurant.latitude,
        restaurant.longitude,
        driver.latitude,
        driver.longitude
      )
    }))
    .filter(
      (driver) => driver.distance <= MAX_DISTANCE_KM
    )
    .sort(
      (a, b) => a.distance - b.distance
    );

  if (driversWithDistance.length === 0) {
    return null;
  }

  return driversWithDistance[0];
}

// =========================================================
// SEND ORDER OFFER
// =========================================================

async function sendOrderOffer(orderId) {
  const driver = await findNearestDriver(orderId);

  if (!driver) {
    return {
      success: false,
      message: "No available driver found"
    };
  }

  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const expiresAt = new Date(
      Date.now() +
      OFFER_DURATION_SECONDS * 1000
    );

    // -----------------------------------------------------
    // UPDATE ORDER
    // -----------------------------------------------------

    const [result] = await connection.execute(
      `
      UPDATE orders
      SET
        status = 'offered',
        current_offer_driver_id = ?,
        offer_expires_at = ?
      WHERE
        id = ?
        AND status IN ('pending', 'dispatching')
        AND current_offer_driver_id IS NULL
      `,
      [
        driver.id,
        expiresAt,
        orderId
      ]
    );

    if (result.affectedRows === 0) {
      await connection.rollback();

      return {
        success: false,
        message: "Order is no longer available"
      };
    }

    // -----------------------------------------------------
    // CREATE OFFER RECORD
    // -----------------------------------------------------

    await connection.execute(
      `
      INSERT INTO order_offers (
        order_id,
        driver_id,
        distance_to_restaurant,
        expires_at,
        status
      )
      VALUES (?, ?, ?, ?, 'offered')
      `,
      [
        orderId,
        driver.id,
        driver.distance,
        expiresAt
      ]
    );

    // -----------------------------------------------------
    // ORDER EVENT
    // -----------------------------------------------------

    await connection.execute(
      `
      INSERT INTO order_events (
        order_id,
        event_type,
        new_status,
        description
      )
      VALUES (?, ?, ?, ?)
      `,
      [
        orderId,
        "driver_offer_sent",
        "offered",
        `Order offered to driver ${driver.id}`
      ]
    );

    await connection.commit();

    return {
      success: true,
      driverId: driver.id,
      expiresAt
    };

  } catch (error) {
    await connection.rollback();
    throw error;

  } finally {
    connection.release();
  }
}

module.exports = {
  findNearestDriver,
  sendOrderOffer
};
