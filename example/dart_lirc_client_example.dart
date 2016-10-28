// Copyright (c) 2016, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:dart_lirc_client/dart_lirc_client.dart';

main() {
  RandomArray randomArray = new RandomArray();

  randomArray.randomArray(123, 10).then((List<int> values) {
    print(values);
  });
}
