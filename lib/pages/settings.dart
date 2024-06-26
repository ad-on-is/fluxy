import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluxy/data/entities.dart';
import 'package:fluxy/data/entries.dart';
import 'package:fluxy/data/storage.dart';
import 'package:fluxy/ui/login_form.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Settings extends HookConsumerWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();

    return PageView(
      controller: pageController,
      children: [
        Overview(
          onTap: () {
            pageController.animateTo(MediaQuery.of(context).size.width,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubicEmphasized);
          },
        ),
        const LoginForm()
      ],
    );
  }
}

class Overview extends HookConsumerWidget {
  final Function? onTap;
  const Overview({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User? user;
    Version? version;
    final markAsReadOnScroll = useState(true);
    final fetchReadNews = useState(false);
    final hideReadNews = useState(true);
    final infiniteScroll = useState(true);
    final init = useState(false);

    saveSettings() {
      ref.read(configProvider.notifier).saveConfig(Config(
          markAsReadOnScroll.value,
          fetchReadNews.value,
          hideReadNews.value,
          infiniteScroll.value));
    }

    markAsReadOnScroll.addListener(() {
      saveSettings();
    });

    fetchReadNews.addListener(() {
      saveSettings();
    });

    hideReadNews.addListener(() {
      saveSettings();
    });

    infiniteScroll.addListener(() {
      saveSettings();
    });

    ref.watch(configProvider).whenData((v) {
      if (!init.value) {
        markAsReadOnScroll.value = v.markAsReadOnScroll;
        fetchReadNews.value = v.fetchReadNews;
        hideReadNews.value = v.hideReadNews;
        infiniteScroll.value = v.infiniteScroll;
        init.value = true;
      }
    });
    ref.watch(userProvider).whenData((v) => user = v);
    ref.watch(versionProvider).whenData((v) => version = v);
    return ListView(
      children: [
        user != null && version != null
            ? ListTile(
                title: Text(user!.username),
                subtitle: Opacity(
                  opacity: 0.5,
                  child: Text(
                      "Miniflux version ${version!.version} - ${version!.buildDate}",
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                trailing: const Icon(Icons.arrow_right),
                onTap: () => {
                  if (onTap != null) {onTap!()}
                },
              )
            : const ListTile(
                title: Text("Loading user info"),
                subtitle: Text("Loading version info..."),
              ),
        ListTile(
          title: const Text("Mark seen entries as read"),
          trailing: Switch(
            value: markAsReadOnScroll.value,
            onChanged: (v) {
              markAsReadOnScroll.value = v;
            },
          ),
          onTap: () => markAsReadOnScroll.value = !markAsReadOnScroll.value,
        ),
        ListTile(
          title: const Text("Fetch read news"),
          trailing: Switch(
            value: fetchReadNews.value,
            onChanged: (v) {
              fetchReadNews.value = v;
            },
          ),
          onTap: () => fetchReadNews.value = !fetchReadNews.value,
        ),
        ListTile(
          title: const Text("Auto-hide read news from UI"),
          trailing: Switch(
            value: hideReadNews.value,
            onChanged: (v) {
              hideReadNews.value = v;
            },
          ),
          onTap: () => hideReadNews.value = !hideReadNews.value,
        ),
        ListTile(
          title: const Text("Infinite scroll"),
          trailing: Switch(
            value: infiniteScroll.value,
            onChanged: (v) {
              infiniteScroll.value = v;
            },
          ),
          onTap: () => infiniteScroll.value = !infiniteScroll.value,
        ),
      ],
    );
  }
}
