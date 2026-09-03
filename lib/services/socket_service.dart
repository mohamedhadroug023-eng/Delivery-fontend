import 'package:socket_io_client/socket_io_client.dart'
    as io;

class SocketService {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect({
    required String serverUrl,
    required String token,
  }) {
    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({
            'token': token,
          })
          .enableAutoConnect()
          .build(),
    );

    _socket!.connect();
  }

  void on(
    String event,
    Function(dynamic data) callback,
  ) {
    _socket?.on(event, callback);
  }

  void emit(
    String event,
    dynamic data,
  ) {
    _socket?.emit(event, data);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
