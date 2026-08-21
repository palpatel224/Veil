import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Manages a unique, persistent user secret used to derive nullifier hashes.
///
/// The secret is generated once on first launch and stored securely in
/// the device's keystore (Keychain on iOS, EncryptedSharedPreferences on Android).
/// This ensures each installation produces unique nullifiers, allowing independent
/// claims per user without blocking others who use the same program.
class UserSecretService {
  static const String _secretKey = 'veil_user_nullifier_secret';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Returns the user's unique secret. Generates and persists one if it doesn't exist yet.
  static Future<String> getOrCreateSecret() async {
    final existing = await _storage.read(key: _secretKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    // First launch: generate a cryptographically random UUID as the secret
    final newSecret = const Uuid().v4();
    await _storage.write(key: _secretKey, value: newSecret);
    return newSecret;
  }

  /// For testing only — deletes the stored secret so a fresh one is generated next time.
  /// Do NOT expose this in the production UI.
  static Future<void> resetSecret() async {
    await _storage.delete(key: _secretKey);
  }
}
