import 'dart:convert';

class NewsArticle {
  final String title;
  final String? description;
  final String url;
  final String? imageUrl;
  final String sourceName;
  final DateTime publishedAt;

  const NewsArticle({
    required this.title,
    this.description,
    required this.url,
    this.imageUrl,
    required this.sourceName,
    required this.publishedAt,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'url': url,
        'imageUrl': imageUrl,
        'sourceName': sourceName,
        'publishedAt': publishedAt.toIso8601String(),
      };

  factory NewsArticle.fromJson(Map<String, dynamic> j) => NewsArticle(
        title: j['title'] as String,
        description: j['description'] as String?,
        url: j['url'] as String,
        imageUrl: j['imageUrl'] as String?,
        sourceName: j['sourceName'] as String,
        publishedAt: DateTime.parse(j['publishedAt'] as String),
      );

  static List<NewsArticle> listFromJsonString(String s) =>
      (jsonDecode(s) as List).map((e) => NewsArticle.fromJson(e as Map<String, dynamic>)).toList();

  static String listToJsonString(List<NewsArticle> articles) =>
      jsonEncode(articles.map((a) => a.toJson()).toList());
}
