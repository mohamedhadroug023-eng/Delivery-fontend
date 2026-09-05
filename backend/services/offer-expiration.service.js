const pool = require("../config/database");

const {
  sendOrderOffer
} = require("./dispatch.service");

// =========================================================
// PROCESS EXPIRED OFFERS
// =========================================================

async function processExpiredOffers() {

  const [expiredOrders] = await pool.execute(
    `
    SELECT
      id,
      current_offer_driver_id
    FROM orders
    WHERE
      status = 'offered'
      AND offer_expires_at IS NOT NULL
      AND offer_expires_at <= NOW()
    `
  );

  for (const order of expiredOrders) {

    const connection =
      await pool.getConnection();

    try {

      await connection.beginTransaction();

      // ---------------------------------------------------
      // Make sure the offer is still expired
      // ---------------------------------------------------

      const [rows] =
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
          [order.id]
        );

      if (rows.length === 0) {
        await connection.rollback();
        continue;
      }

      const currentOrder = rows[0];

      if (
        currentOrder.status !== "offered" ||
        Number(
          currentOrder.current_offer_driver_id
        ) !== Number(
          order.current_offer_driver_id
        )
      ) {
        await connection.rollback();
        continue;
      }

      // ---------------------------------------------------
      // Mark offer as expired
      // ---------------------------------------------------

      await connection.execute(
        `
        UPDATE order_offers
        SET
          status = 'expired',
          responded_at = CURRENT_TIMESTAMP
        WHERE
          order_id = ?
          AND driver_id = ?
          AND status = 'offered'
        ORDER BY id DESC
        LIMIT 1
        `,
        [
          order.id,
          order.current_offer_driver_id
        ]
      );

      // ---------------------------------------------------
      // Return order to dispatching
      // ---------------------------------------------------

      await connection.execute(
        `
        UPDATE orders
        SET
          status = 'dispatching',
          current_offer_driver_id = NULL,
          offer_expires_at = NULL
        WHERE
          id = ?
        `,
        [order.id]
      );

      // ---------------------------------------------------
      // Event
      // ---------------------------------------------------

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
          order.id,
          "driver_offer_expired",
          "offered",
          "dispatching",
          `Offer to driver ${order.current_offer_driver_id} expired`
        ]
      );

      await connection.commit();

    } catch (error) {

      await connection.rollback();

      console.error(
        `Failed to process expired order ${order.id}:`,
        error
      );

    } finally {

      connection.release();
    }

    // -----------------------------------------------------
    // SEND TO NEXT DRIVER
    // -----------------------------------------------------

    try {

      await sendOrderOffer(order.id);

    } catch (error) {

      console.error(
        `Failed to dispatch order ${order.id}:`,
        error
      );
    }
  }
}

module.exports = {
  processExpiredOffers
};
