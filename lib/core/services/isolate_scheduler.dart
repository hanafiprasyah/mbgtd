import 'dart:isolate';
import 'dart:async';

class IsolateScheduler {
  Isolate? _isolate;
  ReceivePort? _receivePort;

  void Function()? onTick;

  Future<void> start() async {
    _receivePort = ReceivePort();

    _receivePort!.listen((message) {
      if (message == 'tick') {
        onTick?.call(); // 🔥 trigger ke main isolate
      }
    });

    _isolate = await Isolate.spawn(_entryPoint, _receivePort!.sendPort);
  }

  void stop() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
  }

  static void _entryPoint(SendPort sendPort) {
    Timer.periodic(const Duration(minutes: 10), (_) {
      sendPort.send('tick');
    });
  }
}
