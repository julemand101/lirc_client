// Copyright (c) 2016, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:lirc_client/lirc_client.dart';

main() {
  var test = new LircReceiver("test", null);
  test.run();
}
