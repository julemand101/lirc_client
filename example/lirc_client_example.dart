import 'package:lirc_client/lirc_client.dart';

Future<void> main() async {
  final client = await LircClient.connect();

  client.broadcastMessages.listen(print);

  client.broadcastMessages
      .where((event) => event.remoteControlName == 'Sony_RM-ED009-12')
      .listen((event) => switch (event.buttonName) {
            'KEY_VOLUMEUP' => client.sendOnce("NAD_SR6", "KEY_VOLUMEUP"),
            'KEY_VOLUMEDOWN' => client.sendOnce("NAD_SR6", "KEY_VOLUMEDOWN"),
            'KEY_MUTE' => client.sendOnce("NAD_SR6", "KEY_POWER"),
            _ => null,
          });

  print(":: Program is running!");
}
