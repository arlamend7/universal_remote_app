import 'dart:async';

import 'package:remote_network/src/transport/contracts/text_transport.dart';

typedef TransportConnector = Future<TextTransport> Function(Uri endpoint);
