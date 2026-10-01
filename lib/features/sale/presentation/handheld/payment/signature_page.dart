import 'package:flutter/material.dart';

import '../../../../../core/presentation/handheld/handheld.dart';
import '../../../../../core/presentation/test_ids.dart';
import '../../../../../core/presentation/widgets/test_id.dart';
import '../../../../../core/theme/app_colors.dart';

typedef SignatureStrokes = List<List<Offset>>;

/// What the Signature page hands back on Save — the raw strokes for the
/// optional "Paid by" pad and the required customer pad.
class SignatureCapture {
  final SignatureStrokes paidBy;
  final SignatureStrokes customer;

  const SignatureCapture({required this.paidBy, required this.customer});
}

/// Pushes the Signature page; resolves to the capture on Save, or null on
/// Cancel / close.
Future<SignatureCapture?> openSignaturePage(
  BuildContext context, {
  required double netPay,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<SignatureCapture>(
      builder: (_) => SignaturePage(netPay: netPay),
    ),
  );
}

/// Signature pad (mockup screen 15). Capture is real and local; storing the
/// signature with the bill / reprinting it on the claim check needs a
/// bill-completion API, so the caller only keeps it in memory for now.
// TODO(pos-handheld): upload the signature with the completed bill.
class SignaturePage extends StatefulWidget {
  final double netPay;

  const SignaturePage({super.key, required this.netPay});

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  final SignatureStrokes _paidBy = [];
  final SignatureStrokes _customer = [];

  bool get _canSave => _customer.isNotEmpty;

  void _save() {
    Navigator.of(context).pop(
      SignatureCapture(
        paidBy: List.unmodifiable(_paidBy),
        customer: List.unmodifiable(_customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TestId(
      SignatureIds.page,
      child: HandheldScaffold(
        header: HandheldHeader(
          title: 'Signature',
          leading: TestId(
            SignatureIds.closeButton,
            child: IconButton(
              icon: const Icon(Icons.close),
              color: Colors.white,
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          trailing: TestId(
            SignatureIds.saveButton,
            child: FilledButton(
              onPressed: _canSave ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.ink,
                // The app theme's full-width minimum can't size in the
                // header's Row (unbounded width).
                minimumSize: const Size(0, 40),
              ),
              child: const Text('Save'),
            ),
          ),
          stats: [
            HandheldStat(
              id: 'signature.netPay',
              label: 'Net pay amount',
              value: formatBaht(widget.netPay),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(HandheldMetrics.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PadSection(
                title: 'Paid By',
                optional: true,
                padId: SignatureIds.paidByPad,
                clearId: SignatureIds.paidByClear,
                statusId: SignatureIds.paidByStatus,
                strokes: _paidBy,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 20),
              _PadSection(
                title: 'Customer Signature',
                padId: SignatureIds.customerPad,
                clearId: SignatureIds.customerClear,
                statusId: SignatureIds.customerStatus,
                strokes: _customer,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 14),
              const Text(
                'Please sign your name. The customer signature will be '
                'stored with the bill and reprinted on the claim check.',
                style: HandheldText.bodySmall,
              ),
            ],
          ),
        ),
        actionBar: HandheldActionBar(
          primary: HandheldPrimaryButton(
            id: SignatureIds.bottomSaveButton,
            label: 'Save signature',
            icon: Icons.check,
            onPressed: _canSave ? _save : null,
          ),
          secondary: HandheldSecondaryButton(
            id: SignatureIds.cancelButton,
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

class _PadSection extends StatelessWidget {
  final String title;
  final bool optional;
  final String padId;
  final String clearId;
  final String statusId;
  final SignatureStrokes strokes;
  final VoidCallback onChanged;

  const _PadSection({
    required this.title,
    required this.padId,
    required this.clearId,
    required this.statusId,
    required this.strokes,
    required this.onChanged,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    final captured = strokes.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    TextSpan(
                      text: optional ? ' · optional' : ' *',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: optional
                            ? AppColors.mutedText
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TestId(
              clearId,
              child: OutlinedButton.icon(
                onPressed: captured
                    ? () {
                        strokes.clear();
                        onChanged();
                      }
                    : null,
                icon: const Icon(Icons.undo, size: 14),
                label: const Text('Clear'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TestId(
          padId,
          child: Semantics(
            label: '$title pad',
            child: _SignaturePad(strokes: strokes, onChanged: onChanged),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TestId(
            statusId,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: captured ? const Color(0xFFE7F8F1) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                captured ? 'Captured' : 'Empty — pad ready',
                style: TextStyle(
                  fontSize: 12,
                  color: captured
                      ? const Color(0xFF0F6947)
                      : AppColors.mutedText,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignaturePad extends StatelessWidget {
  final SignatureStrokes strokes;
  final VoidCallback onChanged;

  const _SignaturePad({required this.strokes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFD),
        borderRadius: BorderRadius.circular(HandheldMetrics.radius),
        border: Border.all(
          color: strokes.isEmpty ? AppColors.line : AppColors.goldMuted,
          width: strokes.isEmpty ? 1 : 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HandheldMetrics.radius),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) {
            strokes.add([d.localPosition]);
            onChanged();
          },
          onPanUpdate: (d) {
            if (strokes.isEmpty) strokes.add([]);
            strokes.last.add(d.localPosition);
            onChanged();
          },
          child: CustomPaint(
            painter: _SignaturePainter(strokes),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final SignatureStrokes strokes;

  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 34;
    canvas.drawLine(
      Offset(20, baseline),
      Offset(size.width - 20, baseline),
      Paint()
        ..color = AppColors.line
        ..strokeWidth = 1,
    );
    final hint = TextPainter(
      text: const TextSpan(
        text: 'Sign above the line',
        style: TextStyle(fontSize: 11, color: Color(0xFFC3C9D2)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hint.paint(canvas, Offset(20, baseline + 6));

    final ink = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.2, ink..style = PaintingStyle.fill);
        ink.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, ink);
    }
  }

  // Strokes are mutated in place, so always repaint on rebuild.
  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}
