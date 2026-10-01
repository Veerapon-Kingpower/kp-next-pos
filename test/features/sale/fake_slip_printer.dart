import 'package:kp_pos/core/printing/slip_printer.dart';

/// Records what would have been printed, in order; [error] fails each print.
class FakeSlipPrinter implements SlipPrinter {
  final List<String> printed = [];
  Exception? error;

  @override
  Future<void> printImageUrl(String url) async {
    printed.add('image:$url');
    if (error != null) throw error!;
  }

  @override
  Future<void> printText(String text) async {
    printed.add('text:$text');
    if (error != null) throw error!;
  }
}
