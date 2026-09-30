import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/presentation/desktop/desktop.dart';
import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../customer/domain/entities/privilege.dart';
import '../sale_cart_view_model.dart';

/// Legacy Sale's "Privilege Selection" (`presentPrivilegeSelection`): the
/// member's privileges plus "No Privilege"; a different pick re-prices the
/// order through the sale engine ([SaleCartViewModel.changePrivilege]). A
/// failure keeps the current privilege and shows the server's message.
Future<void> changeOrderPrivilege(
  BuildContext context,
  SaleCartViewModel viewModel,
) async {
  final picked = await showPrivilegePicker(
    context,
    privileges: viewModel.privileges,
    current: viewModel.selectedPrivilege,
  );
  if (picked == null) return;
  final error = await viewModel.changePrivilege(picked.privilege);
  if (error != null && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oops !'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// The member's privileges in the currency picker's frame: a dialog on
/// desktop, a handheld sheet below it. Resolves to the pick (its
/// `privilege` null = No Privilege), or null when dismissed.
Future<({Privilege? privilege})?> showPrivilegePicker(
  BuildContext context, {
  required List<Privilege> privileges,
  required Privilege? current,
}) {
  final picker = PrivilegePicker(privileges: privileges, current: current);
  if (!AppBreakpoints.isWide(context)) {
    return showHandheldSheet<({Privilege? privilege})>(
      context,
      id: SaleIds.privilegePicker,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
        ),
        child: picker,
      ),
    );
  }
  return showDialog<({Privilege? privilege})>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.55),
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(40),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: TestId(
          SaleIds.privilegePicker,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 12, 12),
              child: picker,
            ),
          ),
        ),
      ),
    ),
  );
}

class PrivilegePicker extends StatelessWidget {
  final List<Privilege> privileges;
  final Privilege? current;

  const PrivilegePicker({
    super.key,
    required this.privileges,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    void close([({Privilege? privilege})? pick]) =>
        Navigator.of(context).pop(pick);

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: Focus(
        autofocus: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.card_giftcard, color: AppColors.goldDark),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Privilege Selection',
                    style: DesktopText.sectionTitle,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: close,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (var i = 0; i < privileges.length; i++)
                    _option(
                      id: SaleIds.privilegeOption(i),
                      title: privileges[i].name,
                      code: _code(privileges[i]),
                      selected: SaleCartViewModel.samePrivilege(
                        privileges[i],
                        current,
                      ),
                      onTap: () => close((privilege: privileges[i])),
                    ),
                  _option(
                    id: SaleIds.privilegeNone,
                    title: 'No Privilege',
                    code: '',
                    selected: current == null,
                    onTap: () => close((privilege: null)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _code(Privilege p) => p.typeCode.isEmpty && p.promoCode.isEmpty
      ? ''
      : '[${p.typeCode}]:${p.promoCode}';

  Widget _option({
    required String id,
    required String title,
    required String code,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return TestId(
      id,
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            color: selected ? const Color(0xFFFBF8F1) : null,
            padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (code.isNotEmpty)
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.goldDark,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color: selected ? AppColors.success : AppColors.hintText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
