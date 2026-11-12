/// The legacy `software` step with an operating-system version the migrated
/// runtime now identifies (the legacy code stored but never parsed it).
Object? Function(Object?) softwareImprovement(String version) =>
    (Object? legacy) {
      final step = Map<String, Object?>.from(legacy! as Map);
      final result = Map<String, Object?>.from(step['result']! as Map);
      final session = Map<String, Object?>.from(result['session']! as Map);
      session['operatingSystemVersion'] = version;
      result['session'] = session;
      step['result'] = result;
      return step;
    };
