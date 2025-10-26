import 'dart:convert';
import 'dart:io';

import 'package:lirc_client/lirc_client.dart';

const dac = 'NAD_D1050';
const receiver = 'NAD_SR6';

Future<void> main() async {
  final client = await LircClient.connect();

  Future<void> turnOn() async {
    print('### TV POWERED ON ###');
    client.sendOnce(dac, 'POWER_ON');

    await Future<void>.delayed(const Duration(milliseconds: 200));
    client.sendOnce(receiver, 'KEY_POWER');

    await Future<void>.delayed(const Duration(seconds: 7));
    client.sendOnce(dac, 'OPTICAL_1');
  }

  Future<void> turnOff() async {
    print('### TV POWERED OFF ###');
    client.sendOnce(dac, 'POWER_OFF');

    await Future<void>.delayed(const Duration(milliseconds: 200));
    client.sendOnce(receiver, 'off');
  }

  final httpClient = HttpClient();
  var lastRadioTrigger = DateTime.timestamp();

  Future<void> setRadioPower(bool on) async {
    final now = DateTime.timestamp();

    if (now.difference(lastRadioTrigger).inSeconds > 1) {
      lastRadioTrigger = now;
      print('### RADIO POWERED ${on ? 'ON' : 'OFF'} ###');
      final request = await httpClient.getUrl(
        Uri.parse(
          'http://192.168.0.109/fsapi/SET/'
          'netRemote.sys.power?pin=1234&value=${on ? 1 : 0}',
        ),
      );
      final response = await request.close();
      response.drain<void>().ignore();
    }
  }

  client.broadcastMessages
      .where((event) => event.remoteControlName == 'sony_rm-ed052')
      .listen(
        (event) => switch (event.buttonName) {
          'KEY_VOLUMEUP' => client.sendOnce(receiver, 'KEY_VOLUMEUP'),
          'KEY_VOLUMEDOWN' => client.sendOnce(receiver, 'KEY_VOLUMEDOWN'),
          'KEY_MUTE' => client.sendOnce(receiver, 'KEY_MUTE'),
          'KEY_RED' => turnOff(),
          'KEY_GREEN' => turnOn(),
          'KEY_YELLOW' => setRadioPower(false),
          'KEY_BLUE' => setRadioPower(true),
          _ => null, //print(value),
        },
      );

  Process cecProcess = await Process.start('/usr/bin/cec-client', const ['-m']);

  RegExp tvTurningOn = RegExp(
    r".*TV \(0\): power status changed from '.+' to "
    r"'(on)|(in transition from standby to on)'",
  );

  cecProcess.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) async {
        //print(line);
        if (line.endsWith('0f:36')) {
          // TV Power off
          turnOff();
        } else if (tvTurningOn.hasMatch(line)) {
          // TV Power on
          turnOn();
        }
      });
}
