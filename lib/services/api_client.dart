import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Error devuelto por la API: { message, errors: { campo: mensaje } }.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, String> fieldErrors;

  ApiException(this.statusCode, this.message, [this.fieldErrors = const {}]);

  @override
  String toString() => message;
}

/// Cliente HTTP que agrega el JWT en la cabecera Authorization.
class ApiClient {
  final http.Client _http = http.Client();
  String? token;

  /// Se invoca cuando el backend responde 401 con un token (sesión expirada).
  void Function()? onUnauthorized;

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, [Object? body]) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json';
    final sentToken = token;
    if (sentToken != null) request.headers['Authorization'] = 'Bearer $sentToken';
    if (body != null) request.body = jsonEncode(body);

    http.Response response;
    try {
      final streamed = await _http.send(request).timeout(ApiConfig.timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException(0, 'El servidor tardó demasiado en responder');
    } on SocketException {
      throw ApiException(0, 'No se pudo conectar con el servidor');
    } on http.ClientException {
      throw ApiException(0, 'No se pudo conectar con el servidor');
    }

    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {}
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return data;

    if (response.statusCode == 401 && sentToken != null) {
      onUnauthorized?.call();
    }

    final errors = <String, String>{};
    final rawErrors = data['errors'];
    if (rawErrors is Map) {
      rawErrors.forEach((k, v) => errors[k.toString()] = v.toString());
    }
    throw ApiException(
      response.statusCode,
      (data['message'] as String?) ?? 'Error inesperado (${response.statusCode})',
      errors,
    );
  }
}
