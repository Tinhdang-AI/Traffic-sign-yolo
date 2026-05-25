import 'dart:math' show cos;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, ValueNotifier;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'location_service.dart';

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
  static const String pendingReportsTable = 'pending_reports';
  static const String detectionHistoryTable = 'detection_history';
  static const int dbVersion = 3;

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
      CREATE TABLE $pendingReportsTable (
        id TEXT PRIMARY KEY,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        violationType TEXT NOT NULL,
        description TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        reportedBy TEXT NOT NULL,
        imageUrl TEXT,
        isVerified INTEGER DEFAULT 0,
        isSynced INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_synced ON $pendingReportsTable(isSynced)',
    );
    await db.execute(
      'CREATE INDEX idx_timestamp ON $pendingReportsTable(timestamp DESC)',
    );

    await db.execute('''
      CREATE TABLE $detectionHistoryTable (
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
      'CREATE INDEX idx_history_timestamp ON $detectionHistoryTable(timestamp DESC)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS $pendingReportsTable');
      await _onCreate(db, newVersion);
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
          imageBytes BLOB
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_history_timestamp ON $detectionHistoryTable(timestamp DESC)',
      );
    }
  }

  /// ✅ Insert a pending report into local database
  Future<void> insertPendingReport({
    required String id,
    required double latitude,
    required double longitude,
    required String violationType,
    required String description,
    required DateTime timestamp,
    required String reportedBy,
    required String? imageUrl,
    required bool isVerified,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(pendingReportsTable, {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'violationType': violationType,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'reportedBy': reportedBy,
      'imageUrl': imageUrl,
      'isVerified': isVerified ? 1 : 0,
      'isSynced': 0,
      'createdAt': now,
      'updatedAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    debugPrint('✅ Pending report inserted locally: $id');
  }

  /// ✅ Get all pending (unsynced) reports
  Future<List<Map<String, dynamic>>> getPendingReports() async {
    final db = await database;
    return await db.query(
      pendingReportsTable,
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );
  }

  /// ✅ Mark reports as synced
  Future<void> markReportAsSynced(String reportId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      pendingReportsTable,
      {'isSynced': 1, 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [reportId],
    );
    debugPrint('✅ Report marked as synced: $reportId');
  }

  /// ✅ Mark multiple reports as synced
  Future<void> markReportsAsSynced(List<String> reportIds) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final id in reportIds) {
      await db.update(
        pendingReportsTable,
        {'isSynced': 1, 'updatedAt': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    debugPrint('✅ ${reportIds.length} reports marked as synced');
  }

  /// ✅ Increment upvotes for a local report
  Future<void> incrementReportUpvotes(String reportId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.rawUpdate(
      '''
      UPDATE $pendingReportsTable
      SET upvotes = COALESCE(upvotes, 0) + 1,
          updatedAt = ?
      WHERE id = ?
      ''',
      [now, reportId],
    );
    debugPrint('✅ Report upvotes incremented: $reportId');
  }

  /// ✅ Get all reports (synced and unsynced) near location
  Future<List<Map<String, dynamic>>> getLocalReportsNearby(
    double latitude,
    double longitude, {
    double radiusKm = 5.0,
  }) async {
    final db = await database;
    final latDelta = radiusKm / 111.0;
    final lonDelta =
        radiusKm / (111.0 * (cos(latitude * 3.14159 / 180)).toDouble());

    return await db.query(
      pendingReportsTable,
      where:
          'latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ? AND isSynced = 1',
      whereArgs: [
        latitude - latDelta,
        latitude + latDelta,
        longitude - lonDelta,
        longitude + lonDelta,
      ],
      orderBy: 'timestamp DESC',
    );
  }

  /// ✅ Get all local reports (cached)
  Future<List<Map<String, dynamic>>> getAllLocalReports() async {
    final db = await database;
    return await db.query(
      pendingReportsTable,
      where: 'isSynced = 1',
      orderBy: 'timestamp DESC',
    );
  }

  /// ✅ Delete a report from local cache
  Future<void> deleteLocalReport(String reportId) async {
    final db = await database;
    await db.delete(
      pendingReportsTable,
      where: 'id = ?',
      whereArgs: [reportId],
    );
    debugPrint('✅ Local report deleted: $reportId');
  }

  /// ✅ Update a report's violationType, description, and optionally imageUrl / isVerified in local database
  Future<void> updateReport({
    required String id,
    required String violationType,
    required String description,
    required String? imageUrl,
    bool? isVerified,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final updateData = <String, dynamic>{
      'violationType': violationType,
      'description': description,
      'imageUrl': imageUrl,
      'updatedAt': now,
    };

    if (isVerified != null) {
      updateData['isVerified'] = isVerified ? 1 : 0;
    }

    await db.update(
      pendingReportsTable,
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('✅ Report updated in DB: $id');
  }

  /// ✅ Get count of pending reports
  Future<int> getPendingReportCount() async {
    final db = await database;
    final result = await db.query(
      pendingReportsTable,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return result.length;
  }

  /// Clear all local reports (use with caution)
  Future<void> clearAllLocalReports() async {
    final db = await database;
    await db.delete(pendingReportsTable);
    debugPrint('⚠️ All local reports cleared');
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
      detectionHistoryTable,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('Saved detection to history: $label');
    historyChangeNotifier.value++;
  }

  /// Get all detection history
  Future<List<HistoryItem>> getDetectionHistory() async {
    final db = await database;
    final maps = await db.query(
      detectionHistoryTable,
      orderBy: 'timestamp DESC',
    );
    return maps.map((e) => HistoryItem.fromMap(e)).toList();
  }

  /// Clear all detection history
  Future<void> clearDetectionHistory() async {
    final db = await database;
    await db.delete(detectionHistoryTable);
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
