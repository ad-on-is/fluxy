import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluxy/data/storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginForm extends HookConsumerWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlController = useTextEditingController();
    final userController = useTextEditingController();
    final passController = useTextEditingController();
    final creds = ref.watch(credentialsProvider);
    creds.whenData((value) {
      urlController.text = value.url;
      userController.text = value.user;
      passController.text = value.pass;
    });
    return Column(children: [
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
            ref.read(credentialsProvider.notifier).saveCredentials(Credentials(
                urlController.text, userController.text, passController.text));
          },
          child: const Text("Login"))
    ]);
  }
}
