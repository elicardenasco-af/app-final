class PromoBanner {
  final int id;
  final String title;
  final String? subtitle;
  final String imageUrl;

  const PromoBanner({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) => PromoBanner(
        id: json['id'] as int,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        imageUrl: json['imageUrl'] as String,
      );
}
