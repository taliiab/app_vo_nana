import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: kIsWeb ? 'http://200.18.74.27:8082' : 'http://200.18.74.27:8082',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Dio get dio => _dio;

  Future<Map<String, dynamic>?> fazerLogin(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'senha': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Login bem-sucedido no backend!');
        return response.data;
      }

      return null;
    } on DioException catch (e) {
      print('Erro de requisição: ${e.message}');
      if (e.response != null) {
        print('Dados do erro do Back: ${e.response?.data}');
        print('Status Code do Back: ${e.response?.statusCode}');
      }
      return null;
    } catch (e) {
      print('Erro inesperado: $e');
      return null;
    }
  }
}