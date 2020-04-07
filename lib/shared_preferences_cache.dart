library shared_preferences_cache;

import 'dart:async';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesCache {
  static const String VALUE_PREFIX = 'spc_val_';
  static const String TS_PREFIX = 'spc_ts_';

  SharedPreferences _sharedPreferences;
  static SharedPreferencesCache _instance;

  static final Random random = Random();
  static const double evictChance = 0.05;

  Duration _maxAge;

  SharedPreferencesCache._(this._sharedPreferences, this._maxAge);

  static Future<SharedPreferencesCache> getInstance(Duration maxAge) async {
    if (_instance == null) {
      SharedPreferences sp = await SharedPreferences.getInstance();
      _instance = SharedPreferencesCache._(sp, maxAge);
    } else {
      _instance._maxAge = maxAge;
    }
    if (random.nextDouble() < evictChance) {
      // Eviction will only be executed every so ofter (based on evictChance)
      // This is a work-around to avoid race conditions if getInstance() is
      // called multiple times at roughly the same time.
      _instance.evict();
    }

    return _instance;
  }

  Future<void> evict() async {
    List<String> keys = _sharedPreferences.getKeys().toList();
    for (int i = 0; i < keys.length; i++) {
      String k = keys[i];
      if (k.startsWith(TS_PREFIX)) {
        int tsWritten = _sharedPreferences.getInt(k);
        if (tsWritten != null && _isTimestampExpired(tsWritten)) {
          await this.remove(k.substring(TS_PREFIX.length));
        }
      }
    }
  }

  Future<void> clear() async {
    List<String> keys = getKeys().toList();
    for (int i = 0; i < keys.length; i++) {
      await _sharedPreferences.remove(keys[i]);
    }
  }

  bool containsKey(String key) =>
      _sharedPreferences.containsKey(_getValueKey(key));

  Future<bool> getBool(String key, Future<bool> Function() f) async {
    if (!containsKey(key) || _isKeyExpired(key)) {
      await _setBool(key, await f());
    }
    return _sharedPreferences.getBool(_getValueKey(key));
  }

  Future<double> getDouble(String key, Future<double> Function() f) async {
    if (!containsKey(key) || _isKeyExpired(key)) {
      await _setDouble(key, await f());
    }
    return _sharedPreferences.getDouble(_getValueKey(key));
  }

  Future<int> getInt(String key, Future<int> Function() f) async {
    if (!containsKey(key) || _isKeyExpired(key)) {
      await _setInt(key, await f());
    }
    return _sharedPreferences.getInt(_getValueKey(key));
  }

  Future<String> getString(String key, Future<String> Function() f) async {
    if (!containsKey(key) || _isKeyExpired(key)) {
      await _setString(key, await f());
    }
    return _sharedPreferences.getString(_getValueKey(key));
  }

  Set<String> getKeys() {
    return _sharedPreferences
        .getKeys()
        .where((k) => k.startsWith(VALUE_PREFIX) || k.startsWith(TS_PREFIX))
        .toSet();
  }

  Future<void> reload() async {
    await _sharedPreferences.reload();
    await evict();
  }

  Future<bool> remove(String key) async {
    await _sharedPreferences.remove(_getTimestampKey(key));
    return _sharedPreferences.remove(_getValueKey(key));
  }

  Future<bool> _setBool(String key, bool value) async {
    await _setTimeStampForKey(key);
    return _sharedPreferences.setBool(_getValueKey(key), value);
  }

  Future<bool> _setDouble(String key, double value) async {
    await _setTimeStampForKey(key);
    return _sharedPreferences.setDouble(_getValueKey(key), value);
  }

  Future<bool> _setInt(String key, int value) async {
    await _setTimeStampForKey(key);
    return _sharedPreferences.setInt(_getValueKey(key), value);
  }

  Future<bool> _setString(String key, String value) async {
    await _setTimeStampForKey(key);
    return _sharedPreferences.setString(_getValueKey(key), value);
  }

  String _getValueKey(String forKey) {
    return VALUE_PREFIX + forKey;
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
