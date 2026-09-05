import 'package:socket_io_client/socket_io_client.dart'
    as io;

class SocketService {
  io.Socket? _socket;

  bool get isConnected =>
      _socket?.connected ?? false;

  /* =======================================================
     CONNECT
  ======================================================= */

  void connect({
    required String serverUrl,
    required String token,
    String? role,
  }) {
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
      print(
        'Socket connected: ${_socket!.id}',
      );

      /*
       * Backend already identifies the user
       * from the JWT token.
       *
       * No driverId / restaurantId is trusted
       * from the client.
       */

      if (role == 'driver') {
        _socket!.emit('driver_join');
      }
    });

    _socket!.onDisconnect((_) {
      print(
        'Socket disconnected',
      );
    });

    _socket!.onConnectError((error) {
      print(
        'Socket connection error: $error',
      );
    });

    _socket!.onError((error) {
      print(
        'Socket error: $error',
      );
    });

    _socket!.connect();
  }


  /* =======================================================
     LISTEN
  ======================================================= */

  void on(
    String event,
    Function(dynamic data) callback,
  ) {
    _socket?.off(event);

    _socket?.on(
      event,
      callback,
    );
  }


  /* =======================================================
     REMOVE LISTENER
  ======================================================= */

  void off(
    String event,
  ) {
    _socket?.off(event);
  }


  /* =======================================================
     EMIT
  ======================================================= */

  void emit(
    String event,
    dynamic data,
  ) {
    _socket?.emit(
      event,
      data,
    );
  }


  /* =======================================================
     DISCONNECT
  ======================================================= */

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
