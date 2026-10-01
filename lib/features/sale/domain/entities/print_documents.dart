import 'finish_payment.dart';

/// One document group of legacy `PrintInvoiceResponse.Data`: the
/// `Original`, `Copy` and `Confirm` pages, each a `value` — an image URL
/// for the invoice / CPN, slip text for LV / CashCard.
class PrintDocumentSet {
  final List<String> original;
  final List<String> copy;
  final List<String> confirm;

  const PrintDocumentSet({
    this.original = const [],
    this.copy = const [],
    this.confirm = const [],
  });
}

/// Legacy `getInvoice()`'s split of `PrintTaxInvoice` by `Type`.
class PrintDocuments {
  /// `Invoice` — the tax invoice pages (image URLs).
  final PrintDocumentSet invoice;

  /// `CPN` — coupon pages (image URLs); null when the bill has none.
  final PrintDocumentSet? cpn;

  /// `LV` — the loyalty slip (text).
  final PrintDocumentSet? lv;

  /// `CashCard` — cash card slips (text).
  final PrintDocumentSet? cashCard;

  const PrintDocuments({
    required this.invoice,
    this.cpn,
    this.lv,
    this.cashCard,
  });
}

/// One page to print, in legacy's order and with its dialog title.
class PrintJob {
  final String title;

  /// The page within its group, 1-based, and the group's size — legacy's
  /// "[1/2]".
  final int index;
  final int count;

  /// An image URL ([isImage]) or slip text.
  final String value;
  final bool isImage;

  const PrintJob({
    required this.title,
    required this.index,
    required this.count,
    required this.value,
    required this.isImage,
  });
}

/// Legacy `onPrintInvice()` and its `showAlert…Print` chain: CPN copies,
/// then the invoice original, copy and confirm pages, then the loyalty
/// slip and the cash card original / copy slips. Nothing at all when the
/// invoice has no original page — legacy signs out straight away then.
List<PrintJob> printJobsFor(PrintDocuments docs) {
  if (docs.invoice.original.isEmpty) return const [];
  final jobs = <PrintJob>[];
  void add(String title, List<String> pages, {required bool image}) {
    for (var i = 0; i < pages.length; i++) {
      jobs.add(
        PrintJob(
          title: title,
          index: i + 1,
          count: pages.length,
          value: pages[i],
          isImage: image,
        ),
      );
    }
  }

  add('Printing CPN', docs.cpn?.copy ?? const [], image: true);
  add('Printing original', docs.invoice.original, image: true);
  add('Printing copy', docs.invoice.copy, image: true);
  add('Printing confirm', docs.invoice.confirm, image: true);
  add('Printing loyalty', docs.lv?.copy ?? const [], image: false);
  add(
    'Printing cashcard original',
    docs.cashCard?.original ?? const [],
    image: false,
  );
  add('Printing cashcard copy', docs.cashCard?.copy ?? const [], image: false);
  return jobs;
}

/// Legacy `getInvoice()`'s answer: [completed] / [messages] as any
/// sale-engine call, and the documents split by `Type` when completed.
class PrintInvoiceAnswer {
  final bool completed;
  final List<SaleEngineMessage> messages;
  final PrintDocuments documents;

  const PrintInvoiceAnswer({
    required this.completed,
    this.messages = const [],
    this.documents = const PrintDocuments(invoice: PrintDocumentSet()),
  });

  SaleEngineMessage? get firstMessage =>
      messages.isEmpty ? null : messages.first;
}
