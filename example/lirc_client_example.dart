import 'dart:convert';
import 'dart:io';

import 'package:lirc_client/lirc_client.dart';

const dac = 'NAD_D1050';
const receiver = 'NAD_SR6';
const mpc = '/bin/mpc';

Future<void> main() async {
  final client = await LircClient.connect();
  String? lastDevice;

  Future<void> turnOn({String device = 'OPTICAL_1'}) async {
    if (lastDevice == 'COMPUTER' && device != 'COMPUTER') {
      Process.start(mpc, ['disable', 'Stereo']).ignore();
    }

    lastDevice = device;

    print('### POWERED ON ###');
    client.sendOnce(dac, 'POWER_ON');

    await Future<void>.delayed(const Duration(milliseconds: 200));
    client.sendOnce(receiver, 'KEY_POWER');

    await Future<void>.delayed(const Duration(seconds: 7));
    client.sendOnce(dac, device);
  }

  Future<void> turnOff() async {
    lastDevice = null;

    print('### POWERED OFF ###');
    client.sendOnce(dac, 'POWER_OFF');

    await Future<void>.delayed(const Duration(milliseconds: 200));
    client.sendOnce(receiver, 'off');

    Process.start(mpc, ['disable', 'Stereo']).ignore();
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

  // 0 = AIRABLE_RADIO (net radio)
  // 1 = AIRABLE_PODCASTS
  // 2 = Spotify
  // 3 = DAB
  // 4 = FM
  // 5 = Bluetooth
  // 6 = AUXIN
  Future<void> setRadioMode(int mode) async {
    print('### RADIO MODE CHANGED TO $mode ###');
    final request = await httpClient.getUrl(
      Uri.parse(
        'http://192.168.0.109/fsapi/SET/'
        'netRemote.sys.mode?pin=1234&value=$mode',
      ),
    );
    final response = await request.close();
    response.drain<void>().ignore();
  }

  final radioModePattern = RegExp(r'<value><u32>(\d+)</u32></value>');
  Future<int> getRadioMode() async {
    final request = await httpClient.getUrl(
      Uri.parse(
        'http://192.168.0.109/fsapi/GET/'
        'netRemote.sys.mode?pin=1234',
      ),
    );
    final response = await request.close();
    final xml = await response.transform(utf8.decoder).join();
    final match = radioModePattern.firstMatch(xml);

    if (match != null && match[1] != null) {
      return int.parse(match[1]!);
    } else {
      return -1;
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

  // MPD related logic
  final mpcProcess = await Process.start(mpc, const ['idleloop', 'output']);
  final pattern = RegExp(r'Output (\d+) \((.+)\) is (disabled|enabled)');

  await for (final event
      in mpcProcess.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
    if (event == 'output') {
      final outputString =
          (await Process.run(mpc, const ['outputs'])).stdout as String;

      final mpdOutputs = {
        for (final match in pattern.allMatches(outputString))
          match[2]: match[3] == 'enabled',
      };

      if (mpdOutputs['Stereo'] == true) {
        turnOn(device: 'COMPUTER');
      } else {
        if (lastDevice == 'COMPUTER') {
          turnOff();
        }
      }

      if (mpdOutputs['BangNetRadio'] == true) {
        // Turn on the radio and go to net radio
        setRadioPower(true);
        await Future<void>.delayed(const Duration(seconds: 1));
        setRadioMode(0);
      } else {
        // Only turn off radio if the channel are net radio
        if (await getRadioMode() == 0) {
          setRadioPower(false);
        }
      }
    }
  }
}
