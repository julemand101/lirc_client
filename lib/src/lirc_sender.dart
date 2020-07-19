part of lirc_client;

class LircClient {
  final Socket _socket;
  final StreamController<LircMessage> _streamController =
      StreamController.broadcast();
  final Queue<Completer<LircReplyMessage>> _commandsAwaitingAnswer = Queue();

  LircClient._(this._socket) {
    _streamController.addStream(_socket
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .transform(_LircMessageTransformer()));

    _replyMessages.listen((reply) {
      if (_commandsAwaitingAnswer.isNotEmpty) {
        _commandsAwaitingAnswer.removeFirst().complete(reply);
      }
    });
  }

  static Future<LircClient> connect(
          {String unixSocketPath = '/var/run/lirc/lircd'}) async =>
      LircClient._(await Socket.connect(
          InternetAddress(unixSocketPath, type: InternetAddressType.unix), 0));

  Stream<LircMessage> get _allMessages => _streamController.stream;

  Stream<LircReplyMessage> get _replyMessages =>
      _allMessages.whereType<LircReplyMessage>();

  Stream<LircBroadcastMessage> get broadcastMessages =>
      _allMessages.whereType<LircBroadcastMessage>();

  Stream<LircSighupMessage> get sighups =>
      _allMessages.whereType<LircSighupMessage>();

  /// SEND_ONCE `<remote control> <button name> [repeats]`
  ///
  /// Tell lircd to send the IR signal associated with the given remote
  /// control and button name, and then repeat it repeats times.
  /// `[repeats]` is a decimal number between 0 and repeat_max.
  /// The latter can be given as a --repeat-max command line argument to lircd,
  /// and defaults to 600.  If repeats is not specified or is less than the
  /// minimum number of repeats for the selected remote control, the minimum
  ///  value will be used.
  Future<LircReplyMessage> sendOnce(String remoteControl, String buttonName,
          {int repeats}) =>
      (repeats == null)
          ? _send("SEND_ONCE $remoteControl $buttonName\n")
          : _send("SEND_ONCE $remoteControl $buttonName $repeats\n");

  /// SEND_START `<remote control name> <button name>`
  ///
  /// Tell lircd to start repeating the given button until it receives a
  /// SEND_STOP command. However, the number of repeats is limited to repeat_max.
  /// lircd won't accept any new send commands while it is repeating.
  Future<LircReplyMessage> sendStart(String remoteControl, String buttonName) =>
      _send("SEND_START $remoteControl $buttonName\n");

  /// SEND_STOP `<remote control name> <button name>`
  ///
  /// Tell lircd to abort a SEND_START command.
  Future<LircReplyMessage> sendStop(String remoteControl, String buttonName) =>
      _send("SEND_STOP $remoteControl $buttonName\n");

  /// LIST `[remote control]`
  ///
  /// Without arguments lircd replies with a list of all defined remote
  /// controls. Given a remote control argument, lircd replies with a list of
  /// all keys defined in the given remote.
  Future<LircReplyMessage> list({String remoteControl}) =>
      (remoteControl == null)
          ? _send('LIST\n')
          : _send('LIST $remoteControl\n');

  /// SET_TRANSMITTERS `transmitter mask`
  ///
  /// Make lircd invoke the drvctl_func(LIRC_SET_TRANSMITTER_MASK, &channels),
  /// where channels is the decoded value of transmitter mask. See lirc(4) for
  /// more information.
  Future<LircReplyMessage> setTransmitters(List<int> transmitterIds) =>
      _send("SET_TRANSMITTERS ${transmitterIds.join(" ")}\n");

  /// VERSION
  ///
  /// Tell lircd to send a version packet response.
  Future<LircReplyMessage> version() => _send('VERSION\n');

  Future<void> close() async {
    await _socket.flush();
    await _socket.close();
    _commandsAwaitingAnswer.forEach(
        (completer) => completer.completeError('close() called on LircClient'));
  }

  Future<LircReplyMessage> _send(String command) {
    final completer = Completer<LircReplyMessage>();

    _commandsAwaitingAnswer.add(completer);
    _socket.add(utf8.encode(command));

    return completer.future;
  }
}
