let io = null;

// =========================================================
// INITIALIZE SOCKET.IO
// =========================================================

function initializeNotificationService(socketIO) {
  io = socketIO;
}

// =========================================================
// SEND ORDER OFFER TO DRIVER
// =========================================================

function sendOrderOfferNotification(
  driverId,
  order
) {
  if (!io) {
    console.warn(
      "Socket.IO is not initialized"
    );

    return false;
  }

  io.to(`driver_${driverId}`).emit(
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

      driver_fee:
        order.driver_fee,

      expires_at:
        order.expires_at
    }
  );

  return true;
}

// =========================================================
// EXPORTS
// =========================================================

module.exports = {
  initializeNotificationService,
  sendOrderOfferNotification
};
