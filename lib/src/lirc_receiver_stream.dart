part of lirc_client;

/*
 * Vigtige data at sende med over i C koden:
 *    prog -> navnet på programmet som er angivet i lircrc conf filen.
 *    config -> sti til config fil.
 *              denne kan være null hvor lirc så vil lede efter filen i en
 *              standardplacering
 */

class LircReceiverStream extends Stream<String> {
  static SendPort _sendPort = _getLircReceiverServicePort();

  StreamController<String> _controller;
  RawReceivePort _receivePort;
  String _appName;
  String _configFile;

  LircReceiverStream(this._appName, [this._configFile]) {
    _controller = new StreamController<String>(
        onListen: _onListen,
        onPause: _onPause,
        onResume: _onResume,
        onCancel: _onCancel);
  }

  StreamSubscription<String> listen(void onData(String line),
      {void onError(Error error), void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  void _onListen() {
    _receivePort = new RawReceivePort((List list) {
      String message = list[0];
      bool error = list[1];

      if (error) {
        _controller.addError(message);
      } else {
        _controller.add(message);
      }
    });

    _sendPort.send([_appName, _configFile, _receivePort.sendPort]);
  }

  void _onCancel() {
    _receivePort.close();
    _receivePort = null;
  }

  void _onPause() {
    // Not supported and I am not sure how I whould do it...
  }

  void _onResume() {
    // Not supported and I am not sure how I whould do it...
  }
}
