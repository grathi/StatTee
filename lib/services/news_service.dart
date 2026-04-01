import 'package:dart_rss/dart_rss.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_article.dart';

class NewsService {
  static const _cacheKey     = 'golf_news_cache';
  static const _cacheTimeKey = 'golf_news_cache_time';
  static const _ttlMinutes   = 30;

  // Free RSS feeds — no API key, no rate limit
  static const _feeds = [
    ('BBC Golf', 'https://feeds.bbci.co.uk/sport/golf/rss.xml'),
  ];

  static Future<List<NewsArticle>> fetchNews({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // Serve from cache if fresh
    if (!forceRefresh) {
      final cachedTime = prefs.getInt(_cacheTimeKey);
      if (cachedTime != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cachedTime;
        if (age < _ttlMinutes * 60 * 1000) {
          final cached = prefs.getString(_cacheKey);
          if (cached != null && cached.isNotEmpty) {
            try {
              final articles = NewsArticle.listFromJsonString(cached);
              // Skip cache if no images (old cache before thumbnail fix)
              if (articles.any((a) => a.imageUrl != null)) return articles;
            } catch (_) {}
          }
        }
      }
    }

    // Fetch all feeds in parallel, ignore failures
    final results = await Future.wait(
      _feeds.map((feed) => _fetchFeed(feed.$1, feed.$2)),
    );

    final articles = results.expand((list) => list).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    // Dedupe by URL and title (removes podcast series duplicates)
    final seenUrls = <String>{};
    final seenTitles = <String>{};
    final deduped = articles
        .where((a) => seenUrls.add(a.url) && seenTitles.add(a.title))
        .take(30)
        .toList();

    // Cache result
    try {
      await prefs.setString(_cacheKey, NewsArticle.listToJsonString(deduped));
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}

    return deduped;
  }

  static Future<List<NewsArticle>> _fetchFeed(String sourceName, String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'TeeStats/1.5 Golf News Reader'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];

      final feed = RssFeed.parse(response.body);
      final articles = <NewsArticle>[];

      for (final item in feed.items) {
        final title = item.title?.trim();
        final link  = item.link?.trim();
        if (title == null || title.isEmpty || link == null || link.isEmpty) continue;

        final imageUrl = _extractImage(item);
        final publishedAt = _parseDate(item.pubDate) ?? DateTime.now();

        articles.add(NewsArticle(
          title:       title,
          description: _cleanHtml(item.description),
          url:         link,
          imageUrl:    imageUrl,
          sourceName:  sourceName,
          publishedAt: publishedAt,
        ));
      }

      return articles;
    } catch (_) {
      return [];
    }
  }

  /// Extract image from media:thumbnail, media:content, enclosure, or description img tag
  static String? _extractImage(RssItem item) {
    // media:thumbnail (BBC, most RSS feeds)
    if (item.media?.thumbnails.isNotEmpty == true) {
      final url = item.media!.thumbnails.first.url;
      if (url != null && url.isNotEmpty) return url;
    }
    // media:content
    if (item.media?.contents.isNotEmpty == true) {
      final url = item.media!.contents.first.url;
      if (url != null && url.isNotEmpty) return url;
    }
    // enclosure
    if (item.enclosure?.url != null) return item.enclosure!.url;
    // img src in description
    final desc = item.description ?? '';
    final match = RegExp(r'''<img[^>]+src=["']([^"']+)["']''').firstMatch(desc);
    if (match != null) return match.group(1);
    return null;
  }

  static String? _cleanHtml(String? html) {
    if (html == null) return null;
    return html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .let((s) => s.isEmpty ? null : s);
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    try { return DateTime.parse(raw); } catch (_) {}
    try { return _parseRfc2822(raw); } catch (_) {}
    return null;
  }

  static DateTime _parseRfc2822(String s) {
    // e.g. "Mon, 30 Mar 2026 12:00:00 +0000"
    final months = {
      'Jan':1,'Feb':2,'Mar':3,'Apr':4,'May':5,'Jun':6,
      'Jul':7,'Aug':8,'Sep':9,'Oct':10,'Nov':11,'Dec':12
    };
    final re = RegExp(
        r'\w+,\s+(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+([+-]\d{4}|GMT|UTC)');
    final m = re.firstMatch(s);
    if (m == null) throw FormatException('bad date');
    final day    = int.parse(m.group(1)!);
    final month  = months[m.group(2)]!;
    final year   = int.parse(m.group(3)!);
    final hour   = int.parse(m.group(4)!);
    final minute = int.parse(m.group(5)!);
    final second = int.parse(m.group(6)!);
    final tzStr  = m.group(7)!;
    Duration offset = Duration.zero;
    if (tzStr.length == 5) {
      final sign = tzStr[0] == '+' ? 1 : -1;
      final h = int.parse(tzStr.substring(1, 3));
      final min = int.parse(tzStr.substring(3, 5));
      offset = Duration(hours: h, minutes: min) * sign;
    }
    return DateTime.utc(year, month, day, hour, minute, second).subtract(offset);
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}
