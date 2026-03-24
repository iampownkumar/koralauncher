import 'kora_database.dart';

// Fix — lazy singleton
KoraDatabase? _dbInstance;
KoraDatabase get db {
  _dbInstance ??= KoraDatabase();
  return _dbInstance!;
}