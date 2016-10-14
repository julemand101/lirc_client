// Copyright (c) 2016, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// TODO: Put public facing types in this file.

/// Checks if you are awesome. Spoiler: you are.
import 'dart:async';

class LircReceiver {
  var socketPath;
  var configFile;
  var appName;

  LircReceiver({this.socketPath, this.configFile, this.appName});

  Stream<String> test() {
    return null;
  }
}
