import '../entities/article.dart';
import '../repositories/sale_repository.dart';

class LookupArticleByBarcodeUseCase {
  final SaleRepository _repository;

  const LookupArticleByBarcodeUseCase(this._repository);

  Future<Article> call(String barcode) =>
      _repository.lookupArticleByBarcode(barcode);
}
