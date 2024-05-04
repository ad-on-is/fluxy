import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Feeds extends HookConsumerWidget {
  const Feeds({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Text("feeds");
  }
}
