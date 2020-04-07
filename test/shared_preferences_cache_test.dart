import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_cache/shared_preferences_cache.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  FakeSharedPreferencesStore store;
  SharedPreferencesCache spc;

  setUp(() async {
    store = FakeSharedPreferencesStore({});
    SharedPreferencesStorePlatform.instance = store;
    spc = await SharedPreferencesCache.getInstance(Duration(milliseconds: 50));
    spc.randomEvictChance = 0.0;
  });

  tearDown(() async {
    await spc.clear();
  });

  test('writing, getting and removing values', () async {
    String key = 'key1';
    String value = 'value';
    await spc.setString(key, value);
    expect(spc.containsKey(key), true);
    expect(spc.getString(key), value);

    String tsKey = SharedPreferencesCache.TS_PREFIX + key;
    expect(spc.containsKey(tsKey), true);

    await spc.remove(key);
    expect(spc.containsKey(key), false);
    expect(spc.containsKey(tsKey), false);
  });

  test('eviction', () async {
    String key1 = 'key1';
    String key2 = 'key2';
    String value = 'value';
    await spc.setString(key1, value);

    sleep(Duration(milliseconds: 200));

    await spc.setString(key2, value);
    await spc.evict();

    String tsKey1 = SharedPreferencesCache.TS_PREFIX + key1;
    expect(spc.containsKey(key1), false);
    expect(spc.containsKey(tsKey1), false);

    String tsKey2 = SharedPreferencesCache.TS_PREFIX + key2;
    expect(spc.containsKey(key2), true);
    expect(spc.containsKey(tsKey2), true);
  });

  test('bla', () async {
    int val = await spc.bla('key', () {
      print('calc');
      return 1;
    });
    print(val);

    val = await spc.bla('key', () {
      print('calc');
      return 1;
    });
    print(val);

    sleep(Duration(milliseconds: 200));

    val = await spc.bla('key', () {
      print('calc');
      return 1;
    });
    print(val);
  });
}

class FakeSharedPreferencesStore implements SharedPreferencesStorePlatform {
  FakeSharedPreferencesStore(Map<String, Object> data)
      : backend = InMemorySharedPreferencesStore.withData(data);

  final InMemorySharedPreferencesStore backend;

  @override
  bool get isMock => true;

  @override
  Future<bool> clear() {
    return backend.clear();
  }

  @override
  Future<Map<String, Object>> getAll() {
    return backend.getAll();
  }

  @override
  Future<bool> remove(String key) {
    return backend.remove(key);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    return backend.setValue(valueType, key, value);
  }
}
