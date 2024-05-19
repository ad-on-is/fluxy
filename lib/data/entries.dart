import 'package:fluxy/data/entities.dart';
import 'package:fluxy/data/miniflux.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod/riverpod.dart';

class EntrySource {
  final int id;
  final String type;

  EntrySource(this.id, this.type);
}

class EntriesNotifier extends FamilyAsyncNotifier<List<FeedEntry>, String> {
  int page = 0;

  Future<List<FeedEntry>> fetch() async {
    final s = getSource();
    if (s.type == "category") {
      if (s.id == 0) {
        return await ref.read(minifluxProvider).discoveryEntries(2, page);
      }
      return await ref
          .read(minifluxProvider)
          .categoryEntries(getSource().id, 20, page);
    } else {
      return await ref.read(minifluxProvider).feedEntries(s.id, 20, page);
    }
  }

  @override
  Future<List<FeedEntry>> build(arg) {
    return fetch();
  }

  EntrySource getSource() {
    final s = arg.split(":");
    return EntrySource(int.parse(s[1]), s[0]);
  }

  void loadMore() async {
    page++;
    state = await AsyncValue.guard(() async {
      final data = await fetch();
      return [...state.asData!.value, ...data];
    });
    print("Loaded more $arg $page");
  }

  void filterRead() {
    state = AsyncValue.data(state.asData!.value
        .filter((e) => !ref.read(seenProvider.notifier).read.contains(e.id))
        .toList());
  }
}

class SeenNotifier extends Notifier<Map<String, List<int>>> {
  @override
  Map<String, List<int>> build() {
    return {"seen": [], "read": []};
  }

  void markAsSeen(int id) {
    final ns = state;
    if (!ns["seen"]!.contains(id)) {
      ns["seen"] = [...ns["seen"]!, id];
    }

    state = ns;
    ref.read(minifluxProvider).markAsRead(ns["seen"]!);
  }

  void markSeenAsRead() {
    final ns = state;
    ns["read"] = [...ns["read"]!, ...ns["seen"]!];
    ns["seen"]!.clear();
    state = ns;
  }

  List<int> get seen => state["seen"]!;
  List<int> get read => state["read"]!;
}

final entriesProvider =
    AsyncNotifierProviderFamily<EntriesNotifier, List<FeedEntry>, String>(
        () => EntriesNotifier());

final categoriesProvider = FutureProvider<List<FeedCategory>>((ref) async {
  final categories = (await ref.read(minifluxProvider).categories())
      .filter((c) => c.title != "All")
      .toList();
  categories.insert(0, FeedCategory.fromJson({"id": 0, "title": "Discover"}));
  return categories;
});

final scrollToTopProvider = StateProvider<bool>((ref) {
  return false;
});

final categoryTitleProvider = StateProvider<String>((ref) {
  return "Discover";
});

final feedIconProvider =
    FutureProvider.family<String, FeedIcon?>((ref, feedIcon) async {
  if (feedIcon == null) {
    return "";
  }
  return await ref.read(minifluxProvider).feedIcon(feedIcon.iconId);
});

final feedsProvider = FutureProvider<List<Feed>>((ref) async {
  return await ref.read(minifluxProvider).feeds();
});

final seenProvider = NotifierProvider<SeenNotifier, Map<String, List<int>>>(
    () => SeenNotifier());
