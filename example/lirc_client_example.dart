// Copyright (c) 2016, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:lirc_client/lirc_client.dart';
import 'dart:io';

main() {
  //var test = new LircReceiver("test", null);
  //test.run();

  LircSender sender = new LircSender();

  new LircReceiverStream("test").listen((String data) {
    print(data);

    if (data == "Mere lyd!!!") {
      sender.sendOnce("NAD_D1050", "POWER_ON");
    } else if (data == "MINDRE LYD") {
      sender.sendOnce("NAD_D1050", "POWER_OFF");
    }

  });
}
