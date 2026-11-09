import 'dart:io';

const String offlineMessage = 'No internet connection. Please check your network.';

Future<bool> hasInternet() async {
  try {
    final result = await InternetAddress.lookup('firestore.googleapis.com')
        .timeout(const Duration(seconds: 5));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
