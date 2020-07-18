import 'package:lirc_client/lirc_client.dart';

Future<void> main() async {
  final client = await LircClient.connect();

  client.broadcastMessages
      .where((event) => event.remoteControlName == 'Sony_RM-ED009-12')
      .listen((event) {
    if (event.buttonName == "KEY_VOLUMEUP") {
      client.sendOnce("NAD_SR6", "KEY_VOLUMEUP");
    } else if (event.buttonName == "KEY_VOLUMEDOWN") {
      client.sendOnce("NAD_SR6", "KEY_VOLUMEDOWN");
    } else if (event.buttonName == "KEY_MUTE") {
      client.sendOnce("NAD_SR6", "KEY_POWER");
    }
  });

  print(":: Program is running!");
}
