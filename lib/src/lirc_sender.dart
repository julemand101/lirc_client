part of lirc_client;

class LircClient {
  final Socket _socket;
  final StreamController<LircMessage> _streamController =
      StreamController.broadcast();
  final Queue<Completer<LircReplyMessage>> _commandsAwaitingAnswer = Queue();

  LircClient._(this._socket) {
    _socket.encoding = const Utf8Codec(allowMalformed: true);

    _streamController.addStream(const Utf8Codec(allowMalformed: true)
        .decoder
        .bind(_socket)
        .transform(const LineSplitter())
        .transform(const _LircMessageTransformer()));

    _streamController.stream.whereType<LircReplyMessage>().listen((reply) {
      if (_commandsAwaitingAnswer.isNotEmpty) {
        _commandsAwaitingAnswer.removeFirst().complete(reply);
      } else {
        // Some logging
      }
    });
  }

  static Future<LircClient> connect(
          {String unixSocketPath = '/var/run/lirc/lircd'}) async =>
      LircClient._(await Socket.connect(
          InternetAddress(unixSocketPath, type: InternetAddressType.unix), 0));

  Stream<LircBroadcastMessage> get broadcastMessages =>
      _streamController.stream.whereType<LircBroadcastMessage>();

  Stream<LircSighupMessage> get sighups =>
      _streamController.stream.whereType<LircSighupMessage>();

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
          {int? repeats}) =>
      _send([
        'SEND_ONCE',
        remoteControl,
        buttonName,
        if (repeats != null) repeats
      ]);

  /// SEND_START `<remote control name> <button name>`
  ///
  /// Tell lircd to start repeating the given button until it receives a
  /// SEND_STOP command. However, the number of repeats is limited to repeat_max.
  /// lircd won't accept any new send commands while it is repeating.
  Future<LircReplyMessage> sendStart(String remoteControl, String buttonName) =>
      _send(['SEND_START', remoteControl, buttonName]);

  /// SEND_STOP `<remote control name> <button name>`
  ///
  /// Tell lircd to abort a SEND_START command.
  Future<LircReplyMessage> sendStop(String remoteControl, String buttonName) =>
      _send(['SEND_STOP', remoteControl, buttonName]);

  /// LIST `[remote control]`
  ///
  /// Without arguments lircd replies with a list of all defined remote
  /// controls. Given a remote control argument, lircd replies with a list of
  /// all keys defined in the given remote.
  Future<LircReplyMessage> list({String? remoteControl}) =>
      _send(['LIST', if (remoteControl != null) remoteControl]);

  /// SET_TRANSMITTERS `transmitter mask`
  ///
  /// Make lircd invoke the drvctl_func(LIRC_SET_TRANSMITTER_MASK, &channels),
  /// where channels is the decoded value of transmitter mask. See lirc(4) for
  /// more information.
  Future<LircReplyMessage> setTransmitters(Iterable<int> transmitterIds) =>
      _send(['SET_TRANSMITTERS', ...transmitterIds]);

  /// VERSION
  ///
  /// Tell lircd to send a version packet response.
  Future<LircReplyMessage> version() => _send(const ['VERSION']);

  Future<void> close() async {
    await _socket.flush();
    await _socket.close();
    _commandsAwaitingAnswer.forEach(
        (completer) => completer.completeError('close() called on LircClient'));
  }

  Future<LircReplyMessage> _send(Iterable<Object> command) {
    final completer = Completer<LircReplyMessage>();

    _commandsAwaitingAnswer.add(completer);
    _socket.write((StringBuffer()
          ..writeAll(command, ' ')
          ..writeln())
        .toString());

    return completer.future;
  }
}
