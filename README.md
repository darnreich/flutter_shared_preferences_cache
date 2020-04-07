# shared_preferences_cache

A Cache for Flutter based on Shared Preferences. It is similar to the package flutter_cache_manager
but instead of caching cache downloaded files, shared_preferences_cache can cache plain values
(int, double, string, bool). This comes in handy if you want to cache a result of an expensive
operation or of an API call which cannot be cached with flutter_cache_manager.

## Usage
To use this plugin, add `shared_preferences_cache` as a
[dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

## Example

``` dart
import 'package:shared_preferences_cache/shared_preferences_cache.dart';

void main() async {
    SharedPreferencesCache spc = await SharedPreferencesCache.getInstance(Duration(days: 5));

    String myCachedValue = await spc.getString(key, () {
      // This code will only be executed if...
      // 1. No value for the given key exists in the cache
      // or
      // 2. The cached value is older then the provided maxAge (5 days in this example)
      return someExpensiveOperation();
    });
}
```

## To Do

* Proper API documentation

## Known Issues

* The library is not thread-safe. When used in parallel it can happen that the key and value pairs fall apart