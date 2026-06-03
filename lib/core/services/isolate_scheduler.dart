import 'dart:async';
import 'dart:isolate';

class IsolateScheduler {
  Isolate? _isolate;
  ReceivePort? _receivePort;

  void Function()? onTick;

  Future<void> start(Duration duration) async {
    // Ensure any existing isolate is stopped before starting a new one.
    stop();

    _receivePort = ReceivePort();

    _receivePort!.listen((message) {
      if (message == 'tick') {
        onTick?.call();
      }
    });

    // Spawn a new isolate to run the timer.
    _isolate = await Isolate.spawn(_entryPoint, {
      'sendPort': _receivePort!.sendPort,
      'duration': duration.inSeconds,
    });
  }

  // Stops the isolate and closes the receive port.
  void stop() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
  }

  static void _entryPoint(Map<String, dynamic> args) {
    final sendPort = args['sendPort'] as SendPort;
    final duration = args['duration'] as int;

    // Use a timer to send a message back to the main isolate after the specified duration.
    Timer(Duration(seconds: duration), () {
      sendPort.send('tick');
    });
  }
}
