import 'package:flutter/material.dart';
import 'package:fluxy/data/entities.dart';
import 'package:fluxy/ui/entries.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FeedDetail extends HookConsumerWidget {
  final Feed feed;
  const FeedDetail(this.feed, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EntryList(sourceId: feed.id, sourceType: "feed");
  }
}
