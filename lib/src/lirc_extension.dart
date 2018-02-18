part of lirc_client;

SendPort _getLircReceiverServicePort() native "LircReceiver_ServicePort";

/// Get file descriptor for LIRC socket.
///
/// Creates a new socket for LIRC and returns the file descriptor to be used by
/// the [SendPort] from [_getLircTransmitterServicePort].
///
/// [path]: Path to socket. If NULL use LIRC\_SOCKET\_PATH in environment,
/// falling back to a hardcoded lircd default.
int _getLircTransmitterLocalSocket(String path)
    native "LircTransmitter_GetLocalSocket";

/// Get SendPort for sending LIRC commands to file descriptor.
///
/// The returned SendPort accepts an array as paramter with the following
/// fields:
///
/// * File descriptor for LIRC socket (int)
/// * LIRC command to send to LIRC (String or null)
///
/// File Descriptor should come from [_getLircTransmitterLocalSocket].
///
/// [null] as LIRC command is interpreted as the file descriptor should be
/// closed. This could be a function on it own but by using the [SendPort] we
/// can ensure all LIRC commands has been handled before we close the file
/// descriptor.
SendPort _getLircTransmitterServicePort() native "LircTransmitter_ServicePort";
