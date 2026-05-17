import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class HistoryItem {
  final String id;
  final String label;
  final double confidence;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String locationName;
  final Uint8List? imageBytes;

  HistoryItem({
    required this.id,
    required this.label,
    required this.confidence,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.locationName,
    this.imageBytes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'confidence': confidence,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'locationName': locationName,
      'imageBytes': imageBytes,
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'],
      label: map['label'],
      confidence: map['confidence'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      locationName: map['locationName'] ?? '',
      imageBytes: map['imageBytes'],
    );
  }
}

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  static Database? _database;

  factory HistoryService() {
    return _instance;
  }

  HistoryService._internal();

  static const String dbName = 'sentinel_history.db';
  static const String historyTable = 'detection_history';
  static const int dbVersion = 2;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, dbName);
    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $historyTable (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        confidence REAL NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        locationName TEXT NOT NULL,
        imageBytes BLOB
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_history_timestamp ON $historyTable(timestamp DESC)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $historyTable ADD COLUMN imageBytes BLOB');
    }
  }

  Future<void> addDetection({
    required String label,
    required double confidence,
    required double latitude,
    required double longitude,
    required String locationName,
    Uint8List? imageBytes,
  }) async {
    final db = await database;
    final id = const Uuid().v4();
    final item = HistoryItem(
      id: id,
      label: label,
      confidence: confidence,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      locationName: locationName,
      imageBytes: imageBytes,
    );
    await db.insert(
      historyTable,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('Saved detection to history: $label');
  }

  Future<List<HistoryItem>> getHistory() async {
    final db = await database;
    final maps = await db.query(
      historyTable,
      orderBy: 'timestamp DESC',
    );
    return maps.map((e) => HistoryItem.fromMap(e)).toList();
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete(historyTable);
  }
}
