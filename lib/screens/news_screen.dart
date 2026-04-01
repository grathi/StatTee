import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';
import '../theme/app_theme.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<NewsArticle>> _future;

  @override
  void initState() {
    super.initState();
    _future = NewsService.fetchNews();
  }

  Future<void> _refresh() async {
    final fresh = NewsService.fetchNews(forceRefresh: true);
    setState(() => _future = fresh);
    await fresh;
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c  = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;
    final hPad = (sw * 0.05).clamp(16.0, 24.0);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.primaryText, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Golf News',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: c.primaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<NewsArticle>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildLoading(c, hPad);
          }
          final articles = snap.data ?? [];
          if (articles.isEmpty) {
            return _buildEmpty(c);
          }
          return RefreshIndicator(
            color: c.accent,
            onRefresh: _refresh,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 40),
              itemCount: articles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _NewsCard(
                article: articles[i],
                onTap: () => _open(articles[i].url),
                c: c,
                sw: sw,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading(AppColors c, double hPad) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 40),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => _shimmerCard(c),
    );
  }

  Widget _shimmerCard(AppColors c) {
    return Container(
      height: 100,
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(borderRadius: BorderRadius.circular(48), side: BorderSide(color: c.cardBorder)),
        shadows: c.cardShadow,
      ),
    );
  }

  Widget _buildEmpty(AppColors c) {
    return RefreshIndicator(
      color: c.accent,
      onRefresh: _refresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Column(
              children: [
                Icon(Icons.wifi_off_rounded, size: 48, color: c.tertiaryText),
                const SizedBox(height: 12),
                Text('No news available', style: TextStyle(color: c.secondaryText, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Pull down to try again', style: TextStyle(color: c.tertiaryText, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;
  final AppColors c;
  final double sw;

  const _NewsCard({
    required this.article,
    required this.onTap,
    required this.c,
    required this.sw,
  });

  @override
  Widget build(BuildContext context) {
    final imageSize = (sw * 0.18).clamp(64.0, 80.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: c.cardBg,
          shape: SuperellipseShape(borderRadius: BorderRadius.circular(48), side: BorderSide(color: c.cardBorder)),
          shadows: c.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (article.imageUrl != null)
              ClipPath(
                clipper: ShapeBorderClipper(
                  shape: SuperellipseShape(borderRadius: BorderRadius.circular(24)),
                ),
                child: Image.network(
                  article.imageUrl!,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(imageSize, c),
                ),
              )
            else
              _placeholder(imageSize, c),

            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source + time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.accentBg,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          article.sourceName,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: c.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _timeAgo(article.publishedAt),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: c.tertiaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Headline
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.primaryText,
                      height: 1.35,
                    ),
                  ),
                  if (article.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      article.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: c.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 4),
            Icon(Icons.open_in_new_rounded, size: 14, color: c.tertiaryText),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(double size, AppColors c) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: c.accentBg,
        shape: SuperellipseShape(borderRadius: BorderRadius.circular(24)),
      ),
      child: Icon(Icons.sports_golf_rounded, color: c.accent, size: size * 0.45),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    if (diff.inDays    < 7)   return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
