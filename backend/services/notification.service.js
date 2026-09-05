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

function sendOrderOfferNotification(driverId, order) {
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
      restaurant_id: order.restaurant_id,
      customer_address: order.customer_address,
      customer_latitude: order.customer_latitude,
      customer_longitude: order.customer_longitude,
      food_amount: order.food_amount,
      driver_fee: order.driver_fee,
      expires_at: order.expires_at
    }
  );

  return true;
}

module.exports = {
  initializeNotificationService,
  sendOrderOfferNotification
};
