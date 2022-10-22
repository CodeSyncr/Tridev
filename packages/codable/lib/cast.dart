import 'dart:async' as async;
import 'dart:core' as core;
import 'dart:core' hide Map, String, int;

class FailedCast implements core.Exception {
  dynamic context;
  dynamic key;
  core.String message;
  FailedCast(this.context, this.key, this.message);
  @override
  core.String toString() {
    if (key == null) {
      return "Failed cast at $context: $message";
    }
    return "Failed cast at $context $key: $message";
  }
}

abstract class Cast<T> {
  const Cast();
  T _cast(dynamic from, core.String context, dynamic key);
  T cast(dynamic from) => _cast(from, "toplevel", null);
}

class AnyCast extends Cast<dynamic> {
  const AnyCast();
  @override
  dynamic _cast(dynamic from, core.String context, dynamic key) => from;
}

class IntCast extends Cast<core.int> {
  const IntCast();
  @override
  core.int _cast(dynamic from, core.String context, dynamic key) =>
      from is core.int
          ? from
          : throw FailedCast(context, key, "$from is not an int");
}

class DoubleCast extends Cast<core.double> {
  const DoubleCast();
  @override
  core.double _cast(dynamic from, core.String context, dynamic key) =>
      from is core.double
          ? from
          : throw FailedCast(context, key, "$from is not an double");
}

class StringCast extends Cast<core.String> {
  const StringCast();
  @override
  core.String _cast(dynamic from, core.String context, dynamic key) =>
      from is core.String
          ? from
          : throw FailedCast(context, key, "$from is not a String");
}

class BoolCast extends Cast<core.bool> {
  const BoolCast();
  @override
  core.bool _cast(dynamic from, core.String context, dynamic key) =>
      from is core.bool
          ? from
          : throw FailedCast(context, key, "$from is not a bool");
}

class Map<K, V> extends Cast<core.Map<K, V>> {
  final Cast<K> _key;
  final Cast<V> _value;
  const Map(Cast<K> key, Cast<V> value)
      : _key = key,
        _value = value;
  @override
  core.Map<K, V> _cast(dynamic from, core.String context, dynamic key) {
    if (from is core.Map) {
      final result = <K, V>{};
      for (final key in from.keys) {
        final newKey = _key._cast(key, "map entry", key);
        result[newKey] = _value._cast(from[key], "map entry", key);
      }
      return result;
    }
    return throw FailedCast(context, key, "not a map");
  }
}

class StringMap<V> extends Cast<core.Map<core.String, V>> {
  final Cast<V> _value;
  const StringMap(Cast<V> value) : _value = value;
  @override
  core.Map<core.String, V> _cast(
    dynamic from,
    core.String context,
    dynamic key,
  ) {
    if (from is core.Map) {
      final result = <core.String, V>{};
      for (final core.String key in from.keys as core.Iterable<core.String>) {
        result[key] = _value._cast(from[key], "map entry", key);
      }
      return result;
    }
    return throw FailedCast(context, key, "not a map");
  }
}

class List<E> extends Cast<core.List<E?>> {
  final Cast<E> _entry;
  const List(Cast<E> entry) : _entry = entry;
  @override
  core.List<E?> _cast(dynamic from, core.String context, dynamic key) {
    if (from is core.List) {
      final length = from.length;
      final result = core.List<E?>.filled(length, null);
      for (core.int i = 0; i < length; ++i) {
        if (from[i] != null) {
          result[i] = _entry._cast(from[i], "list entry", i);
        } else {
          result[i] = null;
        }
      }
      return result;
    }
    return throw FailedCast(context, key, "not a list");
  }
}

class Keyed<K, V> extends Cast<core.Map<K, V?>> {
  Iterable<K> get keys => _map.keys;
  final core.Map<K, Cast<V>> _map;
  const Keyed(core.Map<K, Cast<V>> map) : _map = map;
  @override
  core.Map<K, V?> _cast(dynamic from, core.String context, dynamic key) {
    final core.Map<K, V?> result = {};
    if (from is core.Map) {
      for (final K key in from.keys as core.Iterable<K>) {
        if (_map.containsKey(key)) {
          result[key] = _map[key]!._cast(from[key], "map entry", key);
        } else {
          result[key] = from[key] as V?;
        }
      }
      return result;
    }
    return throw FailedCast(context, key, "not a map");
  }
}

class OneOf<S, T> extends Cast<dynamic> {
  final Cast<S> _left;
  final Cast<T> _right;
  const OneOf(Cast<S> left, Cast<T> right)
      : _left = left,
        _right = right;
  @override
  dynamic _cast(dynamic from, core.String context, dynamic key) {
    try {
      return _left._cast(from, context, key);
    } on FailedCast {
      return _right._cast(from, context, key);
    }
  }
}

class Apply<S, T> extends Cast<T> {
  final Cast<S> _first;
  final T Function(S) _transform;
  const Apply(T Function(S) transform, Cast<S> first)
      : _transform = transform,
        _first = first;
  @override
  T _cast(dynamic from, core.String context, dynamic key) =>
      _transform(_first._cast(from, context, key));
}

class Future<E> extends Cast<async.Future<E>> {
  final Cast<E> _value;
  const Future(Cast<E> value) : _value = value;
  @override
  async.Future<E> _cast(dynamic from, core.String context, dynamic key) {
    if (from is async.Future) {
      return from.then(_value.cast);
    }
    return throw FailedCast(context, key, "not a Future");
  }
}

const any = AnyCast();
const bool = BoolCast();
const int = IntCast();
const double = DoubleCast();
const string = StringCast();
