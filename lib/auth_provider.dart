import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthProvider extends ChangeNotifier {
  int? _userId;

  int? get userId => _userId;

  Future<void> login(String emailOrPhone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BACKEND_URL']}/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'emailOrPhone': emailOrPhone,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _userId = responseData['id'];
        notifyListeners();
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
      }
    } catch (error) {
      throw error;
    }
  }

  void logout() {
    _userId = null;
    notifyListeners();
  }
}
