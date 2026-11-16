import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';

import 'lab_model.dart';

const Color _accent = Color(0xFF0071E3);
const Color _card = Color(0xFFFFFFFF);

class LabPage extends StatefulWidget {
  const LabPage({super.key});

  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> {
  final LabModel _model = LabModel();

  void _runNextCheck() {
    setState(_model.runNextCheck);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _Header(),
              const SizedBox(height: 24),
              _SummaryCard(model: _model),
              const SizedBox(height: 16),
              _CheckList(checks: _model.checks),
              const SizedBox(height: 24),
              _RunButton(enabled: !_model.isComplete, onPressed: _runNextCheck),
              const SizedBox(height: 14),
              const Text(
                'macOS 26 runner · Xcode 27 · Simulator',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: CupertinoColors.tertiaryLabel,
                  fontFamily: 'Menlo',
                  fontFamilyFallback: <String>['monospace'],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const <Widget>[
        Text(
          'iOS Lab',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: CupertinoColors.label,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Flutter · iOS 26 SDK · CI',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.secondaryLabel,
            fontFamily: 'Menlo',
            fontFamilyFallback: <String>['monospace'],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.model});

  final LabModel model;

  @override
  Widget build(BuildContext context) {
    final double progress = model.total == 0 ? 0 : model.passed / model.total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            model.summary.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: CupertinoColors.secondaryLabel,
              fontFamily: 'Menlo',
              fontFamilyFallback: <String>['monospace'],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                '${model.passed}',
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${model.total}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 44,
                height: 44,
                child: CustomPaint(painter: _RingPainter(progress: progress)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 - 3;

    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = _accent.withValues(alpha: 0.15);
    canvas.drawCircle(center, radius, track);

    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = _accent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CheckList extends StatelessWidget {
  const _CheckList({required this.checks});

  final List<LabCheck> checks;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < checks.length; i++) {
      final LabCheck check = checks[i];
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: check.status == CheckStatus.pass
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF9500),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      check.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      check.detail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                        fontFamily: 'Menlo',
                        fontFamilyFallback: <String>['monospace'],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                check.status == CheckStatus.pass ? 'PASS' : 'PENDING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: check.status == CheckStatus.pass
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF9500),
                  fontFamily: 'Menlo',
                  fontFamilyFallback: <String>['monospace'],
                ),
              ),
            ],
          ),
        ),
      );
      if (i < checks.length - 1) {
        rows.add(
          const SizedBox(
            height: 1,
            child: ColoredBox(color: Color(0x14000000)),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: rows),
    );
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: enabled ? onPressed : null,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? _accent : const Color(0xFFC7C7CC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          enabled ? 'Run next check' : 'All checks passed',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }
}
