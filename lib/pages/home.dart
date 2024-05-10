import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluxy/data/miniflux.dart';
import 'package:fluxy/ui/entries.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Home extends HookConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = [];
    final page = useState(0);
    ref.watch(categoriesProvider).whenData((value) {
      categories.addAll(value);
    });

    final pageController = usePageController(initialPage: 0);
    pageController.addListener(() {
      final pp = pageController.page!.round();
      if (pp != page.value) {
        ref.read(readProvider.notifier).markScrolledAsRead();
      }
      page.value = pp;
      if (categories.isNotEmpty) {
        ref
            .read(categoryTitleProvider.notifier)
            .update((_) => categories[page.value].title);
      }
    });

    return PageView(
        controller: pageController,
        children:
            categories.map((e) => CategoryEntryList(category: e.id)).toList());
  }
}
