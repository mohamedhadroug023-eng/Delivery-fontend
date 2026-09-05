const pool = require("../config/database");

// =========================================================
// ADMIN DASHBOARD
// =========================================================

async function getDashboard(req, res, next) {
  try {
    // عدد المطاعم
    const [restaurantCount] = await pool.execute(
      `
      SELECT COUNT(*) AS total
      FROM restaurants
      WHERE is_active = TRUE
      `
    );

    // عدد السائقين
    const [driverCount] = await pool.execute(
      `
      SELECT COUNT(*) AS total
      FROM drivers
      `
    );

    // السائقون المتصلون
    const [onlineDriverCount] = await pool.execute(
      `
      SELECT COUNT(*) AS total
      FROM drivers
      WHERE is_online = TRUE
      `
    );

    // طلبات اليوم
    const [todayOrders] = await pool.execute(
      `
      SELECT COUNT(*) AS total
      FROM orders
      WHERE DATE(created_at) = CURDATE()
      `
    );

    // دخل HADROUG اليوم
    const [todayRevenue] = await pool.execute(
      `
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE type = 'restaurant_fee'
        AND DATE(created_at) = CURDATE()
      `
    );

    // إجمالي المبالغ المستحقة على المطاعم
    const [balanceDue] = await pool.execute(
      `
      SELECT COALESCE(SUM(balance_due), 0) AS total
      FROM restaurants
      WHERE is_active = TRUE
      `
    );

    // الطلبات النشطة
    const [activeOrders] = await pool.execute(
      `
      SELECT
        o.id,
        o.restaurant_id,
        r.name AS restaurant_name,
        o.driver_id,
        u.full_name AS driver_name,
        o.customer_name,
        o.customer_phone,
        o.customer_address,
        o.customer_latitude,
        o.customer_longitude,
        o.food_amount,
        o.driver_fee,
        o.hadroug_fee,
        o.status,
        o.created_at,
        o.accepted_at,
        o.picked_up_at
      FROM orders o
      INNER JOIN restaurants r
        ON r.id = o.restaurant_id
      LEFT JOIN drivers d
        ON d.id = o.driver_id
      LEFT JOIN users u
        ON u.id = d.user_id
      WHERE o.status IN (
        'pending',
        'dispatching',
        'offered',
        'accepted',
        'driver_arrived',
        'pickup_verified',
        'picked_up',
        'delivering'
      )
      ORDER BY o.created_at DESC
      `
    );

    return res.status(200).json({
      success: true,

      statistics: {
        restaurants:
          Number(restaurantCount[0].total),

        drivers:
          Number(driverCount[0].total),

        online_drivers:
          Number(onlineDriverCount[0].total),

        today_orders:
          Number(todayOrders[0].total),

        today_revenue:
          Number(todayRevenue[0].total),

        total_balance_due:
          Number(balanceDue[0].total),

        active_orders:
          activeOrders.length
      },

      active_orders: activeOrders
    });

  } catch (error) {
    next(error);
  }
}


// =========================================================
// GET RESTAURANTS
// =========================================================

async function getRestaurants(req, res, next) {
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
        r.created_at,
        u.full_name,
        u.phone,
        u.email
      FROM restaurants r
      INNER JOIN users u
        ON u.id = r.user_id
      ORDER BY r.created_at DESC
      `
    );

    return res.status(200).json({
      success: true,
      restaurants
    });

  } catch (error) {
    next(error);
  }
}


// =========================================================
// GET DRIVERS
// =========================================================

async function getDrivers(req, res, next) {
  try {
    const [drivers] = await pool.execute(
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
      ORDER BY d.id DESC
      `
    );

    return res.status(200).json({
      success: true,
      drivers
    });

  } catch (error) {
    next(error);
  }
}


// =========================================================
// GET ALL ORDERS
// =========================================================

async function getOrders(req, res, next) {
  try {
    const [orders] = await pool.execute(
      `
      SELECT
        o.id,
        o.restaurant_id,
        r.name AS restaurant_name,

        o.driver_id,
        du.full_name AS driver_name,

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

      LEFT JOIN drivers d
        ON d.id = o.driver_id

      LEFT JOIN users du
        ON du.id = d.user_id

      ORDER BY o.created_at DESC
      `
    );

    return res.status(200).json({
      success: true,
      orders
    });

  } catch (error) {
    next(error);
  }
}


module.exports = {
  getDashboard,
  getRestaurants,
  getDrivers,
  getOrders
};
