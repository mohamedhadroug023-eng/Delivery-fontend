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
        food_amount,
        hadroug_fee,
        driver_fee,
        status,
        driver_id,
        created_at,
        accepted_at,
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
// EXPORTS
// =========================================================

module.exports = {
  getProfile,
  getOrders
};
