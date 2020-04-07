library shared_preferences_cache;

import 'dart:async';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesCache implements SharedPreferences {
  static const String TS_PREFIX = 'spc_ts_';

  SharedPreferences _sharedPreferences;
  static SharedPreferencesCache _instance;

  Duration _maxAge;
  Random _random = Random.secure();
  double randomEvictChance = 0.05;

  SharedPreferencesCache._(this._sharedPreferences, this._maxAge);

  static Future<SharedPreferences> getInstance(Duration maxAge) async {
    if(_instance == null) {
      SharedPreferences sp = await SharedPreferences.getInstance();
      _instance = SharedPreferencesCache._(sp, maxAge);
    }
    else {
      _instance._maxAge = maxAge;
    }
    _instance.evict();
    return _instance;
  }

  Future<void> _randomEvict() async {
    if (randomEvictChance == 0.0) {
      return;
    }

    double value = _random.nextDouble();
    if (value < randomEvictChance) {
      await evict();
    }
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

  @override
  Future<bool> clear() => _sharedPreferences.clear();

  @override
  @deprecated
  Future<bool> commit() => _sharedPreferences.commit();

  @override
  bool containsKey(String key) => _sharedPreferences.containsKey(key);

  @override
  get(String key) => _sharedPreferences.get(key);

  @override
  bool getBool(String key) => _sharedPreferences.getBool(key);

  @override
  double getDouble(String key) => _sharedPreferences.getDouble(key);

  @override
  int getInt(String key) => _sharedPreferences.getInt(key);

  @override
  Set<String> getKeys() => _sharedPreferences.getKeys();

  @override
  String getString(String key) => _sharedPreferences.getString(key);

  @override
  List<String> getStringList(String key) =>
      _sharedPreferences.getStringList(key);

  @override
  Future<void> reload() async {
    await _sharedPreferences.reload();
    await evict();
  }

  @override
  Future<bool> remove(String key) async {
    await _randomEvict();
    await _sharedPreferences.remove(_getTimestampKey(key));
    return _sharedPreferences.remove(key);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    await _randomEvict();
    await _setTimeStampForKey(key);
    return _sharedPreferences.setBool(key, value);
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    await _randomEvict();
    await _setTimeStampForKey(key);
    return _sharedPreferences.setDouble(key, value);
  }

  @override
  Future<bool> setInt(String key, int value) async {
    await _randomEvict();
    await _setTimeStampForKey(key);
    return _sharedPreferences.setInt(key, value);
  }

  @override
  Future<bool> setString(String key, String value) async {
    await _randomEvict();
    await _setTimeStampForKey(key);
    return _sharedPreferences.setString(key, value);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    await _randomEvict();
    await _setTimeStampForKey(key);
    return _sharedPreferences.setStringList(key, value);
  }

  Future<int> bla(String key, int Function() f) async {
    if (!containsKey(key) || _isKeyExpired(key)) {
      await setInt(key, f());
    }
    return getInt(key);
  }
}
