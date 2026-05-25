import 'package:flutter_test/flutter_test.dart';
import 'package:traffic_detect/services/location_service.dart';

void main() {
  test('Test advanced mock location name resolution', () {
    // 1. Exact coordinate for Ninh Thuận Lương Sơn
    final address1 = LocationService.getMockLocationNameStatic(11.7973, 108.7536);
    expect(address1, equals('Quốc lộ 27, Lương Sơn, Xã Lâm Sơn, Ninh Thuận'));

    // 2. Slightly offset coordinate (close distance < 500m)
    final address2 = LocationService.getMockLocationNameStatic(11.7975, 108.7540);
    expect(address2, equals('Quốc lộ 27, Lương Sơn, Xã Lâm Sơn, Ninh Thuận'));

    // 3. Medium distance coordinate (1km - 25km along Route 27)
    final address3 = LocationService.getMockLocationNameStatic(11.8200, 108.7700);
    expect(address3, contains('Quốc lộ 27'));
    expect(address3, contains('Xã Lâm Sơn'));
    expect(address3, contains('Ninh Thuận'));
    print('Address 3: $address3');

    // 4. Large distance coordinate (out of local region but within province/city bounds)
    final address4 = LocationService.getMockLocationNameStatic(11.0000, 108.0000);
    expect(address4, contains('từ'));
    print('Address 4: $address4');
  });
}
