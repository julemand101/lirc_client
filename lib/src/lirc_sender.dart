part of lirc_client;

class LircSender {
  static SendPort _sendPort = _getLircTransmitterServicePort();

  int _fileDescriptor = 0;

  LircSender({String socketPath}) {
    this._fileDescriptor = _getLircTransmitterLocalSocket(socketPath);

    if (this._fileDescriptor <= 0) {
      if (socketPath == null) {
        throw new LircSenderException(
            "Could not get file descriptor for standard LIRC socket. "
            "Got return code: $_fileDescriptor");
      } else {
        throw new LircSenderException(
            "Could not get file descriptor for LIRC socket $socketPath. "
            "Got return code: $_fileDescriptor");
      }
    }
  }

  /// SEND_ONCE `<remote control> <button name> [repeats]`
  ///
  /// Tell lircd to send the IR signal associated with the given remote
  /// control and button name, and then repeat it repeats times.
  /// `[repeats]` is a decimal number between 0 and repeat_max.
  /// The latter can be given as a --repeat-max command line argument to lircd,
  /// and defaults to 600.  If repeats is not specified or is less than the
  /// minimum number of repeats for the selected remote control, the minimum
  ///  value will be used.
  void sendOnce(String remoteControl, String buttonName, {int repeats = 0}) {
    _send("SEND_ONCE $remoteControl $buttonName $repeats\n");
  }

  /// SEND_START `<remote control name> <button name>`
  ///
  /// Tell lircd to start repeating the given button until it receives a
  /// SEND_STOP command. However, the number of repeats is limited to repeat_max.
  /// lircd won't accept any new send commands while it is repeating.
  void sendStart(String remoteControl, String buttonName) {
    _send("SEND_START $remoteControl $buttonName\n");
  }

  /// SEND_STOP `<remote control name> <button name>`
  ///
  /// Tell lircd to abort a SEND_START command.
  void sendStop(String remoteControl, String buttonName) {
    _send("SEND_STOP $remoteControl $buttonName\n");
  }

  /// SET_TRANSMITTERS transmitter mask
  ///
  /// Make lircd invoke the drvctl_func(LIRC_SET_TRANSMITTER_MASK, &channels),
  /// where channels is the decoded value of transmitter mask. See lirc(4) for
  /// more information.
  void setTransmitters(List<int> transmitterIds) {
    _send("SET_TRANSMITTERS ${transmitterIds.join(" ")}\n");
  }

  void close() {
    _send(null);
    _fileDescriptor = 0;
  }

  void _send(String command) {
    if (_fileDescriptor <= 0) {
      throw new LircSenderException("File descriptor is closed.");
    }
    _sendPort.send([_fileDescriptor, command]);
  }
}

class LircSenderException implements Exception {
  final message;

  LircSenderException([this.message]);

  String toString() {
    if (message == null) return "LircSenderException";
    return "LircSenderException: $message";
  }
}
