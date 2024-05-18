import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluxy/data/entities.dart';
import 'package:fluxy/data/entries.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Feeds extends HookConsumerWidget {
  const Feeds({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeds = [];
    ref.watch(feedsProvider).whenData((value) {
      feeds.addAll(value);
    });
    return ListView.builder(
        itemCount: feeds.length,
        itemBuilder: (ctx, index) => FeedListEntry(feeds[index]));
  }
}

class FeedListEntry extends HookConsumerWidget {
  final Feed feed;
  const FeedListEntry(this.feed, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String icon = "";
    ref.watch(feedIconProvider(feed.icon)).whenData((value) => icon = value);
    return ListTile(
        onTap: () {},
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
              )
        // child: Card(
        //   child: Row(
        //     mainAxisSize: MainAxisSize.max,
        //     children: [
        //       icon != ""
        //           ? Image.memory(
        //               base64Decode(icon),
        //               height: 40,
        //               width: 40,
        //               fit: BoxFit.cover,
        //             )
        //           : Container(
        //               width: 40,
        //               height: 40,
        //               color: Colors.blue.withAlpha(10),
        //             ),
        //       const SizedBox(width: 10),
        //       Flexible(
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Padding(
        //               padding: const EdgeInsets.only(right: 10.0),
        //               child: Text(
        //                 feed.title,
        //                 style: Theme.of(context).textTheme.bodyLarge,
        //                 overflow: TextOverflow.ellipsis,
        //               ),
        //             ),
        //             Opacity(
        //               opacity: 0.5,
        //               child: Row(
        //                 children: [
        //                   Text(
        //                     feed.category.title,
        //                   ),
        //                   const Text(" - "),
        //                   Text(feed.siteUrl,
        //                       style: Theme.of(context).textTheme.bodySmall)
        //                 ],
        //               ),
        //             )
        //           ],
        //         ),
        //       )
        //     ],
        //   ),
        // ),
        );
  }
}
