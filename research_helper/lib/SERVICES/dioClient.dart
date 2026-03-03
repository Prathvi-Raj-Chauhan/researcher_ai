import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';

class Dioclient {
  
  static String url = "http://10.0.2.2:8000";
  // static String url = "https://researcher-ai-rag.onrender.com";

  static late final Dio dio;
  static void init() {
    BaseOptions bops = BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60), // longer for ingestion
      headers: {"Content-Type": "application/json"},
    );

    dio = Dio(bops);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 🔥 All requests go through here
          debugPrint('➡️ ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ ${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint('❌ ${e.response?.statusCode} ${e.requestOptions.uri}');

          // 🔐 Auto redirect on auth failure
          if (e.response?.statusCode == 401) {
            debugPrint('❌401 un Authorised');
          }

          handler.next(e);
        },
      ),
    );
  }
}
