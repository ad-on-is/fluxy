import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluxy/data/entries.dart';
import 'package:fluxy/data/storage.dart';
import 'package:fluxy/pages/feeds.dart';
import 'package:fluxy/pages/home.dart';
import 'package:fluxy/ui/login_form.dart';
import 'package:fluxy/pages/settings.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  await Hive.initFlutter();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: Main()));
}

class Main extends HookConsumerWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context, ref) {
    Credentials? creds;
    final loading = useState(true);

    ref.watch(credentialsProvider).whenData((value) {
      loading.value = false;
      creds = value;
    });
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: loading.value
          ? const Loading()
          : creds!.url == ""
              ? const Login()
              : const App(),
    );
  }
}

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: SafeArea(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset("assets/applogo.svg"),
                const SizedBox(width: 10),
                const Text("Fluxy", style: TextStyle(fontSize: 50)),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            Opacity(
              opacity: 0.5,
              child: Text("Enjoy your RSS feeds",
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
            const SizedBox(
              height: 30,
            ),
            const LoginForm(initial: true)
          ],
        ),
      )),
    );
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class App extends HookConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final ht = ref.watch(headerTitleProvider);
    final body = ref.watch(bodyProvider);
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  "assets/applogo.svg",
                  height: 40,
                ),
                const SizedBox(width: 10),
                const Text("Fluxy", style: TextStyle(fontSize: 30)),
              ],
            ),
            Row(
              children: [
                SizedBox(
                    width: 200,
                    child: Text(
                      ht.title,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodyLarge,
                    )),
                const SizedBox(width: 5),
                ht.icon,
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            RawMaterialButton(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                highlightColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Icon(
                  Icons.home,
                  color: body is Home ? Colors.yellow : null,
                ),
                onPressed: () {
                  ref.read(headerTitleProvider.notifier).update((_) =>
                      HeaderTitle(
                          "Discover",
                          const Icon(Icons.category,
                              color: Colors.yellow, size: 15)));
                  ref
                      .read(bodyProvider.notifier)
                      .update((state) => const Home());
                }),
            RawMaterialButton(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                highlightColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Icon(Icons.rss_feed,
                    color: body is Feeds ? Colors.green : null),
                onPressed: () {
                  ref
                      .read(headerTitleProvider.notifier)
                      .update((_) => HeaderTitle(
                          "Feeds",
                          const Icon(
                            Icons.rss_feed,
                            color: Colors.green,
                            size: 15,
                          )));
                  ref
                      .read(bodyProvider.notifier)
                      .update((state) => const Feeds());

                  ref.read(subPageSwitchProvider.notifier).update((s) => !s);
                }),
            RawMaterialButton(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                highlightColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Icon(Icons.settings,
                    color: body is Settings ? Colors.blue : null),
                onPressed: () {
                  ref.read(headerTitleProvider.notifier).update((_) =>
                      HeaderTitle(
                          "Settings",
                          const Icon(Icons.settings,
                              color: Colors.blue, size: 15)));
                  ref
                      .read(bodyProvider.notifier)
                      .update((state) => const Settings());
                }),
          ],
        ),
      ),
      body: SafeArea(
          child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: body,
      )),
    );
  }
}

final bodyProvider = StateProvider<Widget>((ref) => const Home());
