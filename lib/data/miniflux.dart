import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluxy/data/entities.dart';
import 'package:fluxy/data/storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod/riverpod.dart';

class AppFeeds {
  final categories = <FeedCategory>[];
  final categoryEntries = {};
}

class MF extends AsyncNotifier<AppFeeds> {
  final Dio _client = Dio();
  @override
  Future<AppFeeds> build() async {
    final creds = ref.watch(credentialsProvider);
    creds.whenData((value) => {
          _client.options.baseUrl = '${value.url}/v1',
          _client.options.headers['Authorization'] =
              'Basic ${base64.encode(utf8.encode("${value.user}:${value.pass}"))}'
        });
    getCategories();
    return AppFeeds();
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

  Future<void> getCategories() async {
    state = await AsyncValue.guard(() async {
      final current = state.asData!.value;
      current.categories
          .addAll((await fetch(() => _client.get('/categories'))).match((l) {
        showSnackBar(l.toString(), color: Colors.yellow);
        return List<FeedCategory>.empty();
      }, (r) => List.from(r).map((e) => FeedCategory.fromJson(e)).toList()));
      return current;
    });
  }
}

final mfProvider = AsyncNotifierProvider<MF, AppFeeds>(() => MF());

class Miniflux {
  final Dio _client = Dio();
  final Ref ref;

  Miniflux(this.ref) {
    final creds = ref.watch(credentialsProvider);
    creds.whenData((value) => {
          _client.options.baseUrl = '${value.url}/v1',
          _client.options.headers['Authorization'] =
              'Basic ${base64.encode(utf8.encode("${value.user}:${value.pass}"))}'
        });
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
    await fetch(() => _client.put('/entries/', data: {"entry_ids", ids}));
  }
}

final categoriesProvider =
    FutureProvider.autoDispose<List<FeedCategory>>((ref) async {
  final service = Miniflux(ref);
  final categories =
      (await service.categories()).filter((c) => c.title != "All").toList();
  categories.insert(0, FeedCategory.fromJson({"id": 0, "title": "Discover"}));
  return categories;
});

final categoryEntriesProvider =
    FutureProvider.family<List<FeedEntry>, int>((ref, category) async {
  if (category == 0) {
    return List<FeedEntry>.empty();
  }
  final service = Miniflux(ref);
  return await service.categoryEntries(category, 0);
});

final feedEntriesProvider =
    FutureProvider.family<List<FeedEntry>, int>((ref, feed) async {
  final service = Miniflux(ref);
  return await service.feedEntries(feed, 0);
});

final discoveryEntriesProvider = FutureProvider<List<FeedEntry>>((ref) async {
  final service = Miniflux(ref);
  final feeds = [];
  final entries = <FeedEntry>[];
  ref.watch(feedsProvider).whenData((value) => feeds.addAll(value));

  await Future.wait(feeds.map((feed) async {
    entries.addAll(await service.feedEntries(feed.id, 0));
  }));
  entries.shuffle();
  return entries;
});

final categoryTitleProvider = StateProvider<String>((ref) {
  return "Discover";
});

final feedIconProvider =
    FutureProvider.family<String, FeedIcon?>((ref, feedIcon) async {
  final service = Miniflux(ref);
  if (feedIcon == null) {
    return "";
  }
  return await service.feedIcon(feedIcon.iconId);
});

final feedsProvider = FutureProvider<List<Feed>>((ref) async {
  final service = Miniflux(ref);
  return await service.feeds();
});

final markAsReadProvider =
    FutureProvider.family<void, List<int>>((ref, ids) async {
  final service = Miniflux(ref);
  await service.markAsRead(ids);
});
