import 'dart:async';

import 'lirc_message.dart';

class LircMessageTransformer implements StreamTransformer<String, LircMessage> {
  const LircMessageTransformer();

  @override
  Stream<LircMessage> bind(Stream<String> stream) async* {
    var isMultipleLineBlock = false;
    final buffer = <String>[];

    await for (final line in stream) {
      buffer.add(line);

      if (line == 'BEGIN' && isMultipleLineBlock == false) {
        isMultipleLineBlock = true;
      } else if (line == 'END' && isMultipleLineBlock) {
        if (buffer.length == 3 && buffer[1] == 'SIGHUP') {
          yield LircSighupMessage(buffer);
        } else {
          yield LircReplyMessage.parse(buffer);
        }
        buffer.clear();
        isMultipleLineBlock = false;
      } else if (isMultipleLineBlock == false) {
        yield LircBroadcastMessage.parse(buffer);
        buffer.clear();
      }
    }
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() {
    throw UnimplementedError();
  }
}
