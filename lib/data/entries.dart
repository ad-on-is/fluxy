import 'package:fluxy/data/entities.dart';
import 'package:fluxy/data/miniflux.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod/riverpod.dart';

class EntriesNotifier extends FamilyAsyncNotifier<List<FeedEntry>, int> {
  int page = 0;

  Future<List<FeedEntry>> fetch() async {
    // ref.read(minifluxProvider).feedEntries(feed, 0);
    if (arg == 0) {
      return await ref.read(minifluxProvider).discoveryEntries();
    }
    return await ref.read(minifluxProvider).categoryEntries(arg, page);
  }

  @override
  Future<List<FeedEntry>> build(arg) {
    return fetch();
  }

  void loadMore() async {
    page++;
    state = await AsyncValue.guard(() async {
      final data = await fetch();
      return [...state.asData!.value, ...data];
    });
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
  }

  void markScrolledAsRead() {
    final ns = state;
    ns["read"] = [...ns["read"]!, ...ns["seen"]!];
    ns["seen"]!.clear();
    state = ns;
  }

  List<int> get seen => state["seen"]!;
  List<int> get read => state["read"]!;
}

final categoryEntries =
    AsyncNotifierProviderFamily<EntriesNotifier, List<FeedEntry>, int>(
        () => EntriesNotifier());

final categoriesProvider = FutureProvider<List<FeedCategory>>((ref) async {
  final categories = (await ref.read(minifluxProvider).categories())
      .filter((c) => c.title != "All")
      .toList();
  categories.insert(0, FeedCategory.fromJson({"id": 0, "title": "Discover"}));
  return categories;
});

final categoryShouldScrollToTop =
    StateProvider.family<bool, int>((ref, category) {
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
