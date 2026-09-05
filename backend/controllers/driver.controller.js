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

    // -------------------------------------------------------
    // VALIDATION
    // -------------------------------------------------------

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

    // -------------------------------------------------------
    // FIND DRIVER
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
    // SAVE LOCATION
    // -------------------------------------------------------

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
// EXPORTS
// =========================================================

module.exports = {
  getProfile,
  updateOnlineStatus,
  updateLocation
};
