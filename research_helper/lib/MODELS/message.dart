import 'package:hive/hive.dart';

part 'message.g.dart';

@HiveType(typeId: 0)
class Message extends HiveObject {
  @HiveField(0)
  String role;

  @HiveField(1)
  String content;

  @HiveField(2)
  List<String> sources;

  @HiveField(3)
  DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    this.sources = const [],
    required this.timestamp,
  });
}
