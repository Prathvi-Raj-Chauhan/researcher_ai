import 'package:hive_flutter/hive_flutter.dart';
import 'package:research_helper/MODELS/message.dart';

part 'project.g.dart';

@HiveType(typeId: 1)
class Project extends HiveObject {
  @HiveField(0)
  String id; // uuid or session id

  @HiveField(1)
  String name;

  @HiveField(2)
  List<String> sources; // all docs names and urls

  @HiveField(3)
  String summary;

  @HiveField(4)
  List<Message> messages;

  @HiveField(5)
  DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    this.sources = const [],
    this.summary = "",
    this.messages = const [],
    required this.createdAt,
  });
}
