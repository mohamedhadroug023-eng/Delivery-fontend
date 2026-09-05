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

module.exports = {
  getProfile,
  updateOnlineStatus
};
