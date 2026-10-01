import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/core/printing/slip_printer.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/finish_payment.dart';
import 'package:kp_pos/features/sale/domain/entities/print_documents.dart';
import 'package:kp_pos/features/sale/presentation/desktop/desktop_payment_page.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/payment_page.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';

import '../../../../helpers/test_id_finders.dart';
import '../../../../helpers/test_app.dart';
import '../../fake_sale_repository.dart';
import '../../fake_slip_printer.dart';
import '../handheld/sale_test_helpers.dart';

/// Legacy `onPrintInvice()` after Complete sale, on both layouts.
void main() {
  const paid = Cart(
    guid: 'order-1',
    orderNo: 'S-1',
    isCheckOut: true,
    items: [chanel],
    remaining: 0,
  );

  for (final desktop in [true, false]) {
    group(desktop ? 'desktop' : 'handheld', () {
      late FakeSaleRepository repo;
      late FakeSlipPrinter printer;
      var signedOut = 0;

      Future<void> pumpAndComplete(WidgetTester tester) async {
        setDeviceSize(tester, desktop ? const Size(1440, 900) : compactSize);
        signedOut = 0;
        final SaleCartViewModel viewModel = buildSaleViewModel(
          repo,
          cart: paid,
        );
        printer = viewModel.slipPrinter as FakeSlipPrinter;
        Future<void> signOut() async => signedOut++;
        await tester.pumpWidget(
          TestApp(
            home: desktop
                ? DesktopPaymentPage(
                    netPay: 5900,
                    viewModel: viewModel,
                    onSignOut: signOut,
                  )
                : PaymentPage(
                    netPay: 5900,
                    viewModel: viewModel,
                    onSignOut: signOut,
                  ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(byTestId(PaymentIds.completeSaleButton));
        await tester.pumpAndSettle();
        await tester.tap(byTestId(PaymentIds.finishConfirmOk));
        await tester.pumpAndSettle();
      }

      Future<void> ok(WidgetTester tester) async {
        await tester.tap(byTestId(PaymentIds.printPageOk));
        await tester.pumpAndSettle();
      }

      setUp(() => repo = FakeSaleRepository(cartResult: paid));

      testWidgets('every page in legacy order, one dialog each, then sign '
          'out', (tester) async {
        repo.printAnswer = const PrintInvoiceAnswer(
          completed: true,
          documents: PrintDocuments(
            invoice: PrintDocumentSet(
              original: ['o1', 'o2'],
              copy: ['c1'],
              confirm: ['f1'],
            ),
            cpn: PrintDocumentSet(copy: ['cpn1']),
            lv: PrintDocumentSet(copy: ['LV slip']),
            cashCard: PrintDocumentSet(original: ['CC o'], copy: ['CC c']),
          ),
        );
        await pumpAndComplete(tester);
        expect(repo.invoicePrints, ['S-1']);

        final seen = <String>[];
        while (byTestId(PaymentIds.printPage).evaluate().isNotEmpty) {
          final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
          seen.add(
            '${(dialog.title! as Text).data} ${(dialog.content! as Text).data}',
          );
          await ok(tester);
        }
        expect(seen, [
          'Printing CPN [1/1]',
          'Printing original [1/2]',
          'Printing original [2/2]',
          'Printing copy [1/1]',
          'Printing confirm [1/1]',
          'Printing loyalty [1/1]',
          'Printing cashcard original [1/1]',
          'Printing cashcard copy [1/1]',
        ]);
        expect(printer.printed, [
          'image:cpn1',
          'image:o1',
          'image:o2',
          'image:c1',
          'image:f1',
          'text:LV slip',
          'text:CC o',
          'text:CC c',
        ]);
        expect(signedOut, 1);
      });

      testWidgets('nothing printed until OK', (tester) async {
        await pumpAndComplete(tester);
        expect(find.text('Printing original'), findsOneWidget);
        expect(find.text('[1/1]'), findsOneWidget);
        expect(printer.printed, isEmpty);
        await ok(tester);
        expect(printer.printed, ['image:https://slip/original.png']);
      });

      testWidgets('no original page: signs out straight away', (tester) async {
        repo.printAnswer = const PrintInvoiceAnswer(completed: true);
        await pumpAndComplete(tester);
        expect(byTestId(PaymentIds.printPage), findsNothing);
        expect(printer.printed, isEmpty);
        expect(signedOut, 1);
      });

      testWidgets('a failed print says so and carries on', (tester) async {
        await pumpAndComplete(tester);
        printer.error = const PrinterException('No paired printer found.');
        await ok(tester);
        expect(byTestId(PaymentIds.printFailed), findsOneWidget);
        expect(find.text('No paired printer found.'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(signedOut, 1);
      });

      testWidgets('SYNC_ERROR: RETRY asks again', (tester) async {
        repo.printAnswer = const PrintInvoiceAnswer(
          completed: false,
          messages: [
            SaleEngineMessage(
              type: 'Error',
              code: 'SYNC_ERROR',
              desc: 'Not synced yet.',
            ),
          ],
        );
        await pumpAndComplete(tester);
        expect(find.text('SYNC_ERROR'), findsOneWidget);
        expect(find.text('Not synced yet.'), findsOneWidget);

        repo.printAnswer = const PrintInvoiceAnswer(
          completed: true,
          documents: PrintDocuments(
            invoice: PrintDocumentSet(original: ['o1']),
          ),
        );
        await tester.tap(find.text('RETRY'));
        await tester.pumpAndSettle();
        expect(repo.invoicePrints, ['S-1', 'S-1']);
        expect(find.text('Printing original'), findsOneWidget);
      });

      testWidgets('TIMEOUT: OK signs out', (tester) async {
        repo.printAnswer = const PrintInvoiceAnswer(
          completed: false,
          messages: [
            SaleEngineMessage(type: 'Error', code: 'TIMEOUT', desc: 'Late.'),
          ],
        );
        await pumpAndComplete(tester);
        expect(find.text('TIMEOUT'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(signedOut, 1);
      });

      testWidgets('another error: "Error ! code", stays', (tester) async {
        repo.printAnswer = const PrintInvoiceAnswer(
          completed: false,
          messages: [
            SaleEngineMessage(type: 'Error', code: 'E42', desc: 'Broken.'),
          ],
        );
        await pumpAndComplete(tester);
        expect(find.text('Error ! E42'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(signedOut, 0);
      });

      testWidgets('no network: "Network not connection", then sign out', (
        tester,
      ) async {
        repo.printError = const ApiException(
          messageDesc: 'No network connection.',
        );
        await pumpAndComplete(tester);
        expect(find.text('Network not connection'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(signedOut, 1);
      });
    });
  }
}
