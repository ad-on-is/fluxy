import 'package:flutter/material.dart';
import 'package:fluxy/data/miniflux.dart';
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

class Config {
  final bool markAsReadOnScroll;
  final bool fetchReadNews;
  final bool hideReadNews;
  final bool infiniteScroll;
  Config(this.markAsReadOnScroll, this.fetchReadNews, this.hideReadNews,
      this.infiniteScroll);
}

class ConfigNotifier extends AsyncNotifier<Config> {
  @override
  Future<Config> build() async {
    return await getConfig();
  }

  Future<Config> getConfig() async {
    final box = await ref.read(hiveConfig);
    final config = Config(
      await box.get("markAsReadOnScroll") ?? true,
      await box.get("fetchReadNews") ?? false,
      await box.get("hideReadNews") ?? true,
      await box.get("infiniteScroll") ?? true,
    );
    state = AsyncValue.data(config);

    return config;
  }

  Future<void> saveConfig(Config config) async {
    final box = await ref.read(hiveConfig);
    await box.put("markAsReadOnScroll", config.markAsReadOnScroll);
    await box.put("fetchReadNews", config.fetchReadNews);
    await box.put("hideReadNews", config.hideReadNews);
    await box.put("infiniteScroll", config.infiniteScroll);
    state = AsyncValue.data(config);
  }
}

class Credentials {
  final String url;
  final String user;
  final String pass;
  final String key;
  final bool useKey;
  bool valid;

  Credentials(this.url, this.user, this.pass, this.key, this.useKey,
      {this.valid = false});
}

class CredentialsNotifier extends AsyncNotifier<Credentials> {
  @override
  Future<Credentials> build() async {
    return await getCredentials();
  }

  Future<void> saveCredentials(Credentials creds) async {
    creds.valid = await Miniflux.checkCredentials(creds, showSnack: true);
    final box = await ref.read(hiveCreds);
    if (!creds.valid) {
      return;
    }
    await box.put("url", creds.url);
    await box.put("user", creds.user);
    await box.put("pass", creds.pass);
    await box.put("key", creds.key);
    await box.put("useKey", creds.useKey);

    state = AsyncValue.data(creds);
  }

  Future<void> clearCredentials() async {
    state = AsyncValue.data(Credentials("", "", "", "", false));
  }

  Future<Credentials> getCredentials() async {
    final box = await ref.read(hiveCreds);
    final creds = Credentials(
      await box.get("url") ?? "",
      await box.get("user") ?? "",
      await box.get("pass") ?? "",
      await box.get("key") ?? "",
      await box.get("useKey") ?? false,
    );
    creds.valid = await Miniflux.checkCredentials(creds);

    if (creds.valid) {
      state = AsyncValue.data(creds);
    }
    return creds;
  }
}

final hiveCreds = Provider((ref) => Hive.openLazyBox("fluxy-creds"));
final hiveConfig = Provider((ref) => Hive.openLazyBox("fluxy-config"));
final credentialsProvider =
    AsyncNotifierProvider<CredentialsNotifier, Credentials>(
        () => CredentialsNotifier());

final configProvider =
    AsyncNotifierProvider<ConfigNotifier, Config>(() => ConfigNotifier());
