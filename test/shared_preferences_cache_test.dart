import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
    String res = await spc.getString(key, () {
      countFuncCalled++;
      return value;
    });
    expect(res, value);
    expect(countFuncCalled, 1);

    res = await spc.getString(key, () {
      countFuncCalled++;
      return otherValue;
    });
    expect(res, value);
    expect(countFuncCalled, 1);

    await spc.remove(key);

    res = await spc.getString(key, () {
      countFuncCalled++;
      return otherValue;
    });
    expect(res, otherValue);
    expect(countFuncCalled, 2);
  });

  test('eviction', () async {
    String res = await spc.getString(key, () {
      countFuncCalled++;
      return value;
    });
    expect(res, value);
    expect(countFuncCalled, 1);

    res = await spc.getString(key, () {
      countFuncCalled++;
      return otherValue;
    });
    expect(res, value);
    expect(countFuncCalled, 1);

    sleep(Duration(milliseconds: 200));

    res = await spc.getString(key, () {
      countFuncCalled++;
      return otherValue;
    });
    expect(res, otherValue);
    expect(countFuncCalled, 2);
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
