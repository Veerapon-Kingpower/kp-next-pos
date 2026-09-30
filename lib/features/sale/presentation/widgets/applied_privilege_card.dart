import 'package:flutter/material.dart';

import '../../../../core/presentation/desktop/desktop.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../customer/domain/entities/privilege.dart';

/// The privilege the order is priced with, on the Sale page (desktop bill
/// summary, handheld above the lines): the name gets the full width, the
/// legacy `[TypeCode]:PromoCode` code on its own line under it, and Change
/// sits on the heading line above; a member with none reads "No Privilege" / `[No Privilege]`. [onChange] is legacy's Privilege Selection; null
/// renders it inert.
class AppliedPrivilegeCard extends StatelessWidget {
  final Privilege? privilege;
  final VoidCallback? onChange;

  /// Show the Change link (a member).
  final bool canChange;

  /// Handheld: a full-bleed strip with its own padding.
  final bool compact;

  const AppliedPrivilegeCard({
    super.key,
    required this.privilege,
    required this.onChange,
    this.canChange = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = privilege;
    final none = p == null;
    final name = none
        ? 'No Privilege'
        : p.name.trim().isEmpty
        ? 'Privilege'
        : p.name.trim();
    // Legacy `sale.html`'s `[TypeCode]:PromoCode`, on its own line.
    final code = none
        ? '[No Privilege]'
        : p.typeCode.isEmpty && p.promoCode.isEmpty
        ? ''
        : '[${p.typeCode}]:${p.promoCode}';

    final header = Row(
      children: [
        const Expanded(
          child: Text('APPLIED PRIVILEGE', style: DesktopText.fieldLabel),
        ),
        if (canChange)
          TestId(
            SaleIds.privilegeChangeButton,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.goldDark,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFEBDDBF)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.swap_horiz, size: 14),
              label: const Text('Change'),
              onPressed: onChange,
            ),
          ),
      ],
    );

    final card = TestId(
      SaleIds.privilege,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: none ? const Color(0xFFF7F8FA) : AppColors.cream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: none ? const Color(0xFFE3E7ED) : const Color(0xFFEBDDBF),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: none
                    ? const Color(0xFFE9ECF1)
                    : AppColors.gold.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                none ? Icons.card_giftcard_outlined : Icons.card_giftcard,
                size: 16,
                color: none ? AppColors.hintText : AppColors.goldDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: none ? AppColors.mutedText : AppColors.ink,
                    ),
                  ),
                  if (code.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: none ? AppColors.hintText : AppColors.goldDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, const SizedBox(height: 6), card],
    );
    // Room below before the bill buttons / the lines.
    if (!compact) {
      return Padding(padding: const EdgeInsets.only(bottom: 12), child: body);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: body,
    );
  }
}
