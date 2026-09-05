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

    // Get driver
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

    // Lock the order and verify the offer
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

    // Make sure this offer belongs to this driver
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

    // Make sure offer has not expired
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

    // Accept the order
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

    // Update offer history
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

    // Driver now has an active order
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

    // Event
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

    // Make sure this driver currently has the offer
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

    if (
      order.status !== "offered" ||
      Number(order.current_offer_driver_id) !== Number(driverId)
    ) {
      return res.status(409).json({
        success: false,
        message: "This order is no longer offered to you"
      });
    }

    // Mark offer rejected
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

    // Return order to dispatching state
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

    // Record event
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
