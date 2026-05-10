import 'dart:isolate';
import 'dart:async';

class IsolateScheduler {
  Isolate? _isolate;
  ReceivePort? _receivePort;

  void Function()? onTick;

  Future<void> start(Duration duration) async {
    stop();

    _receivePort = ReceivePort();

    _receivePort!.listen((message) {
      if (message == 'tick') {
        onTick?.call();
      }
    });

    _isolate = await Isolate.spawn(_entryPoint, {
      'sendPort': _receivePort!.sendPort,
      'duration': duration.inSeconds,
    });
  }

  void stop() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
  }

  static void _entryPoint(Map<String, dynamic> args) {
    final sendPort = args['sendPort'] as SendPort;
    final duration = args['duration'] as int;

    Timer(Duration(seconds: duration), () {
      sendPort.send('tick');
    });
  }
}
