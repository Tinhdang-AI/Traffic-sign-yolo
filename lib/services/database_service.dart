import 'dart:math' show cos;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  static const String dbName = 'sentinel_local.db';
  static const String pendingReportsTable = 'pending_reports';
  static const int dbVersion = 1;

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
        isSynced INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Create index for faster queries
    await db.execute(
      'CREATE INDEX idx_synced ON $pendingReportsTable(isSynced)',
    );
    await db.execute(
      'CREATE INDEX idx_timestamp ON $pendingReportsTable(timestamp DESC)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
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

  /// ✅ Clear all local reports (use with caution)
  Future<void> clearAllLocalReports() async {
    final db = await database;
    await db.delete(pendingReportsTable);
    debugPrint('⚠️ All local reports cleared');
  }

  /// ✅ Close database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
