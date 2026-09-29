import '../../core/di/service_locator.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/device_settings_storage.dart';
import '../auth/domain/usecases/restore_session_usecase.dart';
import 'data/datasources/sale_remote_data_source.dart';
import 'data/local/article_local_data_source.dart';
import 'data/repositories/sale_repository_impl.dart';
import 'domain/repositories/sale_repository.dart';
import 'domain/usecases/add_item_to_cart_usecase.dart';
import 'domain/usecases/get_cart_usecase.dart';
import 'domain/usecases/change_order_currency_usecase.dart';
import 'domain/usecases/list_currencies_usecase.dart';
import 'domain/usecases/lookup_article_by_barcode_usecase.dart';
import 'domain/usecases/remove_cart_item_usecase.dart';
import 'domain/usecases/update_cart_item_quantity_usecase.dart';
import 'presentation/sale_cart_view_model.dart';

void setupSaleServiceLocator() {
  sl.registerLazySingleton<SaleRemoteDataSource>(
    () => SaleRemoteDataSource(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<ArticleLocalDataSource>(
    () => RealmArticleLocalDataSource(),
  );
  sl.registerLazySingleton<SaleRepository>(
    () => SaleRepositoryImpl(
      remote: sl<SaleRemoteDataSource>(),
      deviceSettingsStorage: sl<DeviceSettingsStorage>(),
      articleLocal: sl<ArticleLocalDataSource>(),
    ),
  );
  sl.registerFactory<LookupArticleByBarcodeUseCase>(
    () => LookupArticleByBarcodeUseCase(sl<SaleRepository>()),
  );
  sl.registerFactory<AddItemToCartUseCase>(
    () => AddItemToCartUseCase(sl<SaleRepository>()),
  );
  sl.registerFactory<UpdateCartItemQuantityUseCase>(
    () => UpdateCartItemQuantityUseCase(sl<SaleRepository>()),
  );
  sl.registerFactory<RemoveCartItemUseCase>(
    () => RemoveCartItemUseCase(sl<SaleRepository>()),
  );
  sl.registerFactory<GetCartUseCase>(
    () => GetCartUseCase(sl<SaleRepository>()),
  );
  sl.registerFactory<ListCurrenciesUseCase>(
    () => ListCurrenciesUseCase(sl<SaleRepository>()),
  );
  sl.registerFactory<ChangeOrderCurrencyUseCase>(
    () => ChangeOrderCurrencyUseCase(sl<SaleRepository>()),
  );
  sl.registerFactory<SaleCartViewModel>(
    () => SaleCartViewModel(
      restoreSession: sl<RestoreSessionUseCase>(),
      lookupArticle: sl<LookupArticleByBarcodeUseCase>(),
      addItemToCart: sl<AddItemToCartUseCase>(),
      updateCartItemQuantity: sl<UpdateCartItemQuantityUseCase>(),
      removeCartItem: sl<RemoveCartItemUseCase>(),
      listCurrencies: sl<ListCurrenciesUseCase>(),
      changeOrderCurrency: sl<ChangeOrderCurrencyUseCase>(),
    ),
  );
}
