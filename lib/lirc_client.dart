// Copyright (c) 2016, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Support for doing something awesome.
///
/// More dartdocs go here.
library lirc_client;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

part 'src/lirc_message.dart';
part 'src/lirc_message_transformer.dart';
part 'src/lirc_sender.dart';

extension _Where<T> on Stream<T> {
  Stream<S> whereType<S>() => where((e) => e is S).cast<S>();
}
