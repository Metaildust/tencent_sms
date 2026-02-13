import 'content_moderation_service.dart';

/// Global moderation service store for Serverpod process-level setup.
class ContentModerationServiceStore {
  static ContentModerationService? _service;

  static void configure({required ContentModerationService service}) {
    _service = service;
  }

  static ContentModerationService get instance {
    final service = _service;
    if (service == null) {
      throw StateError(
        'ContentModerationServiceStore not configured. '
        'Call configure() in server.dart before using moderation endpoints.',
      );
    }
    return service;
  }
}
