import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluxy/data/entities.dart';
import 'package:fluxy/data/entries.dart';
import 'package:fluxy/pages/feed_detail.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Feeds extends HookConsumerWidget {
  const Feeds({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeds = [];
    final pageController = usePageController();
    final refresh = useState(false);
    ref.watch(feedsProvider).whenData((value) {
      feeds.addAll(value);
    });

    ref.watch(subPageSwitchProvider);

    pageController.animateTo(0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubicEmphasized);

    pageController.addListener(() {
      final pp = pageController.page!.round();
      if (feeds.isEmpty) return;
      ref.read(headerTitleProvider.notifier).update((_) => pp == 0
          ? HeaderTitle(
              "Feeds",
              const Icon(
                Icons.rss_feed,
                color: Colors.green,
                size: 15,
              ))
          : HeaderTitle(feeds[pp - 1].title,
              Consumer(builder: (context, ref, _) {
              String icon = "";
              ref.watch(feedIconProvider(feeds[pp - 1].icon)).whenData((value) {
                icon = value;
              });
              return icon != ""
                  ? Image.memory(
                      base64Decode(icon),
                      height: 15,
                      width: 15,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 15,
                      height: 15,
                      color: Colors.blue.withAlpha(10),
                    );
            })));
    });
    return RefreshIndicator(
      onRefresh: () async {
        refresh.value = !refresh.value;
      },
      child: PageView(
        controller: pageController,
        children: [
          ListView.builder(
              itemCount: feeds.length,
              itemBuilder: (ctx, index) => FeedListEntry(
                    feeds[index],
                    onTap: (feed) {
                      pageController.animateTo(
                          MediaQuery.of(context).size.width * (index + 1),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubicEmphasized);
                    },
                  )),
          for (var feed in feeds)
            FeedDetail(
              feed,
              key: ValueKey(feed.id),
            )
        ],
      ),
    );
  }
}

class FeedListEntry extends HookConsumerWidget {
  final Feed feed;
  final Function? onTap;
  const FeedListEntry(this.feed, {super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String icon = "";
    ref.watch(feedIconProvider(feed.icon)).whenData((value) => icon = value);
    return ListTile(
        onTap: () {
          if (onTap != null) {
            onTap!(feed);
          }
        },
        title: Text(
          feed.title,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Opacity(
          opacity: 0.5,
          child: Row(children: [
            Text(
              feed.category.title,
            ),
            const Text(" - "),
            Text(feed.siteUrl, style: Theme.of(context).textTheme.bodySmall)
          ]),
        ),
        trailing: const Icon(Icons.arrow_right),
        leading: icon != ""
            ? Image.memory(
                base64Decode(icon),
                height: 40,
                width: 40,
                fit: BoxFit.cover,
              )
            : Container(
                width: 40,
                height: 40,
                color: Colors.blue.withAlpha(10),
              ));
  }
}
