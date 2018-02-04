part of dart_lirc_client;

/*
 * Vigtige data at sende med over i C koden:
 *    prog -> navnet på programmet som er angivet i lircrc conf filen.
 *    config -> sti til config fil.
 *              denne kan være null hvor lirc så vil lede efter filen i en
 *              standardplacering
 */

class LircReceiver {
  String appName;
  String configFile;

  LircReceiver(this.appName, this.configFile);

  run() {
    RawReceivePort port = new RawReceivePort((List list) {
      String msg = list[0];
      bool error = list[1];

      print("$msg = $error");
    });
    print("Setting up port");
    _newServicePort().send([appName, configFile, port.sendPort]);
    print("Got port");
  }

  SendPort _newServicePort() native "LircReceiver_ServicePort";
}
