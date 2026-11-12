import 'package:remote_core/remote_core.dart';

import '../../common/engine_parameters.dart';
import '../../common/payload_template.dart';
import '../pointer/pointer_button_frame.dart';
import 'ssap_kinds.dart';
import 'ssap_operation.dart';

/// Validates SSAP mappings: allow-listed URIs, bounded payload templates and
/// a closed set of decoders. Nothing outside this vocabulary reaches a TV.
abstract final class SsapOperationCompiler {
  /// Service namespaces an integration may address.
  static final uri = RegExp(
    r'^ssap://(?:audio|system|system\.launcher|media\.controls|tv|'
    r'com\.webos\.[a-zA-Z]+(?:\.[a-zA-Z]+)*|com\.palm\.[a-zA-Z]+(?:\.[a-zA-Z]+)*)'
    r'(?:/[a-zA-Z][a-zA-Z0-9]{0,63}){1,3}$',
  );
  static final _service = RegExp(
    r'^ssap://com\.webos\.[a-zA-Z]+(?:\.[a-zA-Z]+)*$',
  );
  static final _identifier = RegExp(r'^[a-zA-Z0-9._-]{1,128}$');
  static final _prefix = RegExp(r'^[a-zA-Z0-9._ -]{1,64}$');

  static SsapOperation compile(OperationMapping mapping) {
    final values = EngineParameters(mapping.kind, mapping.parameters);
    final parameters = switch (mapping.kind) {
      SsapKinds.request => _request(values, mapping.parameters),
      SsapKinds.subscribe => _subscribe(values),
      SsapKinds.pointerOpen => _uriOnly(values),
      SsapKinds.pointerButton => _button(values),
      SsapKinds.pointerMove ||
      SsapKinds.pointerScroll ||
      SsapKinds.pointerClick => _none(values),
      SsapKinds.readContent => _content(values),
      SsapKinds.launch => _launch(values),
      SsapKinds.launchReported => _launchReported(values, mapping.parameters),
      SsapKinds.toggleAccessory => _accessory(values),
      SsapKinds.identify => _identify(values),
      SsapKinds.wakeAddress => _wake(values),
      _ => throw FormatException('Unknown SSAP operation ${mapping.kind}.'),
    };
    return SsapOperation(mapping.kind, Map.unmodifiable(parameters));
  }

  static Map<String, Object?> _request(
    EngineParameters values,
    Map<String, Object?> raw,
  ) {
    values.only(
      const {'uri', 'payload', 'result', 'muteUri', 'timeoutMs'},
      required: const {'uri'},
    );
    final result = raw['result'] == null
        ? 'none'
        : values.choice('result', SsapKinds.decoders);
    return {
      'uri': values.string('uri', uri),
      'payload': PayloadTemplate.parse(
        raw['payload'],
        PayloadTemplate.arguments,
      ).template,
      'result': result,
      'muteUri': values.optionalString('muteUri', uri),
      'timeoutMs': values.optionalInteger(
        'timeoutMs',
        minimum: 100,
        maximum: 30000,
      ),
    };
  }

  static Map<String, Object?> _subscribe(EngineParameters values) {
    values.only(
      const {
        'uri',
        'result',
        'muteUri',
        'applicationsUri',
        'channelUri',
        'liveTvApplicationId',
        'inputApplicationPrefix',
        'inputIdPrefix',
        'inputNamePrefix',
      },
      required: const {'uri', 'result'},
    );
    final result = values.choice('result', const {'volume', 'content'});
    return {
      ...(result == 'content' ? _contentFields(values) : const {}),
      'uri': values.string('uri', uri),
      'result': result,
      'muteUri': values.optionalString('muteUri', uri),
    };
  }

  static Map<String, Object?> _uriOnly(EngineParameters values) {
    values.only(const {'uri'}, required: const {'uri'});
    return {'uri': values.string('uri', uri)};
  }

  static Map<String, Object?> _button(EngineParameters values) {
    values.only(const {'button'}, required: const {'button'});
    return {'button': values.string('button', pointerButtonName)};
  }

  static Map<String, Object?> _none(EngineParameters values) {
    values.only(const {});
    return const {};
  }

  static Map<String, Object?> _content(EngineParameters values) {
    values.only(
      const {
        'uri',
        'applicationsUri',
        'channelUri',
        'liveTvApplicationId',
        'inputApplicationPrefix',
        'inputIdPrefix',
        'inputNamePrefix',
      },
      required: const {'uri'},
    );
    return {'uri': values.string('uri', uri), ..._contentFields(values)};
  }

  static Map<String, Object?> _contentFields(EngineParameters values) => {
    'applicationsUri': values.optionalString('applicationsUri', uri),
    'channelUri': values.optionalString('channelUri', uri),
    'liveTvApplicationId': values.optionalString(
      'liveTvApplicationId',
      _identifier,
    ),
    'inputApplicationPrefix': values.optionalString(
      'inputApplicationPrefix',
      _identifier,
    ),
    'inputIdPrefix': values.optionalString('inputIdPrefix', _prefix),
    'inputNamePrefix': values.optionalString('inputNamePrefix', _prefix),
  };

  static Map<String, Object?> _launch(EngineParameters values) {
    values.only(const {'uri', 'openUri'}, required: const {'uri'});
    return {
      'uri': values.string('uri', uri),
      'openUri': values.optionalString('openUri', uri),
    };
  }

  static Map<String, Object?> _launchReported(
    EngineParameters values,
    Map<String, Object?> raw,
  ) {
    values.only(
      const {'uri', 'applicationId', 'params'},
      required: const {'uri', 'applicationId'},
    );
    return {
      'uri': values.string('uri', uri),
      'applicationId': values.string('applicationId', _identifier),
      'params': PayloadTemplate.parse(raw['params'], const {}).template,
    };
  }

  static Map<String, Object?> _accessory(EngineParameters values) {
    values.only(
      const {'uri', 'connectUri', 'disconnectUri'},
      required: const {'uri', 'connectUri', 'disconnectUri'},
    );
    return {
      'uri': values.string('uri', uri),
      'connectUri': values.string('connectUri', uri),
      'disconnectUri': values.string('disconnectUri', uri),
    };
  }

  static Map<String, Object?> _identify(EngineParameters values) {
    values.only(
      const {'uri', 'osVersionPrefix', 'operatingSystem'},
      required: const {'uri'},
    );
    return {
      'uri': values.string('uri', uri),
      'operatingSystem': values.optionalString('operatingSystem', _prefix),
      'osVersionPrefix': values.optionalString('osVersionPrefix', _prefix),
    };
  }

  static Map<String, Object?> _wake(EngineParameters values) {
    values.only(const {'service'}, required: const {'service'});
    return {'service': values.string('service', _service)};
  }
}
