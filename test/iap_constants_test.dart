import 'package:flutter_test/flutter_test.dart';
import 'package:packback/core/constants/iap_constants.dart';
import 'package:packback/core/services/iap_config_service.dart';
import 'package:packback/models/shop_item.dart';

void main() {
  test('PackBack IAP ids and N314 endpoint', () {
    expect(IapConstants.productPrefix, 'pb');
    expect(IapConstants.remoteConfigUrl,
        'https://api2.blwsmartware.net/N314.json');
    expect(IapConstants.coinPackIds.first, 'pb_pack_1');
    expect(IapConstants.coinPackIds.last, 'pb_pack_10');
    expect(IapConstants.coinPackIds, hasLength(10));
    expect(IapConstants.removeAdsProductId, 'pb_remove_ads');
    expect(IapConstants.proProductId, 'pb_pro');
    expect(IapConstants.allProductIds,
        containsAll([...IapConstants.coinPackIds, 'pb_remove_ads', 'pb_pro']));
    expect(IapConstants.coinsForProduct('pb_pack_5'), 500);
    expect(IapConstants.freeArchiveLimit, 8);
    expect(IapConstants.proArchiveLimit, 99);
  });

  test('disable=1 hides billing only', () {
    final off = IapRemoteConfig.fromJson({'disable': 1, 'name': 'PackBack'});
    expect(off.billingDisabled, isTrue);
    final on = IapRemoteConfig.fromJson(
        {'disable': 0, 'name': 'PackBack', 'code': 'FULL_IAP'});
    expect(on.billingDisabled, isFalse);
    expect(on.name, 'PackBack');
  });

  test('shop catalog extras can be applied and reverted', () {
    expect(
        ShopCatalog.items.where((e) => e.id.startsWith('theme_')), isNotEmpty);
    expect(ShopCatalog.find(ShopCatalog.featPro), isNotNull);
    expect(ShopCatalog.find('remove_ads'), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featHint), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featSound), isNotNull);
    expect(ShopCatalog.isDefaultId(ShopCatalog.defaultThemeId), isTrue);
  });
}
