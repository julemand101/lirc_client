part of lirc_client;

class _LircMessageTransformer
    implements StreamTransformer<String, LircMessage> {

  const _LircMessageTransformer();

  @override
  Stream<LircMessage> bind(Stream<String> stream) async* {
    var _multipleLineBlock = false;
    final _buffer = <String>[];

    await for (final line in stream) {
      _buffer.add(line);

      if (line == 'BEGIN' && _multipleLineBlock == false) {
        _multipleLineBlock = true;
      } else if (line == 'END' && _multipleLineBlock) {
        if (_buffer.length == 3 && _buffer[1] == 'SIGHUP') {
          yield LircSighupMessage(_buffer);
        } else {
          yield LircReplyMessage.parse(_buffer);
        }
        _buffer.clear();
        _multipleLineBlock = false;
      } else if (_multipleLineBlock == false) {
        yield LircBroadcastMessage.parse(_buffer);
        _buffer.clear();
      }
    }
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() {
    throw UnimplementedError();
  }
}
