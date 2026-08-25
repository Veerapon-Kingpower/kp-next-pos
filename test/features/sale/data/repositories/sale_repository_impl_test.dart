import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/sale/data/datasources/sale_remote_data_source.dart';
import 'package:kp_pos/features/sale/data/repositories/sale_repository_impl.dart';
import 'package:kp_pos/features/sale/domain/entities/article.dart';

import '../../../../core/network/fake_api_client.dart';
import '../../../../core/storage/fakes.dart';
import '../../fake_article_local_data_source.dart';

void main() {
  const deviceSettings = DeviceSettings(
    subBranchCode: 'CPX-DT',
    saleEngineEndpoint: 'https://sale-engine',
    webServiceEndpoint: 'https://web-service',
    flightApi: 'https://flight',
  );

  const articleResponse = {
    'isCompleted': true,
    'Data': {
      'Article': {
        'ArticleCode': 'ART001',
        'ArticleName': 'Test Article',
        'EANCode': '8850012345678',
        'Brand': {'Code': 'B1', 'Name': 'Brand One'},
        'VatRate': 7,
        'Price': 100,
      },
    },
    'Message': [],
  };

  ({SaleRepositoryImpl repo, FakeArticleLocalDataSource local}) buildRepo(
    FakeApiClient apiClient,
    DeviceSettings settings,
  ) {
    final local = FakeArticleLocalDataSource();
    final repo = SaleRepositoryImpl(
      remote: SaleRemoteDataSource(apiClient: apiClient),
      deviceSettingsStorage: FakeDeviceSettingsStorage(settings),
      articleLocal: local,
    );
    return (repo: repo, local: local);
  }

  test(
    'lookupArticleByBarcode uses saleEngineEndpoint and subBranchCode as siteCode',
    () async {
      final apiClient = FakeApiClient(response: articleResponse);
      final built = buildRepo(apiClient, deviceSettings);

      final result = await built.repo.lookupArticleByBarcode(
        '8850012345678',
      );

      expect(
        apiClient.lastUrl,
        'https://sale-engine/SaleEngine/GetMasterByBarcodeDLL',
      );
      final sent = apiClient.lastData as Map<String, dynamic>;
      expect(sent['siteCode'], 'CPX-DT');
      expect(result.articleCode, 'ART001');
      expect(result.isFromCache, isFalse);
    },
  );

  test(
    'lookupArticleByBarcode caches a successful network result',
    () async {
      final apiClient = FakeApiClient(response: articleResponse);
      final built = buildRepo(apiClient, deviceSettings);

      await built.repo.lookupArticleByBarcode('8850012345678');

      final cached = built.local.getByBarcode('8850012345678');
      expect(cached, isNotNull);
      expect(cached!.articleCode, 'ART001');
    },
  );

  test(
    'lookupArticleByBarcode falls back to the cache when the network is unreachable',
    () async {
      final apiClient = FakeApiClient(
        errorToThrow: const ApiException(
          messageDesc: 'No network connection.',
        ),
      );
      final built = buildRepo(apiClient, deviceSettings);
      built.local.upsert(
        barcode: '8850012345678',
        article: const Article(
          articleCode: 'ART001',
          articleName: 'Test Article',
          eanCode: '8850012345678',
          brandCode: 'B1',
          brandName: 'Brand One',
          price: 100,
          vatRate: 7,
        ),
      );

      final result = await built.repo.lookupArticleByBarcode(
        '8850012345678',
      );

      expect(result.articleCode, 'ART001');
      expect(result.isFromCache, isTrue);
    },
  );

  test(
    'lookupArticleByBarcode still fails when the network is unreachable and nothing is cached',
    () async {
      final apiClient = FakeApiClient(
        errorToThrow: const ApiException(
          messageDesc: 'No network connection.',
        ),
      );
      final built = buildRepo(apiClient, deviceSettings);

      expect(
        () => built.repo.lookupArticleByBarcode('8850012345678'),
        throwsA(isA<ApiException>()),
      );
    },
  );

  test(
    'lookupArticleByBarcode does not fall back to the cache for a legitimate "not found" response',
    () async {
      final apiClient = FakeApiClient(
        response: {
          'isCompleted': false,
          'Data': null,
          'Message': [
            {
              'MessageType': 'error',
              'MessageCode': 'E01',
              'MessageDesc': 'Article not found',
            },
          ],
        },
      );
      final built = buildRepo(apiClient, deviceSettings);
      built.local.upsert(
        barcode: '8850012345678',
        article: const Article(
          articleCode: 'ART001',
          articleName: 'Test Article',
          eanCode: '8850012345678',
          brandCode: 'B1',
          brandName: 'Brand One',
          price: 100,
          vatRate: 7,
        ),
      );

      expect(
        () => built.repo.lookupArticleByBarcode('8850012345678'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.messageDesc,
            'messageDesc',
            'Article not found',
          ),
        ),
      );
    },
  );

  test(
    'lookupArticleByBarcode skips the network entirely when forceOfflineMode is on and the article is cached',
    () async {
      final apiClient = FakeApiClient(response: articleResponse);
      final built = buildRepo(
        apiClient,
        deviceSettings.copyWith(forceOfflineMode: true),
      );
      built.local.upsert(
        barcode: '8850012345678',
        article: const Article(
          articleCode: 'ART001',
          articleName: 'Test Article',
          eanCode: '8850012345678',
          brandCode: 'B1',
          brandName: 'Brand One',
          price: 100,
          vatRate: 7,
        ),
      );

      final result = await built.repo.lookupArticleByBarcode(
        '8850012345678',
      );

      expect(apiClient.lastUrl, isNull);
      expect(result.articleCode, 'ART001');
      expect(result.isFromCache, isTrue);
    },
  );

  test(
    'lookupArticleByBarcode fails without calling the network when forceOfflineMode is on and nothing is cached',
    () async {
      final apiClient = FakeApiClient(response: articleResponse);
      final built = buildRepo(
        apiClient,
        deviceSettings.copyWith(forceOfflineMode: true),
      );

      expect(
        () => built.repo.lookupArticleByBarcode('8850012345678'),
        throwsA(isA<ApiException>()),
      );
      expect(apiClient.lastUrl, isNull);
    },
  );

  test(
    'addItemToCart uses saleEngineEndpoint and the given session key',
    () async {
      final apiClient = FakeApiClient(
        response: {
          'isCompleted': true,
          'Data': [
            {'Guid': 'order-1', 'isCheckOut': false, 'OrderDetails': []},
          ],
          'Message': [],
        },
      );
      final built = buildRepo(apiClient, deviceSettings);

      await built.repo.addItemToCart(
        sessionKey: 'abc123',
        articleCode: 'ART001',
        quantity: 3,
      );

      expect(
        apiClient.lastUrl,
        'https://sale-engine/SaleEngine/AddItemToOrder',
      );
      expect(apiClient.lastData, {
        'ItemCode': 'ART001',
        'ItemGWP': '',
        'SessionKey': 'abc123',
        'Rows': ['3'],
      });
    },
  );

  test(
    'getCart resolves the shoppingCard-scoped order from GetOrder',
    () async {
      final apiClient = FakeApiClient(
        response: {
          'isCompleted': true,
          'Data': [
            {'Guid': 'order-1', 'isCheckOut': false, 'OrderDetails': []},
          ],
          'Message': [],
        },
      );
      final built = buildRepo(apiClient, deviceSettings);

      final result = await built.repo.getCart(
        sessionKey: 'abc123',
        shoppingCard: 'CPX0001',
      );

      expect(apiClient.lastUrl, 'https://sale-engine/SaleEngine/GetOrder');
      expect(result.guid, 'order-1');
    },
  );
}
