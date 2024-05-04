import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluxy/data/entities.dart';
import 'package:fluxy/data/miniflux.dart';
import 'package:fluxy/helpers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EntryList extends HookConsumerWidget {
  final int category;
  const EntryList({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = [];
    if (category == 0) {
      ref
          .watch(discoveryEntriesProvider)
          .whenData((value) => entries.addAll(value));
    } else {
      ref
          .watch(categoryEntriesProvider(category))
          .whenData((value) => entries.addAll(value));
    }

    final controller = useScrollController();
    controller.addListener(() {
      if (controller.position.pixels == controller.position.maxScrollExtent) {
        print("END REACHED");
        if (category == 0) {
          // ref.read(discoveryEntriesProvider.notifier).loadMore();
        } else {
          // ref.read(categoryEntriesProvider(category).notifier).loadMore();
        }
      }
    });

    return ListView.builder(
        controller: controller,
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return EntryCard(entry: entry);
        });
  }
}

class EntryCard extends HookConsumerWidget {
  final FeedEntry entry;
  const EntryCard({super.key, required this.entry});

  Future<void> _launchUrl(String url, WidgetRef ref) async {
    final uri = Uri.parse(url);
    if (await launchUrl(uri)) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String icon = "";
    ref
        .watch(feedIconProvider(entry.feed.icon))
        .whenData((value) => icon = value);

    return Card(
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
                    height: 250,
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
    );
  }
}
