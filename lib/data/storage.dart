import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:riverpod/riverpod.dart';

GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
showSnackBar(String text, {Color color = Colors.black}) {
  if (scaffoldKey.currentState != null) {
    ScaffoldMessenger.of(scaffoldKey.currentContext!).removeCurrentSnackBar();
    ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: color,
    ));
  }
}

class Credentials {
  final String url;
  final String user;
  final String pass;
  Credentials(this.url, this.user, this.pass);
}

class CredentialsNotifier extends AsyncNotifier<Credentials> {
  @override
  Future<Credentials> build() async {
    return await getCredentials();
  }

  Future<bool> checkCredentials(Credentials creds) async {
    final dio = Dio();
    try {
      dio.options.baseUrl = '${creds.url}/v1';
      dio.options.headers['Authorization'] =
          'Basic ${base64.encode(utf8.encode("${creds.user}:${creds.pass}"))}';
      final res = await dio.get("/me");
      if (res.statusCode! < 300) {
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

  Future<void> saveCredentials(Credentials creds) async {
    if (await checkCredentials(creds)) {
      final box = await ref.read(hiveProvider);
      await box.put("url", creds.url);
      await box.put("user", creds.user);
      await box.put("pass", creds.pass);
      state = AsyncValue.data(creds);
    }
  }

  Future<void> clearCredentials() async {
    state = AsyncValue.data(Credentials("", "", ""));
  }

  Future<Credentials> getCredentials() async {
    final box = await ref.read(hiveProvider);
    final creds = Credentials(await box.get("url") ?? "",
        await box.get("user") ?? "", await box.get("pass") ?? "");
    state = AsyncValue.data(creds);

    return creds;
  }
}

final hiveProvider = Provider((ref) => Hive.openLazyBox("fluxy"));
final credentialsProvider =
    AsyncNotifierProvider<CredentialsNotifier, Credentials>(
        () => CredentialsNotifier());
