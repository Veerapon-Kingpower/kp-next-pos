import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/sale/domain/entities/print_documents.dart';

void main() {
  test('no invoice original: nothing to print (legacy signs out)', () {
    expect(
      printJobsFor(
        const PrintDocuments(
          invoice: PrintDocumentSet(copy: ['c']),
          lv: PrintDocumentSet(copy: ['lv']),
        ),
      ),
      isEmpty,
    );
  });

  test('legacy order: CPN copy, original, copy, confirm, loyalty, cash '
      'card original and copy', () {
    final jobs = printJobsFor(
      const PrintDocuments(
        invoice: PrintDocumentSet(original: ['o1', 'o2'], confirm: ['f']),
        cpn: PrintDocumentSet(original: ['ignored'], copy: ['cpn']),
        lv: PrintDocumentSet(original: ['ignored'], copy: ['lv']),
        cashCard: PrintDocumentSet(original: ['cco'], copy: ['ccc']),
      ),
    );
    expect(
      [for (final j in jobs) '${j.title} ${j.index}/${j.count} ${j.value}'],
      [
        'Printing CPN 1/1 cpn',
        'Printing original 1/2 o1',
        'Printing original 2/2 o2',
        'Printing confirm 1/1 f',
        'Printing loyalty 1/1 lv',
        'Printing cashcard original 1/1 cco',
        'Printing cashcard copy 1/1 ccc',
      ],
    );
    expect(
      [for (final j in jobs) j.isImage],
      [
        true, true, true, true, false, false, false, //
      ],
    );
  });
}
