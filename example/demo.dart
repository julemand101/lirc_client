import 'package:lirc_client/lirc_client.dart';

Future<void> main() async {
  print(':: Started');
  final client = await LircClient.connect();
  print(':: Connected');
  client.sighups.listen((messge) => print('SIGHUP: ${messge.rawMessage}'));
  client.broadcastMessages.listen((event) {
    print('BROADCAST EVENT');
    print('remoteControlName: ${event.remoteControlName}');
    print('buttonName: ${event.buttonName}');
    print('code: ${event.code}');
    print('repeatCount: ${event.repeatCount}');
    print('RAW: ${event.rawMessage}');
  });

  for (var i = 0; i < 100; i++) {
    client.version();
  }

  final result = await client.list();
  print(result.data);


  await client.close();
}
