import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluxy/data/entries.dart';
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
        ref.read(seenProvider.notifier).markSeenAsRead();
      }
      page.value = pp;
      if (categories.isEmpty) return;
      ref.read(headerTitleProvider.notifier).update((_) => HeaderTitle(
          categories[page.value].title,
          page.value == 0
              ? const Icon(Icons.category, color: Colors.yellow, size: 15)
              : const Icon(
                  Icons.label_important,
                  color: Colors.blue,
                  size: 15,
                )));
    });

    return PageView(
        controller: pageController,
        children: categories
            .map((e) => EntryList(sourceId: e.id, sourceType: "category"))
            .toList());
  }
}
