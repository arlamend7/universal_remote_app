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
      case 'ssap://com.webos.applicationManager/getForegroundAppInfo':
        socket.reply(request, {'appId': 'com.webos.app.hdmi2'});
      case 'ssap://tv/getChannelList':
        socket.reply(request, {
          'channelList': [
            {
              'channelId': 'channel-7',
              'channelName': 'Local',
              'channelNumber': '7',
            },
          ],
        });
      case 'ssap://com.webos.service.btaudiosrc/getPairedDevices':
        socket.reply(request, {
          'devices': [
            {
              'address': '00:11:22:33:44:55',
              'name': 'Soundbar',
              'state': 'disconnected',
            },
          ],
        });
      case 'ssap://com.webos.service.update/getCurrentSWInformation':
        socket.reply(request, {
          'product_name': 'webOSTV 5.0',
          'model_name': 'Fixture LG',
          'sw_type': 'FIRMWARE',
          'major_ver': '04',
          'minor_ver': '50.56',
        });
      case 'ssap://com.webos.service.networkinput/getPointerInputSocket':
        socket.reply(request, {'socketPath': 'ws://192.168.1.20:3000/pointer'});
      default:
        socket.reply(request, {'returnValue': true});
    }
  };
}
