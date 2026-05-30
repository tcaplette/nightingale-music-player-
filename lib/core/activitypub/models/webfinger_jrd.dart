class WebFingerLink {
  const WebFingerLink({
    required this.rel,
    this.type,
    this.href,
  });

  final String rel;
  final String? type;
  final String? href;

  factory WebFingerLink.fromJson(Map<String, dynamic> json) => WebFingerLink(
        rel: json['rel'] as String,
        type: json['type'] as String?,
        href: json['href'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'rel': rel,
        if (type != null) 'type': type,
        if (href != null) 'href': href,
      };
}

class WebFingerJrd {
  const WebFingerJrd({
    required this.subject,
    this.aliases,
    required this.links,
  });

  final String subject;
  final List<String>? aliases;
  final List<WebFingerLink> links;

  factory WebFingerJrd.fromJson(Map<String, dynamic> json) => WebFingerJrd(
        subject: json['subject'] as String,
        aliases: (json['aliases'] as List?)?.cast<String>(),
        links: (json['links'] as List? ?? [])
            .map((l) => WebFingerLink.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'subject': subject,
        if (aliases != null) 'aliases': aliases,
        'links': links.map((l) => l.toJson()).toList(),
      };

  String? get selfHref => links
      .where((l) => l.rel == 'self')
      .map((l) => l.href)
      .firstOrNull;
}
