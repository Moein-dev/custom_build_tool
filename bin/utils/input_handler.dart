import 'dart:async';
import 'dart:io';

class InputHandler {
  // تبدیل stdin به یک BroadcastStream
  static final Stream<List<int>> _stdinBroadcast = stdin.asBroadcastStream();

  static Future<String> readKey() async {
    stdin.echoMode = false;
    stdin.lineMode = false;

    try {
      final completer = Completer<String>();

      // use BroadcastStream to listen to stdin
      final subscription = _stdinBroadcast.listen((data) {
        completer.complete(String.fromCharCode(data[0]));
      }, onError: (error) {
        completer.completeError(error);
      }, onDone: () {
        completer.completeError("Input stream closed.");
      });

      // await input
      final result = await completer.future;

      // cancel subscription after receiving input
      subscription.cancel();
      return result;
    } finally {
      stdin.echoMode = true;
      stdin.lineMode = true;
    }
  }

  static Future<String> readLineWithEcho(bool echoEnabled) async {
    stdin.echoMode = echoEnabled; // enable/disable terminal settings
    stdin.lineMode = true; // enable/disable terminal settings

    try {
      final completer = Completer<String>();

      // use BroadcastStream to listen to stdin
      final subscription = _stdinBroadcast.listen((data) {
        completer.complete(String.fromCharCodes(data).trim());
      }, onError: (error) {
        completer.completeError(error);
      }, onDone: () {
        completer.completeError("Input stream closed.");
      });

      // await input
      final result = await completer.future.toString();

      // cancel subscription after receiving input
      subscription.cancel();
      return result;
    } finally {
      stdin.echoMode = true; // reset terminal settings
      stdin.lineMode = true;
    }
  }
}