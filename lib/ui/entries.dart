import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fluxy/data/entities.dart';
import 'package:fluxy/data/entries.dart';
import 'package:fluxy/data/miniflux.dart';
import 'package:fluxy/helpers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CategoryEntryList extends HookConsumerWidget {
  final int category;
  const CategoryEntryList({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = [];
    final shouldScroll = ref.read(categoryShouldScrollToTop(category));
    final controller = useScrollController();

    ref.watch(categoryEntries(category)).whenData((value) {
      entries.addAll(value);
    });

    if (shouldScroll && controller.hasClients) {
      // controller.jumpTo(0);
    }

    return MasonryGridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
        itemCount: entries.length,
        controller: controller,
        itemBuilder: (ctx, index) => EntryCard(
              entry: entries[index],
              onLaunched: (int id) {
                // ref
                //     .read(categoryShouldScrollToTop(category).notifier)
                //     .update((s) => true);
                ref.read(seenProvider.notifier).markScrolledAsRead();
                ref.read(categoryEntries(category).notifier).filterRead();
              },
              onSeen: (int id) {
                ref.read(seenProvider.notifier).markAsSeen(id);
                final idx = entries.length - 10 > 0 ? entries.length - 10 : 0;
                if (entries[idx].id == id) {
                  ref.read(categoryEntries(category).notifier).loadMore();
                }
              },
            ));
  }
}

class EntryCard extends HookConsumerWidget {
  final FeedEntry entry;
  final Function? onSeen;
  final Function? onLaunched;
  const EntryCard(
      {super.key, required this.entry, this.onSeen, this.onLaunched});

  Future<void> _launchUrl(String url, WidgetRef ref) async {
    final uri = Uri.parse(url);
    if (await launchUrl(uri)) {
      if (onLaunched != null) {
        onLaunched!(entry.id);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String icon = "";
    ref
        .watch(feedIconProvider(entry.feed.icon))
        .whenData((value) => icon = value);

    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    return VisibilityDetector(
      key: Key(entry.id.toString()),
      onVisibilityChanged: (info) {
        if (info.visibleFraction == 1.0) {
          if (onSeen != null) {
            onSeen!(entry.id);
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 15, top: 15, left: 10, right: 10),
        child: RawMaterialButton(
          onPressed: () {
            _launchUrl(entry.url, ref);
          },
          child: Column(
            children: [
              entry.getImage() != ""
                  ? CachedNetworkImage(
                      imageUrl: entry.getImage(),
                      height: 300,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(height: 250),
                      // errorWidget: (context, url, error) => Icon(Icons.error),
                    )
                  : Container(
                      color: Colors.blue,
                    ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            icon != ""
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
                                  ),
                            const SizedBox(width: 5),
                            Opacity(
                                opacity: 0.6,
                                child: Text(
                                  Helpers.cutText(entry.feed.title, 30),
                                  style: Theme.of(context).textTheme.bodySmall,
                                )),
                          ],
                        ),
                        Opacity(
                          opacity: 0.4,
                          child: Text(
                            DateFormat("EEE, d. MMM y")
                                .format(entry.publishedAt.toLocal()),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Text(entry.content),
            ],
          ),
        ),
      ),
    );
  }
}
