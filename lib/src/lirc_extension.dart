part of lirc_client;

SendPort _getLircReceiverServicePort() native "LircReceiver_ServicePort";

/**
 * Path: Path to socket. If NULL use LIRC_SOCKET_PATH in environment,
 * falling back to a hardcoded lircd default.
 */
int _getLircTransmitterLocalSocket(String path)
    native "LircTransmitter_GetLocalSocket";

SendPort _getLircTransmitterServicePort() native "LircTransmitter_ServicePort";
