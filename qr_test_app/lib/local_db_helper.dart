import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const int version = 1;
  static const String dbName = "locations.db";
  static const String tableName = "Locations";


  static Database? _database;

  static Future<Database?> getDatabase() async {
    if (_database != null) return _database;

    // Get the database path
    final dbPath = await getDatabasesPath();

    _database = await openDatabase(
      join(dbPath, dbName),
      onCreate: (db, version) {
        // Create locations table
        db.execute(
            "CREATE TABLE $tableName (id INTEGER PRIMARY KEY AUTOINCREMENT, latitude REAL, longitude REAL)");
      },
      version: version,
    );

    return _database;
  }

  static Future<int> saveLocation(LocationModel location) async {
    final db = await getDatabase();
    return db!.insert(tableName, location.toMap());
  }

  static Future<List<LocationModel>> getAllLocations() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db!.query(tableName);
    return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
  }

  static closeDatabase(){
    _database?.close();
  }
}

class LocationModel {
  final double latitude;
  final double longitude;

  LocationModel(this.latitude, this.longitude);

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static LocationModel fromMap(Map<String, dynamic> map) {
    return LocationModel(
      map['latitude'] as double,
      map['longitude'] as double,
    );
  }
}

