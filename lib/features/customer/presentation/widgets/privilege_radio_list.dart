import 'package:flutter/material.dart';

import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/privilege.dart';

/// "Select privilege" — one card holding a single-select radio list: a
/// "No privilege" row (the default) followed by each of the customer's
/// privileges as `Name` over `[TypeCode]:PromoCode` (legacy's picker
/// label). The chosen row gets a gold edge and cream fill. Shared by the
/// desktop Customers tab and the handheld profile.
class PrivilegeRadioList extends StatelessWidget {
  final List<Privilege> privileges;
  final Privilege? selected;
  final ValueChanged<Privilege?> onChanged;

  const PrivilegeRadioList({
    super.key,
    required this.privileges,
    required this.selected,
    required this.onChanged,
  });

  static String code(Privilege p) => p.typeCode.isEmpty && p.promoCode.isEmpty
      ? ''
      : '[${p.typeCode}]:${p.promoCode}';

  @override
  Widget build(BuildContext context) {
    return TestId(
      ProfileIds.privileges,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'SELECT PRIVILEGE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                  Text(
                    privileges.isEmpty
                        ? 'None on this card'
                        : '${privileges.length} available',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            _Option(
              id: ProfileIds.noPrivilege,
              title: 'No privilege',
              subtitle: 'Sell at normal price',
              icon: Icons.block,
              selected: selected == null,
              onTap: () => onChanged(null),
            ),
            for (var i = 0; i < privileges.length; i++)
              _Option(
                id: ProfileIds.privilege(i),
                title: privileges[i].name.isEmpty
                    ? 'Privilege'
                    : privileges[i].name,
                subtitle: code(privileges[i]),
                icon: Icons.card_giftcard,
                selected: identical(selected, privileges[i]),
                onTap: () => onChanged(privileges[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
      id,
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.fromLTRB(13, 10, 16, 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.cream : null,
              border: Border(
                top: const BorderSide(color: AppColors.line),
                left: BorderSide(
                  width: 3,
                  color: selected ? AppColors.goldDark : Colors.transparent,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? AppColors.goldDark : AppColors.hintText,
                ),
                const SizedBox(width: 12),
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AppColors.goldDark : AppColors.mutedText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
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
