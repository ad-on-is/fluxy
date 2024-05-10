import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluxy/data/entities.dart';
import 'package:fluxy/data/storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod/riverpod.dart';

class Miniflux {
  final Dio _client = Dio();
  final Ref ref;

  Miniflux(this.ref) {
    ref.watch(credentialsProvider).whenData((value) => {
          _client.options.baseUrl = '${value.url}/v1',
          _client.options.headers['Authorization'] =
              'Basic ${base64.encode(utf8.encode("${value.user}:${value.pass}"))}'
        });
    ref.watch(readProvider);
    _listenForRead();
  }

  void _listenForRead() {
    final read = ref.read(readProvider);
    markAsRead(read);
  }

  Future<dynamic>? me() async {
    final response = await fetch(() => _client.get('/me'));
    return response.match((l) => l, (r) => null);
  }

  Future<Either<Exception, dynamic>> fetch(
      Future<Response> Function() method) async {
    try {
      Response response = await method();
      return right(response.data);
    } on DioException catch (e) {
      return left(
          Exception("${e.response?.statusCode}: ${e.response?.statusMessage}"));
    }
  }

  Future<List<Feed>> feeds() async {
    return (await fetch(() => _client.get('/feeds'))).match((l) {
      showSnackBar(l.toString(), color: Colors.yellow);
      return List<Feed>.empty();
    }, (r) => List.from(r).map((e) => Feed.fromJson(e)).toList());
  }

  Future<List<FeedCategory>> categories() async {
    return (await fetch(() => _client.get('/categories'))).match((l) {
      showSnackBar(l.toString(), color: Colors.yellow);
      return List<FeedCategory>.empty();
    }, (r) => List.from(r).map((e) => FeedCategory.fromJson(e)).toList());
  }

  Future<List<FeedEntry>> discoveryEntries() async {
    final entries = <FeedEntry>[];

    await Future.wait((await feeds()).map((feed) async {
      entries.addAll(await feedEntries(feed.id, 0));
    }));
    entries.shuffle();
    return entries;
  }

  Future<List<FeedEntry>> categoryEntries(int category, int offset) async {
    return (await fetch(
            () => _client.get('/categories/$category/entries?limit=20')))
        .match((l) {
      showSnackBar(l.toString(), color: Colors.yellow);
      return List<FeedEntry>.empty();
    },
            (r) => List.from(r["entries"])
                .map((e) => FeedEntry.fromJson(e))
                .toList());
  }

  Future<List<FeedEntry>> feedEntries(int feed, int offset) async {
    return (await fetch(() => _client.get('/feeds/$feed/entries?limit=3')))
        .match((l) {
      showSnackBar(l.toString(), color: Colors.yellow);
      return List<FeedEntry>.empty();
    },
            (r) => List.from(r["entries"])
                .map((e) => FeedEntry.fromJson(e))
                .toList());
  }

  Future<String> feedIcon(int iconId) async {
    final response = await fetch(() => _client.get('/icons/$iconId'));
    String data = response.match((l) => "", (r) => r["data"]);
    return data.substring(data.indexOf("base64,") + "base64,".length);
  }

  Future<void> markAsRead(List<int> ids) async {
    print("marked as read $ids");
    // await fetch(() =>
    //     _client.put('/entries/', data: {"entry_ids": ids, "status": "read"}));
  }
}

final minifluxProvider = Provider((ref) => Miniflux(ref));

class EntriesNotifier extends FamilyAsyncNotifier<List<FeedEntry>, int> {
  Future<List<FeedEntry>> fetch() async {
    if (arg == 0) {
      return await ref.read(minifluxProvider).discoveryEntries();
    }
    return await ref.read(minifluxProvider).categoryEntries(arg, 0);
  }

  @override
  Future<List<FeedEntry>> build(int arg) async {
    ref.watch(readProvider);
    print("ENTRIEEEEZ");
    if (state.value == null) {
      return fetch();
    }
    return state.value!;
  }

  Future<void> loadMore() async {
    state = await AsyncValue.guard(() async {
      final entries = await fetch();
      return [...state.value ?? [], ...entries];
    });
  }
}

final ce = AsyncNotifierProvider.family<EntriesNotifier, List<FeedEntry>, int>(
    EntriesNotifier.new);
final categoriesProvider = FutureProvider<List<FeedCategory>>((ref) async {
  final categories = (await ref.read(minifluxProvider).categories())
      .filter((c) => c.title != "All")
      .toList();
  categories.insert(0, FeedCategory.fromJson({"id": 0, "title": "Discover"}));
  return categories;
});

final categoryLoadMore = StateProvider.family<bool, int>((ref, category) {
  return false;
});

final categoryShouldScrollToTop =
    StateProvider.family<bool, int>((ref, category) {
  return false;
});

final categoryEntriesProvider =
    FutureProvider.family<List<FeedEntry>, int>((ref, category) async {
  ref.watch(categoryLoadMore(category));
  if (category == 0) {
    return await ref.read(minifluxProvider).discoveryEntries();
  } else {
    return await ref.read(minifluxProvider).categoryEntries(category, 0);
  }
});

final categoryEntries =
    StateProvider.family<List<FeedEntry>, int>((ref, category) {
  final entries = <FeedEntry>[];
  ref
      .watch(categoryEntriesProvider(category))
      .whenData((value) => entries.addAll(value));

  print(entries.length);

  return entries
      .filter((e) => !ref.watch(readProvider).contains(e.id))
      .toList();
});

final feedEntriesProvider =
    FutureProvider.family<List<FeedEntry>, int>((ref, feed) async {
  return await ref.read(minifluxProvider).feedEntries(feed, 0);
});

final feedEntries = StateProvider.family<List<FeedEntry>, int>((ref, feed) {
  final entries = <FeedEntry>[];
  if (entries.isEmpty) {
    ref
        .watch(feedEntriesProvider(feed))
        .whenData((value) => entries.addAll(value));
  }

  return entries
      .filter((e) => !ref.watch(readProvider).contains(e.id))
      .toList();
});

final categoryTitleProvider = StateProvider<String>((ref) {
  return "Discover";
});

final feedIconProvider =
    FutureProvider.family<String, FeedIcon?>((ref, feedIcon) async {
  if (feedIcon == null) {
    return "";
  }
  return await ref.read(minifluxProvider).feedIcon(feedIcon.iconId);
});

final feedsProvider = FutureProvider<List<Feed>>((ref) async {
  return await ref.read(minifluxProvider).feeds();
});

class ReadFeeds {
  List<int> read = [];
  List<int> scrolled = [];
}

class ReadFeedsNotifier extends Notifier<List<int>> {
  @override
  List<int> build() {
    return [];
  }

  void markScrolledAsRead() {
    state = [...state, ...ref.read(scrolledProvider)];
    ref.read(scrolledProvider.notifier).clear();
  }
}

class ScrolledFeedsNotifier extends Notifier<List<int>> {
  @override
  List<int> build() {
    return [];
  }

  void markAsScrolled(int id) {
    if (!state.contains(id)) {
      state = [...state, id];
    }
    // print(state);
  }

  void clear() {
    state = [];
  }
}

final readProvider =
    NotifierProvider<ReadFeedsNotifier, List<int>>(() => ReadFeedsNotifier());

final scrolledProvider = NotifierProvider<ScrolledFeedsNotifier, List<int>>(
    () => ScrolledFeedsNotifier());
