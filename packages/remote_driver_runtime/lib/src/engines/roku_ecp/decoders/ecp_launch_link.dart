/// An ECP launch request: `appId` or `appId?contentId=…&mediaType=…`.
final class EcpLaunchLink {
  const EcpLaunchLink(this.id, this.parameters);

  final String id;
  final Map<String, String>? parameters;

  static const _mediaTypes = {
    'series',
    'season',
    'episode',
    'movie',
    'shortFormVideo',
    'tvSpecial',
  };

  static EcpLaunchLink? parse(String target) {
    final split = target.indexOf('?');
    final id = split < 0 ? target : target.substring(0, split);
    if (id.isEmpty) {
      return null;
    }
    if (split < 0) {
      return EcpLaunchLink(id, null);
    }
    final Map<String, String> query;
    try {
      query = Uri.splitQueryString(target.substring(split + 1));
    } on FormatException {
      return null;
    }
    final contentId = query['contentId'];
    final mediaType = query['mediaType'];
    final valid =
        query.keys.every((key) => key == 'contentId' || key == 'mediaType') &&
        contentId != null &&
        contentId.isNotEmpty &&
        contentId.length < 255 &&
        (mediaType == null || _mediaTypes.contains(mediaType));
    return valid ? EcpLaunchLink(id, query) : null;
  }
}
