import 'clock.dart';

enum LogLevel { info, warning, error }

enum SpanStatus { started, ok, error }

const _safeAttributeKeys = {
  'route_name',
  'status_class',
  'safe_error_code',
  'duration_ms',
  'region',
  'adherence',
  'wellbeing',
  'has_note',
  'retryable',
  'correlation_id',
  'span_name',
  'metric_name',
};

Map<String, Object?> allowSafeAttributes(Map<String, Object?> raw) {
  return {
    for (final entry in raw.entries)
      if (_safeAttributeKeys.contains(entry.key)) entry.key: entry.value,
  };
}

class StructuredLog {
  const StructuredLog({
    required this.eventName,
    required this.level,
    required this.timestamp,
    required this.attributes,
  });

  final String eventName;
  final LogLevel level;
  final DateTime timestamp;
  final Map<String, Object?> attributes;

  Map<String, Object?> toJson() => {
    'event_name': eventName,
    'level': level.name,
    'timestamp': timestamp.toIso8601String(),
    'attributes': attributes,
  };
}

class SpanRecord {
  SpanRecord({
    required this.name,
    required this.correlationId,
    required this.start,
    this.parentName,
    this.attributes = const {},
    this.status = SpanStatus.started,
    this.end,
  });

  final String name;
  final String correlationId;
  final DateTime start;
  final String? parentName;
  final Map<String, Object?> attributes;
  SpanStatus status;
  DateTime? end;

  int? get durationMs => end?.difference(start).inMilliseconds;

  Map<String, Object?> toJson() => {
    'span_name': name,
    'correlation_id': correlationId,
    'parent_name': parentName,
    'status': status.name,
    'duration_ms': durationMs,
    'attributes': attributes,
  };
}

class SanitizedErrorRecord {
  const SanitizedErrorRecord({
    required this.safeCode,
    required this.correlationId,
    required this.timestamp,
    required this.attributes,
    required this.crash,
  });

  final String safeCode;
  final String correlationId;
  final DateTime timestamp;
  final Map<String, Object?> attributes;
  final bool crash;
}

class InMemoryObservability {
  InMemoryObservability({required this.clock});

  final Clock clock;
  final logs = <StructuredLog>[];
  final spans = <SpanRecord>[];
  final breadcrumbs = <Map<String, Object?>>[];
  final metrics = <String, int>{};
  final errors = <SanitizedErrorRecord>[];
  int crashCount = 0;
  int _counter = 0;

  String newCorrelationId() => 'corr_${++_counter}';

  void breadcrumb(String routeName, String correlationId) {
    breadcrumbs.add(
      allowSafeAttributes({
        'route_name': routeName,
        'correlation_id': correlationId,
      }),
    );
    if (breadcrumbs.length > 12) breadcrumbs.removeAt(0);
  }

  SpanRecord startSpan(
    String name,
    String correlationId, {
    String? parentName,
    Map<String, Object?> attributes = const {},
  }) {
    final span = SpanRecord(
      name: name,
      correlationId: correlationId,
      parentName: parentName,
      start: clock.now(),
      attributes: allowSafeAttributes(attributes),
    );
    spans.add(span);
    return span;
  }

  void endSpan(SpanRecord span, SpanStatus status) {
    span.status = status;
    span.end = clock.now();
  }

  void endOpenSpan(String name, String correlationId, SpanStatus status) {
    final index = spans.lastIndexWhere(
      (record) =>
          record.name == name &&
          record.correlationId == correlationId &&
          record.end == null,
    );
    if (index == -1) return;
    endSpan(spans[index], status);
  }

  void recordEvent(
    String eventName,
    LogLevel level,
    Map<String, Object?> attributes,
  ) {
    logs.add(
      StructuredLog(
        eventName: eventName,
        level: level,
        timestamp: clock.now(),
        attributes: allowSafeAttributes(attributes),
      ),
    );
  }

  void metric(String name, {int by = 1}) {
    metrics[name] = (metrics[name] ?? 0) + by;
  }

  void expectedError(
    String safeCode,
    String correlationId,
    Map<String, Object?> attributes,
  ) {
    errors.add(
      SanitizedErrorRecord(
        safeCode: safeCode,
        correlationId: correlationId,
        timestamp: clock.now(),
        attributes: allowSafeAttributes(attributes),
        crash: false,
      ),
    );
  }

  void unexpectedException(
    Object error,
    String correlationId,
    Map<String, Object?> attributes,
  ) {
    crashCount += 1;
    errors.add(
      SanitizedErrorRecord(
        safeCode: 'unexpected_exception',
        correlationId: correlationId,
        timestamp: clock.now(),
        attributes: allowSafeAttributes(attributes),
        crash: true,
      ),
    );
  }
}
