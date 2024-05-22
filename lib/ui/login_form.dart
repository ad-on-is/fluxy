import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluxy/data/storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginForm extends HookConsumerWidget {
  final bool initial;
  const LoginForm({super.key, this.initial = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlController = useTextEditingController();
    final userController = useTextEditingController();
    final passController = useTextEditingController();
    final keyController = useTextEditingController();
    final init = useState(false);
    final useKey = useState(false);
    ref.watch(credentialsProvider).whenData((creds) {
      urlController.text = creds.url;
      userController.text = creds.user;
      passController.text = creds.pass;
      keyController.text = creds.key;
      if (!init.value) {
        useKey.value = creds.useKey;
        init.value = true;
      }
    });
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Column(children: [
        TextField(
            controller: urlController,
            decoration: const InputDecoration(
              labelText: "URL",
              icon: Icon(
                Icons.link,
                size: 20,
              ),
              hintText: "https://miniflux.example.com",
            )),
        const SizedBox(height: 15),
        TextField(
            controller: userController,
            decoration: const InputDecoration(
              icon: Icon(
                Icons.person,
                size: 20,
              ),
              labelText: "Username",
              hintText: "Username",
            )),
        const SizedBox(height: 15),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Use API Key", style: Theme.of(context).textTheme.bodyLarge),
            Switch(
              value: useKey.value,
              onChanged: (v) => useKey.value = v,
            ),
          ],
        ),
        !useKey.value
            ? TextField(
                controller: passController,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  icon: Icon(
                    Icons.key,
                    size: 20,
                  ),
                  labelText: "Password",
                  hintText: "Password",
                ))
            : TextField(
                controller: keyController,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  icon: Icon(
                    Icons.key,
                    size: 20,
                  ),
                  labelText: "API Key",
                  hintText: "API Key",
                )),
        const SizedBox(height: 15),
        ElevatedButton(
            onPressed: () async {
              ref.read(credentialsProvider.notifier).saveCredentials(
                  Credentials(urlController.text, userController.text,
                      passController.text, keyController.text, useKey.value));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                initial ? const Text("Login") : const Text("Save"),
                const SizedBox(width: 10),
                initial ? const Icon(Icons.login) : const Icon(Icons.save),
              ],
            ))
      ]),
    );
  }
}
