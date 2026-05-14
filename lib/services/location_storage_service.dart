import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SavedLocation {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final bool isFavorite;
  final DateTime createdAt;

  SavedLocation({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isFavorite = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedLocation.fromMap(Map<String, dynamic> map) {
    return SavedLocation(
      id: map['id'] as int?,
      name: map['name'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      isFavorite: (map['isFavorite'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

class LocationStorageService {
  static final LocationStorageService _instance =
      LocationStorageService._internal();

  factory LocationStorageService() {
    return _instance;
  }

  LocationStorageService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'traffic_detect_locations.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE saved_locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            isFavorite INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
          ''');
      },
    );
  }

  /// Save a new location or update existing
  Future<int> saveLocation(SavedLocation location) async {
    final db = await database;

    if (location.id != null) {
      // Update existing
      await db.update(
        'saved_locations',
        location.toMap(),
        where: 'id = ?',
        whereArgs: [location.id],
      );
      return location.id!;
    } else {
      // Insert new
      return await db.insert('saved_locations', location.toMap());
    }
  }

  /// Get all favorite locations
  Future<List<SavedLocation>> getFavorites() async {
    final db = await database;
    final maps = await db.query(
      'saved_locations',
      where: 'isFavorite = 1',
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => SavedLocation.fromMap(map)).toList();
  }

  /// Get recently visited locations (last 10)
  Future<List<SavedLocation>> getRecent({int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      'saved_locations',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return maps.map((map) => SavedLocation.fromMap(map)).toList();
  }

  /// Mark location as favorite
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'saved_locations',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a saved location
  Future<void> deleteLocation(int id) async {
    final db = await database;
    await db.delete('saved_locations', where: 'id = ?', whereArgs: [id]);
  }

  /// Search saved locations by name
  Future<List<SavedLocation>> searchLocations(String query) async {
    final db = await database;
    final maps = await db.query(
      'saved_locations',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => SavedLocation.fromMap(map)).toList();
  }

  /// Clear all saved locations
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('saved_locations');
  }
}
