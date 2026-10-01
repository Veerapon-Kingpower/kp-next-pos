import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cart_item.dart';
import '../sale_cart_view_model.dart';
import '../widgets/line_editor.dart';

/// Pushes the Edit line page for cart [row]. [isAirportMpos] hides Pickup,
/// as legacy does.
Future<void> openEditLinePage(
  BuildContext context, {
  required SaleCartViewModel viewModel,
  required String row,
  required int lineNumber,
  bool isAirportMpos = false,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => EditLinePage(
        viewModel: viewModel,
        row: row,
        lineNumber: lineNumber,
        isAirportMpos: isAirportMpos,
      ),
    ),
  );
}

/// Edit line · Order item (mockup screen 14) — legacy `EditSalePage`
/// ("Edit Detail"): qty, serial, Freeze, Lock and Collect / Take saved
/// together ([saveLineEdit]), CITES / VAS details, plus voiding the line.
class EditLinePage extends StatefulWidget {
  final SaleCartViewModel viewModel;
  final String row;
  final int lineNumber;
  final bool isAirportMpos;

  const EditLinePage({
    super.key,
    required this.viewModel,
    required this.row,
    required this.lineNumber,
    this.isAirportMpos = false,
  });

  @override
  State<EditLinePage> createState() => _EditLinePageState();
}

class _EditLinePageState extends State<EditLinePage> {
  LineEditDraft? _draft;

  CartItem? get _line {
    final items = widget.viewModel.cart?.items ?? const <CartItem>[];
    for (final item in items) {
      if (item.row == widget.row) return item;
    }
    return null;
  }

  @override
  void dispose() {
    _draft?.dispose();
    super.dispose();
  }

  /// Nothing changed: just closes, with no call.
  Future<void> _saveAndClose(CartItem line, LineEditDraft draft) async {
    final ok =
        !draft.isChanged ||
        await saveLineEdit(context, widget.viewModel, line, draft);
    if (ok && mounted) Navigator.of(context).pop();
  }

  Future<void> _void(CartItem line) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Void this line?',
      message: line.articleName.isEmpty ? line.articleCode : line.articleName,
      confirmLabel: 'Void line',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await widget.viewModel.removeItem(line.row);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleCartViewModel>(
      init: widget.viewModel,
      global: false,
      builder: (viewModel) {
        final line = _line;
        if (line == null) {
          // Removed elsewhere (or voided here) — nothing left to edit.
          return const Scaffold(body: SizedBox.shrink());
        }
        final draft = _draft ??= LineEditDraft(line);
        return _buildPage(context, viewModel, line, draft);
      },
    );
  }

  Widget _buildPage(
    BuildContext context,
    SaleCartViewModel viewModel,
    CartItem line,
    LineEditDraft draft,
  ) {
    final busy = viewModel.isBusy;

    return TestId(
      EditLineIds.page,
      child: HandheldScaffold(
        header: ListenableBuilder(
          listenable: draft,
          builder: (context, _) => _EditLineHeader(
            lineNumber: widget.lineNumber,
            onUndo: draft.isChanged ? draft.undo : null,
            onSave: busy || !draft.isChanged
                ? null
                : () => saveLineEdit(context, viewModel, line, draft),
            onSaveClose: busy ? null : () => _saveAndClose(line, draft),
          ),
        ),
        backgroundColor: AppColors.surface,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LineEditFields(
                viewModel: viewModel,
                line: line,
                draft: draft,
                showPickup: !widget.isAirportMpos,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: TestId(
                  EditLineIds.voidButton,
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => _void(line),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Void line'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      minimumSize: const Size.fromHeight(
                        HandheldMetrics.primaryActionHeight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditLineHeader extends StatelessWidget {
  final int lineNumber;
  final VoidCallback? onUndo;
  final VoidCallback? onSave;
  final VoidCallback? onSaveClose;

  const _EditLineHeader({
    required this.lineNumber,
    required this.onUndo,
    required this.onSave,
    required this.onSaveClose,
  });

  @override
  Widget build(BuildContext context) {
    Widget outlined(
      String id,
      String label,
      VoidCallback? onTap, {
      IconData? icon,
    }) => Expanded(
      child: TestId(
        id,
        child: SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: icon == null
                ? const SizedBox.shrink()
                : Icon(icon, size: 14, color: AppColors.gold),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ),
    );

    return ColoredBox(
      color: AppColors.ink,
      child: SafeArea(
        bottom: false,
        child: HandheldContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const BackButton(color: Colors.white),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order item',
                            style: HandheldText.title.copyWith(
                              fontSize: 17,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Line $lineNumber',
                            style: HandheldText.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      outlined(
                        EditLineIds.undoButton,
                        'Undo',
                        onUndo,
                        icon: Icons.undo,
                      ),
                      const SizedBox(width: 8),
                      outlined(EditLineIds.saveButton, 'Save', onSave),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TestId(
                          EditLineIds.saveCloseButton,
                          child: SizedBox(
                            height: 44,
                            child: FilledButton(
                              onPressed: onSaveClose,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.ink,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: const Text(
                                'Save & close',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
