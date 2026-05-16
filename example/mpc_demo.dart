import 'dart:convert';
import 'dart:io';

const mpc = '/bin/mpc';

void main() async {
  final mpcProcess = await Process.start(mpc, const ['idleloop', 'output']);

  final pattern = RegExp(r'Output (\d+) \((.+)\) is (disabled|enabled)');

  await for (final event
      in mpcProcess.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
    if (event == 'output') {
      final outputString =
          (await Process.run(mpc, const ['outputs'])).stdout as String;

      final outputs = {
        for (final match in pattern.allMatches(outputString))
          {match[2]: match[3] == 'enabled'},
      };

      print(outputs);
    }
  }
}
