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
  bool fetchRead = false;
  final markedAsRead = [];

  Miniflux(this.ref) {
    _client.options.headers['Content-Type'] = 'application/json';
    ref.watch(configProvider).whenData((v) => fetchRead = v.fetchReadNews);
    ref.watch(credentialsProvider).whenData((creds) => {
          _client.options.baseUrl = '${creds.url}/v1',
          if (creds.useKey)
            {_client.options.headers['X-Auth-Token'] = creds.key}
          else
            {
              _client.options.headers['Authorization'] =
                  'Basic ${base64.encode(utf8.encode("${creds.user}:${creds.pass}"))}'
            }
        });
  }

  static Future<bool> checkCredentials(Credentials creds,
      {bool showSnack = false}) async {
    final dio = Dio();
    try {
      dio.options.baseUrl = '${creds.url}/v1';
      if (creds.useKey) {
        dio.options.headers['X-Auth-Token'] = creds.key;
      } else {
        dio.options.headers['Authorization'] =
            'Basic ${base64.encode(utf8.encode("${creds.user}:${creds.pass}"))}';
      }

      final res = await dio.get("/me");
      if (res.statusCode! < 300) {
        if (showSnack) {
          showSnackBar("Credentials valid", color: Colors.green);
        }
        return true;
      }
    } catch (e) {
      showSnackBar("Error connecting to ${creds.url}", color: Colors.red);
      return false;
      // print("ERROR with creds");
    }
    showSnackBar("Invalid credentials", color: Colors.orange);
    return false;
  }

  Future<User> me() async {
    final response = await fetch(() => _client.get('/me'));
    return response.match((l) => User(0, "UNKNOWN"), (r) => User.fromJson(r));
  }

  Future<Version> version() async {
    final response = await fetch(() => _client.get('/version'));
    return response.match(
        (l) => Version("Version", "UNKNOWN"), (r) => Version.fromJson(r));
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

  void markAsRead(List<int> ids) async {
    final seen = ids.filter((s) => !markedAsRead.contains(s)).toList();
    if (seen.isEmpty) {
      return;
    }
    final res = await fetch(() =>
        _client.put('/entries', data: {"entry_ids": seen, "status": "read"}));

    if (res.isLeft()) {
      showSnackBar(res.getLeft().toString(), color: Colors.yellow);
    } else {
      markedAsRead.addAll(seen);
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

  Future<List<FeedEntry>> discoveryEntries(int limit, int offset) async {
    final entries = <FeedEntry>[];

    await Future.wait((await feeds()).map((feed) async {
      entries.addAll(await feedEntries(feed.id, limit, offset));
    }));
    entries.shuffle();
    return entries;
  }

  Future<List<FeedEntry>> categoryEntries(
      int category, int limit, int offset) async {
    final filter = !fetchRead ? "status=unread" : "status=unread&status=read";

    return (await fetch(() => _client.get(
            '/categories/$category/entries?limit=$limit&offset=${offset * limit}&order=published_at&direction=desc&$filter')))
        .match((l) {
      showSnackBar(l.toString(), color: Colors.yellow);
      return List<FeedEntry>.empty();
    },
            (r) => List.from(r["entries"])
                .map((e) => FeedEntry.fromJson(e))
                .toList());
  }

  Future<List<FeedEntry>> feedEntries(int feed, int limit, int offset) async {
    final filter = !fetchRead ? "status=unread" : "status=unread&status=read";
    return (await fetch(() => _client.get(
            '/feeds/$feed/entries?limit=$limit&offset=${offset * limit}&order=published_at&direction=desc&$filter')))
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
