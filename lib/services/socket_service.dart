import 'package:socket_io_client/socket_io_client.dart'
    as io;

class SocketService {
  io.Socket? _socket;

  bool get isConnected =>
      _socket?.connected ?? false;

  // =========================================================
  // CONNECT
  // =========================================================

  void connect({
    required String serverUrl,
    required String token,
    required int driverId,
  }) {
    // إذا كان هناك اتصال سابق، نغلقه أولًا
    disconnect();

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({
            'token': token,
          })
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.onConnect((_) {
      print('Socket connected: ${_socket!.id}');

      // دخول غرفة السائق
      _socket!.emit(
        'driver_join',
        driverId,
      );
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });

    _socket!.onConnectError((error) {
      print(
        'Socket connection error: $error',
      );
    });

    _socket!.connect();
  }

  // =========================================================
  // LISTEN TO EVENT
  // =========================================================

  void on(
    String event,
    Function(dynamic data) callback,
  ) {
    _socket?.on(
      event,
      callback,
    );
  }

  // =========================================================
  // EMIT EVENT
  // =========================================================

  void emit(
    String event,
    dynamic data,
  ) {
    _socket?.emit(
      event,
      data,
    );
  }

  // =========================================================
  // DISCONNECT
  // =========================================================

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
