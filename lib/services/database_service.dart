import 'dart:math' show cos;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, ValueNotifier;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'location_service.dart';
import 'nextjs_api_service.dart';
import 'auth_service.dart';

class HistoryItem {
  final String id;
  final String label;
  final double confidence;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String locationName;
  final Uint8List? imageBytes;
  final String userId;

  HistoryItem({
    required this.id,
    required this.label,
    required this.confidence,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.locationName,
    this.imageBytes,
    required this.userId,
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
      'userId': userId,
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
      userId: map['userId'] ?? 'guest',
    );
  }

  String get displayLocationName {
    final trimmed = locationName.trim();
    if (trimmed.isEmpty || 
        trimmed.startsWith('Tọa độ') || 
        trimmed.contains('GPS') ||
        RegExp(r'^-?\d+\.\d+$').hasMatch(trimmed) ||
        RegExp(r'^-?\d+\.\d+,\s*-?\d+\.\d+$').hasMatch(trimmed)) {
      return LocationService.getMockLocationNameStatic(latitude, longitude);
    }
    return locationName;
  }
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  static final ValueNotifier<int> historyChangeNotifier = ValueNotifier<int>(0);

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  static const String dbName = 'sentinel_local.db';
  static const String detectionHistoryTable = 'detection_history';
  static const int dbVersion = 4;

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
      CREATE TABLE $detectionHistoryTable (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        confidence REAL NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        locationName TEXT NOT NULL,
        imageBytes BLOB,
        userId TEXT NOT NULL DEFAULT 'guest'
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_history_timestamp ON $detectionHistoryTable(timestamp DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_history_user ON $detectionHistoryTable(userId)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS pending_reports');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $detectionHistoryTable (
          id TEXT PRIMARY KEY,
          label TEXT NOT NULL,
          confidence REAL NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          timestamp INTEGER NOT NULL,
          locationName TEXT NOT NULL,
          imageBytes BLOB,
          userId TEXT NOT NULL DEFAULT 'guest'
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_history_timestamp ON $detectionHistoryTable(timestamp DESC)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_history_user ON $detectionHistoryTable(userId)',
      );
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE $detectionHistoryTable ADD COLUMN userId TEXT DEFAULT "guest"');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_history_user ON $detectionHistoryTable(userId)');
    }
  }

  // ─────────────────────────────────────────────
  // DETECTION HISTORY METHODS (merged from HistoryService)
  // ─────────────────────────────────────────────

  /// Add a detection to history
  Future<void> addDetectionHistory({
    required String label,
    required double confidence,
    required double latitude,
    required double longitude,
    required String locationName,
    Uint8List? imageBytes,
  }) async {
    final db = await database;
    final id = const Uuid().v4();
    final userId = AuthService().currentUser?.id ?? 'guest';
    
    final item = HistoryItem(
      id: id,
      label: label,
      confidence: confidence,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      locationName: locationName,
      imageBytes: imageBytes,
      userId: userId,
    );
    await db.insert(
      detectionHistoryTable,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('Saved detection to history: $label');
    
    // Upload to backend
    try {
      String? imageUrl;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        try {
          imageUrl = await NestJsApiService().uploadImage(imageBytes, '${id}.jpg');
        } catch (e) {
          debugPrint('Failed to upload image, continuing without it: $e');
        }
      }
      
      await NestJsApiService().recordDetection(
        latitude: latitude,
        longitude: longitude,
        confidence: confidence,
        detectionType: label,
        description: locationName,
        imageUrl: imageUrl,
      );
      debugPrint('Synced detection to backend: $label');
    } catch (e) {
      debugPrint('Failed to sync detection to backend: $e');
    }
    
    historyChangeNotifier.value++;
  }

  /// Get all detection history for current user
  Future<List<HistoryItem>> getDetectionHistory() async {
    final db = await database;
    final userId = AuthService().currentUser?.id ?? 'guest';
    final maps = await db.query(
      detectionHistoryTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((e) => HistoryItem.fromMap(e)).toList();
  }

  /// Clear all detection history for current user
  Future<void> clearDetectionHistory() async {
    final db = await database;
    final userId = AuthService().currentUser?.id ?? 'guest';
    await db.delete(
      detectionHistoryTable,
      where: 'userId = ?',
      whereArgs: [userId],
    );
    historyChangeNotifier.value++;
  }

  /// Delete a detection history item
  Future<void> deleteDetectionHistoryItem(String id) async {
    final db = await database;
    await db.delete(
      detectionHistoryTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    historyChangeNotifier.value++;
  }

  /// ✅ Close database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
