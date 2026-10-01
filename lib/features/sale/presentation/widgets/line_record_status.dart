import 'package:flutter/material.dart';

import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cart_item.dart';

/// Legacy Sale's status icon on a line with `recordInfos`: red for an
/// `Error` (`isRequireOnly`), amber for warnings only (`isWarning`). Tap
/// lists the messages ([showLineRecordInfos]). Nothing when there are none.
class LineRecordStatus extends StatelessWidget {
  final CartItem line;
  final double size;

  const LineRecordStatus({super.key, required this.line, this.size = 20});

  @override
  Widget build(BuildContext context) {
    if (line.recordInfos.isEmpty) return const SizedBox.shrink();
    final error = line.hasRecordError;
    return TestId(
      SaleIds.lineStatus(line.row),
      child: Semantics(
        button: true,
        label: error ? 'Line has errors' : 'Line has warnings',
        child: InkResponse(
          radius: size,
          onTap: () => showLineRecordInfos(context, line),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.warning_amber_rounded,
              size: size,
              color: error ? AppColors.danger : AppColors.warning,
            ),
          ),
        ),
      ),
    );
  }
}

/// Legacy `showPopUpErr()`: the line's `MessageDesc`s as a list, titled
/// ERROR or WARNING.
Future<void> showLineRecordInfos(BuildContext context, CartItem line) =>
    showDialog<void>(
      context: context,
      builder: (context) => TestId(
        SaleIds.lineStatusDialog,
        child: AlertDialog(
          title: Text(line.hasRecordError ? 'ERROR' : 'WARNING'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final info in line.recordInfos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text(info.desc)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
