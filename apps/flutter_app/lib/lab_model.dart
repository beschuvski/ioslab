/// Pure Dart model of the lab checklist.
///
/// It contains no Flutter imports so it can be unit-tested with plain
/// `dart test` semantics and reused by the widget layer.
library;

enum CheckStatus { pass, pending }

class LabCheck {
  const LabCheck({
    required this.id,
    required this.title,
    required this.detail,
    this.status = CheckStatus.pending,
  });

  final String id;
  final String title;
  final String detail;
  final CheckStatus status;

  LabCheck copyWith({CheckStatus? status}) {
    return LabCheck(
      id: id,
      title: title,
      detail: detail,
      status: status ?? this.status,
    );
  }
}

class LabModel {
  LabModel({List<LabCheck>? checks})
    : _checks = List<LabCheck>.of(checks ?? defaultChecks);

  static const List<LabCheck> defaultChecks = <LabCheck>[
    LabCheck(
      id: 'analyze',
      title: 'Analyze',
      detail: 'dart analyze --fatal-infos',
      status: CheckStatus.pass,
    ),
    LabCheck(
      id: 'tests',
      title: 'Tests',
      detail: 'flutter test · unit + widget',
      status: CheckStatus.pass,
    ),
    LabCheck(
      id: 'render',
      title: 'Render',
      detail: 'iOS Simulator · 393 × 852 pt',
      status: CheckStatus.pending,
    ),
  ];

  final List<LabCheck> _checks;

  List<LabCheck> get checks => List<LabCheck>.unmodifiable(_checks);

  int get total => _checks.length;

  int get passed => _checks.where((c) => c.status == CheckStatus.pass).length;

  String get summary => '$passed/$total checks passing';

  bool get isComplete => passed == total;

  /// Promotes the first pending check; returns false when nothing is pending.
  bool runNextCheck() {
    final int index = _checks.indexWhere(
      (c) => c.status == CheckStatus.pending,
    );
    if (index < 0) {
      return false;
    }
    _checks[index] = _checks[index].copyWith(status: CheckStatus.pass);
    return true;
  }
}
