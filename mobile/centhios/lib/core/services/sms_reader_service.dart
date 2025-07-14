import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsReaderService {
  final SmsQuery _smsQuery = SmsQuery();

  Future<bool> _requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<List<SmsMessage>> getAllSms() async {
    final hasPermission = await _requestSmsPermission();
    if (!hasPermission) {
      // Handle the case where permission is denied.
      // You might want to throw an exception or return an empty list.
      throw Exception('SMS permission denied.');
    }

    try {
      final messages = await _smsQuery.getAllSms;
      return messages;
    } catch (e) {
      // Handle any errors that occur during message retrieval.
      print('Error reading SMS messages: $e');
      rethrow;
    }
  }
}
