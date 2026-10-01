import '../entities/line_edit.dart';
import '../repositories/sale_repository.dart';

class EditCartItemUseCase {
  final SaleRepository _repository;

  const EditCartItemUseCase(this._repository);

  Future<LineEditResult> call({
    required String sessionKey,
    required String row,
    required LineEdit edit,
  }) => _repository.editCartItem(sessionKey: sessionKey, row: row, edit: edit);
}

class LookupSerialUseCase {
  final SaleRepository _repository;

  const LookupSerialUseCase(this._repository);

  Future<String> call({required String site, required String barcode}) =>
      _repository.lookupSerial(site: site, barcode: barcode);
}
