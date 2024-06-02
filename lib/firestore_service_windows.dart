import 'package:flutter/services.dart';

class FirestoreService {
  static const MethodChannel _channel = MethodChannel('firestore_channel');

  static Future<List<dynamic>> getDocuments(String collectionPath) async {
    try {
      return await _channel
          .invokeMethod('getDocuments', {'collectionPath': collectionPath});
    } on PlatformException catch (e) {
      return [];
    }
  }
}
