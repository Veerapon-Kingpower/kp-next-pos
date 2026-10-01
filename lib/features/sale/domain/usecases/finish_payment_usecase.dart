import '../entities/finish_payment.dart';
import '../entities/print_documents.dart';
import '../repositories/sale_repository.dart';

/// Legacy Checkout's Finish: `ValidateGWP`, then `FinishPaymentOrder`, then
/// `PrintTaxInvoice`.
class FinishPaymentUseCase {
  final SaleRepository _repository;

  const FinishPaymentUseCase(this._repository);

  Future<SaleEngineAnswer> validateGwp({
    required String sessionKey,
    required String orderGuid,
  }) => _repository.validateGwp(sessionKey: sessionKey, orderGuid: orderGuid);

  Future<SaleEngineAnswer> finish({
    required String sessionKey,
    required String orderGuid,
    List<OrderSignatureEntry>? signatures,
  }) => _repository.finishPaymentOrder(
    sessionKey: sessionKey,
    orderGuid: orderGuid,
    signatures: signatures,
  );

  Future<PrintInvoiceAnswer> printInvoice({
    required String sessionKey,
    required String orderNo,
  }) => _repository.printTaxInvoice(sessionKey: sessionKey, orderNo: orderNo);
}
