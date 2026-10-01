import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/presentation/desktop/desktop.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/overlay_panel.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cart_item.dart';
import '../sale_cart_view_model.dart';
import '../widgets/line_editor.dart';

/// Opens the desktop Edit line overlay for a Buying [line] — legacy
/// `EditSalePage` ("Edit Detail"): qty, serial, Freeze, Lock and Collect /
/// Take ([LineEditFields]) with Undo / Save / Save & close.
Future<void> showDesktopEditLineOverlay(
  BuildContext context, {
  required SaleCartViewModel viewModel,
  required CartItem line,
  required String title,
  required bool isAirportMpos,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.55),
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(40),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: TestId(
          EditLineIds.page,
          child: OverlayPanel(
            title: title,
            onClose: () => Navigator.of(dialogContext).pop(),
            child: _EditLineBody(
              viewModel: viewModel,
              row: line.row,
              isAirportMpos: isAirportMpos,
            ),
          ),
        ),
      ),
    ),
  );
}

class _EditLineBody extends StatefulWidget {
  final SaleCartViewModel viewModel;
  final String row;
  final bool isAirportMpos;

  const _EditLineBody({
    required this.viewModel,
    required this.row,
    required this.isAirportMpos,
  });

  @override
  State<_EditLineBody> createState() => _EditLineBodyState();
}

class _EditLineBodyState extends State<_EditLineBody> {
  LineEditDraft? _draft;

  @override
  void dispose() {
    _draft?.dispose();
    super.dispose();
  }

  CartItem? get _line {
    for (final item in widget.viewModel.cart?.items ?? const <CartItem>[]) {
      if (item.row == widget.row) return item;
    }
    return null;
  }

  /// Nothing changed: just closes, with no call.
  Future<void> _saveAndClose(CartItem line, LineEditDraft draft) async {
    final ok =
        !draft.isChanged ||
        await saveLineEdit(context, widget.viewModel, line, draft);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleCartViewModel>(
      init: widget.viewModel,
      global: false,
      builder: (viewModel) {
        final line = _line;
        if (line == null) return const SizedBox.shrink();
        final draft = _draft ??= LineEditDraft(line);
        final busy = viewModel.isBusy;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: LineEditFields(
                  viewModel: viewModel,
                  line: line,
                  draft: draft,
                  showPickup: !widget.isAirportMpos,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: ListenableBuilder(
                listenable: draft,
                builder: (context, _) => Row(
                  children: [
                    Expanded(
                      child: DesktopButton(
                        id: EditLineIds.undoButton,
                        label: 'Undo',
                        icon: Icons.undo,
                        secondary: true,
                        height: 48,
                        onPressed: draft.isChanged ? draft.undo : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DesktopButton(
                        id: EditLineIds.saveButton,
                        label: 'Save',
                        secondary: true,
                        height: 48,
                        onPressed: busy || !draft.isChanged
                            ? null
                            : () =>
                                  saveLineEdit(context, viewModel, line, draft),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DesktopButton(
                        id: EditLineIds.saveCloseButton,
                        label: 'Save & close',
                        icon: Icons.check,
                        height: 48,
                        onPressed: busy
                            ? null
                            : () => _saveAndClose(line, draft),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
