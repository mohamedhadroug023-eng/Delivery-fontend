const pool = require("../config/database");

let io = null;


/* =========================================================
   INITIALIZE
========================================================= */

function initializeNotificationService(socketIO) {
  io = socketIO;
}


/* =========================================================
   GET FULL ORDER
========================================================= */

async function getOrderForNotification(
  orderId
) {
  const [orders] = await pool.execute(
    `
    SELECT
      o.id,
      o.restaurant_id,

      r.name AS restaurant_name,
      r.address AS restaurant_address,
      r.latitude AS restaurant_latitude,
      r.longitude AS restaurant_longitude,

      o.driver_id,

      o.customer_name,
      o.customer_phone,
      o.customer_address,
      o.customer_latitude,
      o.customer_longitude,

      o.food_amount,
      o.hadroug_fee,
      o.driver_fee,

      o.status,

      o.current_offer_driver_id,
      o.offer_expires_at,

      o.created_at,
      o.accepted_at,
      o.pickup_verified_at,
      o.picked_up_at,
      o.delivered_at,
      o.cancelled_at

    FROM orders o

    INNER JOIN restaurants r
      ON r.id = o.restaurant_id

    WHERE o.id = ?

    LIMIT 1
    `,
    [orderId]
  );

  if (orders.length === 0) {
    return null;
  }

  return orders[0];
}


/* =========================================================
   SEND ORDER OFFER TO DRIVER
========================================================= */

async function sendOrderOfferNotification(
  driverId,
  order
) {
  if (!io) {
    console.warn(
      "Socket.IO is not initialized"
    );

    return false;
  }

  io.to(
    `driver_${driverId}`
  ).emit(
    "order_offer",
    {
      order_id: order.id,

      restaurant_id:
        order.restaurant_id,

      restaurant_name:
        order.restaurant_name ?? null,

      restaurant_address:
        order.restaurant_address ?? null,

      restaurant_latitude:
        order.restaurant_latitude ?? null,

      restaurant_longitude:
        order.restaurant_longitude ?? null,

      customer_name:
        order.customer_name ?? null,

      customer_phone:
        order.customer_phone ?? null,

      customer_address:
        order.customer_address ?? null,

      customer_latitude:
        order.customer_latitude ?? null,

      customer_longitude:
        order.customer_longitude ?? null,

      food_amount:
        order.food_amount,

      hadroug_fee:
        order.hadroug_fee,

      driver_fee:
        order.driver_fee,

      status:
        order.status,

      expires_at:
        order.offer_expires_at ??
        order.expires_at ??
        null
    }
  );

  return true;
}


/* =========================================================
   SEND TO RESTAURANT
========================================================= */

async function notifyRestaurant(
  restaurantId,
  event,
  data
) {
  if (!io) {
    console.warn(
      "Socket.IO is not initialized"
    );

    return false;
  }

  io.to(
    `restaurant_${restaurantId}`
  ).emit(
    event,
    data
  );

  return true;
}


/* =========================================================
   SEND TO ADMIN
========================================================= */

async function notifyAdmins(
  event,
  data
) {
  if (!io) {
    console.warn(
      "Socket.IO is not initialized"
    );

    return false;
  }

  io.to(
    "admins"
  ).emit(
    event,
    data
  );

  return true;
}


/* =========================================================
   ORDER STATUS UPDATE
========================================================= */

async function notifyOrderStatus(
  orderId,
  status,
  extraData = {}
) {
  if (!io) {
    console.warn(
      "Socket.IO is not initialized"
    );

    return false;
  }

  const order =
    await getOrderForNotification(
      orderId
    );

  if (!order) {
    console.warn(
      `Order ${orderId} not found for notification`
    );

    return false;
  }


  const payload = {
    order_id:
      order.id,

    restaurant_id:
      order.restaurant_id,

    restaurant_name:
      order.restaurant_name,

    driver_id:
      order.driver_id,

    customer_name:
      order.customer_name,

    customer_phone:
      order.customer_phone,

    customer_address:
      order.customer_address,

    customer_latitude:
      order.customer_latitude,

    customer_longitude:
      order.customer_longitude,

    food_amount:
      order.food_amount,

    hadroug_fee:
      order.hadroug_fee,

    driver_fee:
      order.driver_fee,

    status,

    ...extraData
  };


  /* =======================================================
     RESTAURANT
  ======================================================= */

  io.to(
    `restaurant_${order.restaurant_id}`
  ).emit(
    "order_status_updated",
    payload
  );


  /* =======================================================
     DRIVER
  ======================================================= */

  if (order.driver_id) {

    io.to(
      `driver_${order.driver_id}`
    ).emit(
      "order_status_updated",
      payload
    );
  }


  /* =======================================================
     ADMINS
  ======================================================= */

  io.to(
    "admins"
  ).emit(
    "order_status_updated",
    payload
  );


  return true;
}


/* =========================================================
   DRIVER ACCEPTED ORDER
========================================================= */

async function notifyDriverAccepted(
  orderId,
  driverId
) {
  return notifyOrderStatus(
    orderId,
    "accepted",
    {
      driver_id:
        driverId
    }
  );
}


/* =========================================================
   DRIVER ARRIVED
========================================================= */

async function notifyDriverArrived(
  orderId,
  driverId
) {
  return notifyOrderStatus(
    orderId,
    "driver_arrived",
    {
      driver_id:
        driverId
    }
  );
}


/* =========================================================
   PICKUP VERIFIED
========================================================= */

async function notifyPickupVerified(
  orderId,
  driverId
) {
  return notifyOrderStatus(
    orderId,
    "picked_up",
    {
      driver_id:
        driverId
    }
  );
}


/* =========================================================
   DELIVERY STARTED
========================================================= */

async function notifyDeliveryStarted(
  orderId,
  driverId
) {
  return notifyOrderStatus(
    orderId,
    "delivering",
    {
      driver_id:
        driverId
    }
  );
}


/* =========================================================
   ORDER DELIVERED
========================================================= */

async function notifyOrderDelivered(
  orderId,
  driverId
) {
  return notifyOrderStatus(
    orderId,
    "delivered",
    {
      driver_id:
        driverId
    }
  );
}


/* =========================================================
   EXPORTS
========================================================= */

module.exports = {
  initializeNotificationService,

  getOrderForNotification,

  sendOrderOfferNotification,

  notifyRestaurant,

  notifyAdmins,

  notifyOrderStatus,

  notifyDriverAccepted,

  notifyDriverArrived,

  notifyPickupVerified,

  notifyDeliveryStarted,

  notifyOrderDelivered
};
