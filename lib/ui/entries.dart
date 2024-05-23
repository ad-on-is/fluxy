import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fluxy/data/entities.dart';
import 'package:fluxy/data/entries.dart';
import 'package:fluxy/data/storage.dart';
import 'package:fluxy/helpers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

class EntryList extends HookConsumerWidget {
  final String sourceType;
  final int sourceId;
  const EntryList(
      {super.key, required this.sourceId, required this.sourceType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = [];
    final controller = useScrollController();
    Config? config;
    ref.watch(configProvider).whenData((v) => config = v);
    ref.watch(entriesProvider("$sourceType:$sourceId")).whenData((value) {
      entries.addAll(value);
    });

    if (ref.read(scrollToTopProvider) && controller.hasClients) {
      controller.jumpTo(0);
    }

    controller.addListener(() {
      if (!config!.infiniteScroll) {
        ref
            .read(listKeyProvider.notifier)
            .update((s) => "$sourceType:$sourceId");
        if (controller.position.pixels == controller.position.maxScrollExtent) {
          ref.read(showLoadMoreProvider.notifier).update((s) => true);
        } else {
          ref.read(showLoadMoreProvider.notifier).update((s) => false);
        }
      }
    });

    return MasonryGridView.count(
      itemCount: entries.length,
      controller: controller,
      addAutomaticKeepAlives: true,
      semanticChildCount: entries.length,
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
      itemBuilder: (BuildContext context, int index) => EntryCard(
        entry: entries[index],
        onLaunched: (int id) {
          ref.read(scrollToTopProvider.notifier).update((s) => true);
          ref.read(seenProvider.notifier).markSeenAsRead();
          ref
              .read(entriesProvider("$sourceType:$sourceId").notifier)
              .filterRead();
        },
        onOffScreen: (int id) {
          ref.read(scrollToTopProvider.notifier).update((s) => false);
          ref.read(seenProvider.notifier).markAsSeen(id);
        },
        onSeen: (int id) {
          if (!config!.infiniteScroll) {
            return;
          }
          final idx = entries.length - 10 > 0 ? entries.length - 10 : 0;
          if (entries[idx].id == id) {
            ref
                .read(entriesProvider("$sourceType:$sourceId").notifier)
                .loadMore();
          }
        },
      ),
    );
  }
}

class EntryCard extends HookConsumerWidget {
  final FeedEntry entry;
  final Function? onSeen;
  final Function? onOffScreen;
  final Function? onLaunched;
  const EntryCard(
      {super.key,
      required this.entry,
      this.onSeen,
      this.onLaunched,
      this.onOffScreen});

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

    useAutomaticKeepAlive();

    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    return VisibilityDetector(
      key: Key(entry.id.toString()),
      onVisibilityChanged: (info) {
        if (info.visibleFraction == 1.0) {
          // was on screen
          if (onSeen != null) {
            onSeen!(entry.id);
          }
        } else {
          if (info.visibleBounds.size.height < info.size.height * 0.7 &&
              info.visibleBounds.top > 0) {
            if (onOffScreen != null) {
              onOffScreen!(entry.id);
            }
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
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(height: 250),
                      // errorWidget: (context, url, error) => Icon(Icons.error),
                    )
                  : const SizedBox(),
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
                            Text(
                              Helpers.cutText(entry.feed.title, 30),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Text(
                          DateFormat("EEE, d. MMM y")
                              .format(entry.publishedAt.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall,
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
