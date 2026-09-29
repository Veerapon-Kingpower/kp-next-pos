import 'package:flutter/material.dart';

import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/customer.dart';
import '../customer_summary.dart';

/// "Registration checks" rows — ✓ / ✕, label, and the value that satisfied
/// the check (see [registrationChecks]). Shared by the desktop Home result
/// and the handheld profile; the caller supplies the surrounding card.
class RegistrationChecksList extends StatelessWidget {
  final CustomerPerson person;
  final EdgeInsetsGeometry rowPadding;

  const RegistrationChecksList({
    super.key,
    required this.person,
    this.rowPadding = const EdgeInsets.symmetric(vertical: 11),
  });

  @override
  Widget build(BuildContext context) {
    final checks = registrationChecks(person);
    return TestId(
      ProfileIds.registrationChecks,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < checks.length; i++)
            TestId(
              ProfileIds.check(i),
              child: _CheckRow(
                check: checks[i],
                padding: rowPadding,
                last: i == checks.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final RegistrationCheck check;
  final EdgeInsetsGeometry padding;
  final bool last;

  const _CheckRow({
    required this.check,
    required this.padding,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final color = check.passed ? AppColors.success : AppColors.danger;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              check.passed ? Icons.check : Icons.close,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              check.label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (check.detail.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              check.detail,
              style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
            ),
          ],
        ],
      ),
    );
  }
}
