import 'dart:collection';

sealed class LircMessage {
  final List<String> rawMessage;

  LircMessage(List<String> rawMessage)
    : rawMessage = List.unmodifiable(rawMessage);
}

class LircSighupMessage extends LircMessage {
  LircSighupMessage(super.rawMessage);

  @override
  String toString() =>
      'LircSighupMessage: {'
      'rawMessage: $rawMessage}';
}

class LircReplyMessage extends LircMessage {
  final String command;
  final bool error;
  final List<String> data;

  bool get success => !error;

  LircReplyMessage._({
    required List<String> rawMessage,
    required this.command,
    required this.error,
    required List<String> data,
  }) : data = UnmodifiableListView(data),
       super(rawMessage);

  // BEGIN
  // <command>
  // [SUCCESS|ERROR]
  // [DATA
  // n
  // n lines of data]
  // END
  factory LircReplyMessage.parse(List<String> rawMessage) => LircReplyMessage._(
    rawMessage: rawMessage,
    command: rawMessage[1],
    error: rawMessage[2] == 'ERROR',
    data: [
      if (rawMessage[3] == 'DATA')
        ...rawMessage.sublist(5, 5 + int.parse(rawMessage[4])),
    ],
  );

  @override
  String toString() =>
      'LircReplyMessage: {'
      'command; $command, '
      'error: $error, '
      'data: $data, '
      'rawMessage: $rawMessage}';
}

class LircBroadcastMessage extends LircMessage {
  final int code;
  final int repeatCount;
  final String buttonName;
  final String remoteControlName;

  LircBroadcastMessage._({
    required List<String> rawMessage,
    required this.code,
    required this.repeatCount,
    required this.buttonName,
    required this.remoteControlName,
  }) : super(rawMessage);

  factory LircBroadcastMessage.parse(List<String> rawMessage) {
    // <code> <repeat count> <button name> <remote control name>
    final parts = rawMessage.first.split(' ');

    return LircBroadcastMessage._(
      rawMessage: rawMessage,
      code: int.parse(parts[0], radix: 16),
      repeatCount: int.parse(parts[1], radix: 16),
      buttonName: parts[2],
      remoteControlName: parts[3],
    );
  }

  @override
  String toString() =>
      'LircBroadcastMessage: {'
      'code: $code (hex: ${code.toRadixString(16).padLeft(16, '0')}, '
      'repeatCount: $repeatCount (hex: ${repeatCount.toRadixString(16)}), '
      'buttonName: $buttonName, '
      'remoteControlName: $remoteControlName, '
      'rawMessage: $rawMessage}';
}

/*
LIST
-----------------------------
BEGIN
LIST
SUCCESS
DATA
10
NAD
Sony_RM-ED009-12
Sony_RM-ED009-15
NAD_451
NAD_AVR2-RCVR
NAD_AVR2-DVD
NAD_D1050
NAD_RC512
NAD_SR6
NAD_SR712
END
-----------------------------

LIST NAD_AVR2-RCVR

-----------------------------
BEGIN
LIST NAD_AVR2-RCVR
SUCCESS
DATA
32
00000000000001fe RCVR_POWER
00000000000004fb KEY_SLEEP
00000000000043bc KEY_DVD
00000000000003fc KEY_SAT
000000000000837c KEY_VCR
0000000000000cf3 VIDEO_4
0000000000008c73 VIDEO_5
000000000000748b EXT._5.1
000000000000a15e KEY_CD
000000000000b14e KEY_TAPE
000000000000bb44 FM/AM
00000000000051ae RCVR_1
000000000000718e RCVR_2
00000000000049b6 RCVR_3
0000000000006996 RCVR_4
000000000000d12e RCVR_5
000000000000f10e RCVR_6
000000000000c936 RCVR_7
000000000000e916 RCVR_8
00000000000019e6 RCVR_9
000000000000e31c RCVR_0
00000000000033cc RCVR_SURR.
000000000000f40b RCVR_DYN.R
000000000000b34c RCVR_TEST
000000000000d42b RCVR_LEVEL
00000000000011ee RCVR_VOLUME+
00000000000031ce RCVR_VOLUME-
0000000000008b74 RCVR_TUNE_DOWN
0000000000004bb4 RCVR_TUNE_UP
00000000000029d6 RCVR_MUTE_ENTER
000000000000649b RCVR_DISPLAY
000000000000cc33 RCVR_TUNE_MODE
END
-----------------------------

VERSION
-----------------------------
BEGIN
VERSION
SUCCESS
DATA
1
0.10.1
END
-----------------------------
 */
