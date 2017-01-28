class LircSender {
  /*
   * SEND_ONCE <remote control> <button name> [repeats]
   *
   * Tell lircd to send the IR signal associated with the given remote
   * control and button name, and then repeat it repeats times.
   * [repeats] is a decimal number between 0 and repeat_max.
   * The latter can be given as a --repeat-max command line argument to lircd,
   * and defaults to 600.  If repeats is not specified or is less than the
   * minimum number of repeats for the selected remote control, the minimum
   *  value will be used.
   */
  static const _SEND_ONCE = "SEND_ONCE";

  /*
   * SEND_START <remote control name> <button name>
   *
   * Tell lircd to start repeating the given button until it receives a
   * SEND_STOP command. However, the number of repeats is limited to repeat_max.
   * lircd won't accept any new send commands while it is repeating.
   */
  static const _SEND_START = "SEND_START";

  /*
   * SEND_STOP <remote control name> <button name>
   *
   * Tell lircd to abort a SEND_START command.
   */
  static const _SEND_STOP = "SEND_STOP";

  /*
   * LIST [remote control]
   *
   * Without arguments lircd replies with a list of all defined remote controls.
   * Given a remote control argument, lircd replies with a list of all keys
   * defined in the given remote.
   */
  static const _LIST = "LIST";

  /*
   * SET_INPUTLOG [path]
   * Given a path, lircd will start logging all received data on that file.
   * The log is printable lines as defined in mode2(1) describing pulse/space
   * durations. Without a path, current logfile is closed and the logging is
   * stopped.
   */
  static const _SET_INPUTLOG = "SET_INPUTLOG";

  /*
   * DRV_OPTION key value
   *
   * Make lircd invoke the drvctl_func(DRVCTL_SET_OPTION, option) with option
   * being made up by the parsed key and value. The return package reflects the
   * outcome of the drvctl_func call.
   */
  static const _DRV_OPTION = "DRV_OPTION";

  /*
   * SIMULATE key data
   * Given key data, instructs lircd  to send this to all clients i.e., to
   * simulate that this key has been decoded. The key data must be formatted
   * exactly as the packet described in [SOCKET BROADCAST MESSAGES FORMAT],
   * notably is the number of digits in code and repeat count hardcoded. This
   * command is only accepted if the --allow-simulate command line option is
   * active.
   */
  static const _SIMULATE = "SIMULATE";

  /*
   * SET_TRANSMITTERS transmitter mask
   *
   * Make lircd invoke the drvctl_func(LIRC_SET_TRANSMITTER_MASK, &channels),
   * where channels is the decoded value of transmitter mask. See lirc(4) for
   * more information.
   */
  static const _SET_TRANSMITTERS = "SET_TRANSMITTERS";

  /*
   *  VERSION
   *
   *  Tell lircd to send a version packet response.
   */
  static const _VERSION = "VERSION";

  var socketPath;

  LircSender({this.socketPath});

  void sendOnce() {}
}
