import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1526739547870247/7495194366';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1526739547870247/7357090852';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
