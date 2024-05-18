import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluxy/data/entities.dart';
import 'package:fluxy/data/entries.dart';
import 'package:fluxy/data/storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod/riverpod.dart';

class Miniflux {
  final Dio _client = Dio();
  final Ref ref;
  final markedAsRead = [];

  Miniflux(this.ref) {
    ref.watch(credentialsProvider).whenData((value) => {
          _client.options.baseUrl = '${value.url}/v1',
          _client.options.headers['Authorization'] =
              'Basic ${base64.encode(utf8.encode("${value.user}:${value.pass}"))}'
        });
    ref.watch(seenProvider);
    _listenForRead();
  }

  void _listenForRead() {
    final seen = ref
        .read(seenProvider.notifier)
        .seen
        .filter((s) => !markedAsRead.contains(s))
        .toList();
    print("MINIFLUX: mark as read");
    // await fetch(() =>
    //     _client.put('/entries/', data: {"entry_ids": ids, "status": "read"}));
    markedAsRead.addAll(seen);
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
}

final minifluxProvider = Provider((ref) => Miniflux(ref));
