import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_cache/shared_preferences_cache.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  FakeSharedPreferencesStore store;
  SharedPreferencesCache spc;

  String key = 'key1';
  String value = 'value';
  String otherValue = 'other value';
  int countFuncCalled = 0;

  setUp(() async {
    store = FakeSharedPreferencesStore({});
    SharedPreferencesStorePlatform.instance = store;
    spc = await SharedPreferencesCache.getInstance(Duration(milliseconds: 50));
    countFuncCalled = 0;
  });

  tearDown(() async {
    await spc.clear();
  });

  test('writing, getting and removing values', () async {
    String res = await spc.getString(key, () async {
      countFuncCalled++;
      return value;
    });
    expect(res, value);
    expect(countFuncCalled, 1);

    res = await spc.getString(key, () async {
      countFuncCalled++;
      return otherValue;
    });
    expect(res, value);
    expect(countFuncCalled, 1);

    await spc.remove(key);

    res = await spc.getString(key, () async {
      countFuncCalled++;
      return otherValue;
    });
    expect(res, otherValue);
    expect(countFuncCalled, 2);
  });

  test('eviction policy', () async {
    String res = await spc.getString(key, () async {
      countFuncCalled++;
      return value;
    });
    expect(res, value);
    expect(countFuncCalled, 1);

    res = await spc.getString(key, () async {
      countFuncCalled++;
      return otherValue;
    });
    expect(res, value);
    expect(countFuncCalled, 1);

    sleep(Duration(milliseconds: 200));

    res = await spc.getString(key, () async {
      countFuncCalled++;
      return otherValue;
    });
    expect(res, otherValue);
    expect(countFuncCalled, 2);
  });

  test('clear', () async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setString('foo', 'bar');

    await spc.getString(key, () async => value);

    expect(sp.containsKey('foo'), true);
    expect(spc.containsKey('foo'), false);

    expect(spc.containsKey(key), true);
    expect(sp.containsKey(SharedPreferencesCache.VALUE_PREFIX + key), true);
    expect(sp.containsKey(SharedPreferencesCache.TS_PREFIX + key), true);

    await spc.clear();

    expect(sp.containsKey('foo'), true);
    expect(spc.containsKey('foo'), false);

    expect(spc.containsKey(key), false);
    expect(sp.containsKey(SharedPreferencesCache.VALUE_PREFIX + key), false);
    expect(sp.containsKey(SharedPreferencesCache.TS_PREFIX + key), false);
  });

  test('remove', () async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await spc.getString(key, () async => value);
    expect(spc.containsKey(key), true);
    expect(sp.containsKey(SharedPreferencesCache.VALUE_PREFIX + key), true);
    expect(sp.containsKey(SharedPreferencesCache.TS_PREFIX + key), true);

    await spc.remove(key);

    expect(spc.containsKey(key), false);
    expect(sp.containsKey(SharedPreferencesCache.VALUE_PREFIX + key), false);
    expect(sp.containsKey(SharedPreferencesCache.TS_PREFIX + key), false);
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
