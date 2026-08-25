import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class SearchCustomerUseCase {
  final CustomerRepository _repository;

  const SearchCustomerUseCase(this._repository);

  Future<List<Customer>> call({
    required String shoppingCard,
    required bool isTour,
  }) {
    return _repository.search(shoppingCard: shoppingCard, isTour: isTour);
  }
}
