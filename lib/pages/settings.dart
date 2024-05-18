import 'package:flutter/material.dart';
import 'package:fluxy/ui/login_form.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Settings extends HookConsumerWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SingleChildScrollView(
      child: Column(
        children: [LoginForm()],
      ),
    );
  }
}
