import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/location_record.dart';
import '../models/geofence.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'location_tracking.db');
    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(Database db, int version) async {
    // Create locations table
    await db.execute('''
      CREATE TABLE location_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL,
        longitude REAL,
        timestamp TEXT,
        locationName TEXT,
        isClockIn INTEGER
      )
    ''');

    // Create geofences table
    await db.execute('''
      CREATE TABLE geofences(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        latitude REAL,
        longitude REAL,
        radius REAL,
        description TEXT
      )
    ''');
  }

  // Location Records CRUD operations
  Future<int> insertLocationRecord(LocationRecord record) async {
    Database db = await database;
    int id = await db.insert('location_records', record.toMap());
    print(
      'DATABASE: Inserted location record with ID $id: ${record.location.latitude}, ${record.location.longitude}, ${record.timestamp}, ${record.locationName ?? "No location name"}',
    );
    return id;
  }

  Future<List<LocationRecord>> getLocationRecords() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('location_records');
    return List.generate(maps.length, (i) => LocationRecord.fromMap(maps[i]));
  }

  Future<List<LocationRecord>> getLocationRecordsForDay(DateTime date) async {
    Database db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'location_records',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return List.generate(maps.length, (i) => LocationRecord.fromMap(maps[i]));
  }

  // Geofences CRUD operations
  Future<int> insertGeofence(Geofence geofence) async {
    Database db = await database;
    return await db.insert('geofences', geofence.toMap());
  }

  Future<List<Geofence>> getGeofences() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('geofences');
    return List.generate(maps.length, (i) => Geofence.fromMap(maps[i]));
  }

  Future<int> updateGeofence(Geofence geofence) async {
    Database db = await database;
    return await db.update(
      'geofences',
      geofence.toMap(),
      where: 'id = ?',
      whereArgs: [geofence.id],
    );
  }

  Future<int> deleteGeofence(int id) async {
    Database db = await database;
    return await db.delete('geofences', where: 'id = ?', whereArgs: [id]);
  }
}
