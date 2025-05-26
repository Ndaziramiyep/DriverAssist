import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:driver_assist/models/service_provider_model.dart';
import 'package:driver_assist/models/chat_message_model.dart';

class LocalDatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'driver_assist.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Service Providers Table
    await db.execute('''
      CREATE TABLE service_providers(
        id TEXT PRIMARY KEY,
        name TEXT,
        type TEXT,
        address TEXT,
        latitude REAL,
        longitude REAL,
        phone_number TEXT,
        email TEXT,
        website TEXT,
        services TEXT,
        rating REAL,
        review_count INTEGER,
        is_verified INTEGER,
        is_open INTEGER,
        operating_hours TEXT,
        accepted_payment_methods TEXT,
        image_url TEXT,
        last_updated INTEGER
      )
    ''');

    // Chat Messages Table
    await db.execute('''
      CREATE TABLE chat_messages(
        id TEXT PRIMARY KEY,
        sender_id TEXT,
        receiver_id TEXT,
        message TEXT,
        timestamp INTEGER,
        is_read INTEGER,
        image_url TEXT,
        type TEXT,
        chat_id TEXT
      )
    ''');

    // Offline Actions Table
    await db.execute('''
      CREATE TABLE offline_actions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT,
        data TEXT,
        timestamp INTEGER,
        is_synced INTEGER
      )
    ''');
  }

  // Service Provider Methods
  Future<void> saveServiceProvider(ServiceProviderModel provider) async {
    final db = await database;
    await db.insert(
      'service_providers',
      {
        'id': provider.id,
        'name': provider.name,
        'type': provider.type,
        'address': provider.address,
        'latitude': provider.location.latitude,
        'longitude': provider.location.longitude,
        'phone_number': provider.phoneNumber,
        'email': provider.email,
        'website': provider.website,
        'services': provider.services.join(','),
        'rating': provider.rating,
        'review_count': provider.reviewCount,
        'is_verified': provider.isVerified ? 1 : 0,
        'is_open': provider.isOpen ? 1 : 0,
        'operating_hours': provider.operatingHours.toString(),
        'accepted_payment_methods': provider.acceptedPaymentMethods.join(','),
        'image_url': provider.imageUrl,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ServiceProviderModel>> getServiceProviders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('service_providers');

    return List.generate(maps.length, (i) {
      return ServiceProviderModel(
        id: maps[i]['id'],
        name: maps[i]['name'],
        type: maps[i]['type'],
        address: maps[i]['address'],
        location: GeoPoint(maps[i]['latitude'], maps[i]['longitude']),
        phoneNumber: maps[i]['phone_number'],
        email: maps[i]['email'],
        website: maps[i]['website'],
        services: maps[i]['services'].split(','),
        rating: maps[i]['rating'],
        reviewCount: maps[i]['review_count'],
        isVerified: maps[i]['is_verified'] == 1,
        isOpen: maps[i]['is_open'] == 1,
        operatingHours: Map<String, dynamic>.from(
          // Parse operating hours string to map
          {},
        ),
        acceptedPaymentMethods: maps[i]['accepted_payment_methods'].split(','),
        imageUrl: maps[i]['image_url'],
      );
    });
  }

  // Chat Message Methods
  Future<void> saveChatMessage(ChatMessageModel message, String chatId) async {
    final db = await database;
    await db.insert(
      'chat_messages',
      {
        'id': message.id,
        'sender_id': message.senderId,
        'receiver_id': message.receiverId,
        'message': message.message,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
        'is_read': message.isRead ? 1 : 0,
        'image_url': message.imageUrl,
        'type': message.type.toString().split('.').last,
        'chat_id': chatId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatMessageModel>> getChatMessages(String chatId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return ChatMessageModel(
        id: maps[i]['id'],
        senderId: maps[i]['sender_id'],
        receiverId: maps[i]['receiver_id'],
        message: maps[i]['message'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
        isRead: maps[i]['is_read'] == 1,
        imageUrl: maps[i]['image_url'],
        type: MessageType.values.firstWhere(
          (e) => e.toString() == 'MessageType.${maps[i]['type']}',
          orElse: () => MessageType.text,
        ),
      );
    });
  }

  // Offline Actions Methods
  Future<void> saveOfflineAction(String actionType, String data) async {
    final db = await database;
    await db.insert(
      'offline_actions',
      {
        'action_type': actionType,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'is_synced': 0,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedActions() async {
    final db = await database;
    return await db.query(
      'offline_actions',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> markActionAsSynced(int actionId) async {
    final db = await database;
    await db.update(
      'offline_actions',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [actionId],
    );
  }

  // Cleanup Methods
  Future<void> clearOldData() async {
    final db = await database;
    final oneWeekAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;

    await db.delete(
      'service_providers',
      where: 'last_updated < ?',
      whereArgs: [oneWeekAgo],
    );

    await db.delete(
      'chat_messages',
      where: 'timestamp < ?',
      whereArgs: [oneWeekAgo],
    );
  }
}