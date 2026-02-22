import 'dart:io';
import 'package:dio/dio.dart';
import 'package:research_helper/SERVICES/dioClient.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Apiservices {
  static Future<String> getUserId() async {
    final pref = await SharedPreferences.getInstance();
    String userId = pref.getString('userId')!;
    return userId;
  }

  static Future<Map<String, dynamic>> ingestUrl(
    String url,
    String projectId,
  ) async {
    String userId = await getUserId();
    try {
      final response = await Dioclient.dio.post(
        "/ingest/url",
        data: {"url": url, "userId": userId, "projectId" : projectId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> ingestFile(
    File file,
    String projectId,
  ) async {
    String userId = await getUserId();
    try {
      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        "userId" : userId,
        "projectId": projectId,
      });

      final response = await Dioclient.dio.post("/ingest/file", data: formData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<String> summarize(String projectId) async {
    String userId = await getUserId();
    try {

      final response = await Dioclient.dio.post(
        "/summarize",
        data: {"projectId": projectId, "userId" : userId},
      );
      return response.data["summary"];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return "Cannot connect to server. Check your connection.";
    }
    if (e.response != null) {
      final detail = e.response?.data["detail"];
      return detail ?? "Server error: ${e.response?.statusCode}";
    }
    return "Something went wrong. Please try again.";
  }
}
