import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluxy/data/storage.dart';
import 'package:fluxy/pages/feeds.dart';
import 'package:fluxy/pages/home.dart';
import 'package:fluxy/data/miniflux.dart';
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
    Credentials creds = Credentials("", "", "");
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
          : creds.url == ""
              ? const Login()
              : const App(),
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

class Login extends HookConsumerWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlController = useTextEditingController();
    final userController = useTextEditingController();
    final passController = useTextEditingController();
    return Scaffold(
      key: scaffoldKey,
      body: SafeArea(
          child: Column(children: [
        TextField(
          controller: urlController,
        ),
        TextField(
          controller: userController,
        ),
        TextField(
          controller: passController,
        ),
        ElevatedButton(
            onPressed: () async {
              ref.read(credentialsProvider.notifier).saveCredentials(
                  Credentials(urlController.text, userController.text,
                      passController.text));
            },
            child: const Text("Login"))
      ])),
    );
  }
}

class App extends HookConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final title = ref.watch(categoryTitleProvider);
    final body = ref.watch(bodyProvider);
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Fluxy"),
            Row(
              children: [
                title == "Discover"
                    ? const Icon(
                        Icons.category,
                        color: Colors.lime,
                      )
                    : const Icon(
                        Icons.label_important,
                        color: Colors.blue,
                      ),
                const SizedBox(width: 10),
                Text(title),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  ref
                      .read(bodyProvider.notifier)
                      .update((state) => const Home());
                }),
            IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  ref
                      .read(bodyProvider.notifier)
                      .update((state) => const Feeds());
                }),
            IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
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
