import 'dart:io';
import 'package:dio/dio.dart';
import 'package:research_helper/MODELS/message.dart';
import 'package:research_helper/SERVICES/dioClient.dart';
import 'package:research_helper/SERVICES/storage_services.dart';
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
        data: {"url": url, "userId": userId, "projectId": projectId},
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
        "userId": userId,
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
        data: {"projectId": projectId, "userId": userId},
      );
      return response.data["summary"];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Message?> query(String content, String projId) async {
    String userId = await getUserId();
    try {
      final res = await Dioclient.dio.post(
        '/query',
        data: {
          "query": content,
          "userId": userId,
          "projectId": projId,
          "k": 5,
          "history": StorageServices.getLastNMessagesJson(projId, 5),
        },
      );
        print("query response = ${res.data['answer']}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        Message aiMessage = Message(
          role: 'ai',
          content: res.data['answer'],
          timestamp: DateTime.now(),
        );
        
        await StorageServices.addMessage(projId, aiMessage);
        return aiMessage;
      } else {
        
        return null;
      }
    } catch (e) {
      print('got in catch while querying ${e}');
      return null;
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
