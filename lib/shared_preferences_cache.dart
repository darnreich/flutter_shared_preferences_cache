library shared_preferences_cache;

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesCache {
  static const String TS_PREFIX = 'spc_ts_';

  SharedPreferences _sharedPreferences;
  static SharedPreferencesCache _instance;

  Duration _maxAge;

  SharedPreferencesCache._(this._sharedPreferences, this._maxAge);

  static Future<SharedPreferencesCache> getInstance(Duration maxAge) async {
    if (_instance == null) {
      SharedPreferences sp = await SharedPreferences.getInstance();
      _instance = SharedPreferencesCache._(sp, maxAge);
    } else {
      _instance._maxAge = maxAge;
    }
    _instance.evict();
    return _instance;
  }

  Future<void> evict() async {
    List<String> keys = _sharedPreferences.getKeys().toList();
    for (int i = 0; i < keys.length; i++) {
      String k = keys[i];
      if (k.startsWith(TS_PREFIX)) {
        int tsWritten = _sharedPreferences.getInt(k);
        if (_isTimestampExpired(tsWritten)) {
          await this.remove(k.substring(TS_PREFIX.length));
        }
      }
    }
  }

  Future<bool> clear() => _sharedPreferences.clear();

  bool containsKey(String key) => _sharedPreferences.containsKey(key);

  Future<bool> getBool(String key, bool Function() f) async {
    if (!containsKey(key) || _isKeyExpired(key)) {
      await _setBool(key, f());
    }
    return _sharedPreferences.getBool(key);
  }

  Future<double> getDouble(String key, double Function() f) async {
    if (!containsKey(key) || _isKeyExpired(key)) {
      await _setDouble(key, f());
    }
    return _sharedPreferences.getDouble(key);
  }

  Future<int> getInt(String key, int Function() f) async {
    if (!containsKey(key) || _isKeyExpired(key)) {
      await _setInt(key, f());
    }
    return _sharedPreferences.getInt(key);
  }

  Future<String> getString(String key, String Function() f) async {
    if (!containsKey(key) || _isKeyExpired(key)) {
      await _setString(key, f());
    }
    return _sharedPreferences.getString(key);
  }

  Set<String> getKeys({bool includeTimestampKeys = false}) {
    bool Function(String k) testFunction = includeTimestampKeys
        ? (String k) => true
        : (String k) => !k.startsWith(TS_PREFIX);
    return _sharedPreferences.getKeys().where(testFunction).toSet();
  }

  Future<void> reload() async {
    await _sharedPreferences.reload();
    await evict();
  }

  Future<bool> remove(String key) async {
    await _sharedPreferences.remove(_getTimestampKey(key));
    return _sharedPreferences.remove(key);
  }

  Future<bool> _setBool(String key, bool value) async {
    await _setTimeStampForKey(key);
    return _sharedPreferences.setBool(key, value);
  }

  Future<bool> _setDouble(String key, double value) async {
    await _setTimeStampForKey(key);
    return _sharedPreferences.setDouble(key, value);
  }

  Future<bool> _setInt(String key, int value) async {
    await _setTimeStampForKey(key);
    return _sharedPreferences.setInt(key, value);
  }

  Future<bool> _setString(String key, String value) async {
    await _setTimeStampForKey(key);
    return _sharedPreferences.setString(key, value);
  }

  String _getTimestampKey(String forKey) {
    return TS_PREFIX + forKey;
  }

  bool _isTimestampExpired(int ts) {
    int diff = DateTime.now().millisecondsSinceEpoch - ts;
    return diff > _maxAge.inMilliseconds;
  }

  bool _isKeyExpired(String key) {
    int ts = _sharedPreferences.getInt(_getTimestampKey(key));
    return ts == null || _isTimestampExpired(ts);
  }

  Future _setTimeStampForKey(String key) async {
    int ts = DateTime.now().millisecondsSinceEpoch;
    return _sharedPreferences.setInt(_getTimestampKey(key), ts);
  }
}
