class FeedIcon {
  final int iconId;
  FeedIcon.fromJson(Map<String, dynamic> json) : iconId = json['icon_id'];
}

class User {
  final int id;
  final String username;

  User(this.id, this.username);

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        username = json['username'];
}

class Version {
  final String version;
  final String buildDate;

  Version(this.version, this.buildDate);

  Version.fromJson(Map<String, dynamic> json)
      : version = json['version'],
        buildDate = json['build_date'];
}

class Feed {
  final String title;
  final int id;
  final String siteUrl;
  final FeedIcon? icon;
  final FeedCategory category;
  Feed.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        id = json['id'],
        siteUrl = json['site_url'],
        category = FeedCategory.fromJson(json['category']),
        icon = FeedIcon.fromJson(json['icon']);
}

class FeedCategory {
  final int id;
  final String title;
  FeedCategory.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'];
}

class FeedEntryEnclosure {
  final String url;
  final String mimeType;

  FeedEntryEnclosure.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        mimeType = json['mime_type'];
}

class FeedEntry {
  final int id;
  final String title;
  final String content;
  final Feed feed;
  final String url;
  final DateTime publishedAt;
  final List<FeedEntryEnclosure> enclosures;

  String getImage() {
    for (var enclosure in enclosures) {
      if (enclosure.mimeType.startsWith('image')) {
        return enclosure.url;
      }
    }
    final contentImage = content.contains('<img')
        ? RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(content)?.group(1)
        : "";

    return contentImage ?? "";
  }

  FeedEntry.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        id = json['id'],
        feed = Feed.fromJson(json['feed']),
        publishedAt = DateTime.parse(json['published_at']),
        url = json['url'],
        enclosures = List.from(json['enclosures'])
            .map((e) => FeedEntryEnclosure.fromJson(e))
            .toList(),
        content = json['content'];
}
