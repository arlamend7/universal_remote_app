import 'fake_transport.dart';

void standardResponses(FakeTransport socket, {bool unsupportedVolume = false}) {
  socket.respond = (request) {
    if (request['type'] == 'register') {
      socket.reply(request, {'client-key': 'secret'}, type: 'registered');
      return;
    }
    switch (request['uri']) {
      case 'ssap://audio/getVolume':
        if (unsupportedVolume) {
          socket.reject(request, '404 no such service');
        } else {
          socket.reply(request, {
            'returnValue': true,
            'volume': 30,
            'muted': false,
          });
        }
      case 'ssap://com.webos.applicationManager/listApps':
        socket.reply(request, {
          'apps': [
            {'id': 'device.actual.app', 'title': 'Example'},
            {'id': 'device.actual.app', 'title': 'Duplicate'},
            {'id': 'internal.service', 'title': 'Internal', 'visible': false},
          ],
        });
      case 'ssap://tv/getExternalInputList':
        socket.reply(request, {
          'devices': [
            {'id': 'HDMI_2', 'label': 'Console'},
          ],
        });
      case 'ssap://com.webos.service.networkinput/getPointerInputSocket':
        socket.reply(request, {'socketPath': 'ws://192.168.1.20:3000/pointer'});
      default:
        socket.reply(request, {'returnValue': true});
    }
  };
}
