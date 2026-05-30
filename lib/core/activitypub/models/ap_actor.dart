import 'package:nightingale/core/activitypub/ap_context.dart';
import 'package:nightingale/core/activitypub/models/ap_public_key.dart';

class ApActor {
  const ApActor({
    required this.id,
    required this.type,
    required this.inbox,
    required this.outbox,
    required this.followers,
    required this.following,
    required this.preferredUsername,
    required this.name,
    required this.publicKey,
    this.summary,
    this.icon,
    this.url,
    this.manuallyApprovesFollowers,
    this.publishedAt,
  });

  final String id;
  final String type;
  final String inbox;
  final String outbox;
  final String followers;
  final String following;
  final String preferredUsername;
  final String name;
  final ApPublicKey publicKey;
  final String? summary;
  final String? icon;
  final String? url;
  // true if the account manually approves followers (private account)
  final bool? manuallyApprovesFollowers;
  final DateTime? publishedAt;

  factory ApActor.fromJson(Map<String, dynamic> json) => ApActor(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'Person',
        inbox: json['inbox'] as String,
        outbox: json['outbox'] as String,
        followers: json['followers'] as String,
        following: json['following'] as String,
        preferredUsername: json['preferredUsername'] as String,
        name: json['name'] as String? ?? '',
        publicKey: ApPublicKey.fromJson(
          json['publicKey'] as Map<String, dynamic>,
        ),
        summary: json['summary'] as String?,
        icon: json['icon'] is Map
            ? (json['icon'] as Map)['url'] as String?
            : json['icon'] as String?,
        url: json['url'] as String?,
        manuallyApprovesFollowers:
            json['manuallyApprovesFollowers'] as bool?,
        publishedAt: json['published'] is String
            ? DateTime.tryParse(json['published'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        '@context': kDefaultApContext,
        'id': id,
        'type': type,
        'inbox': inbox,
        'outbox': outbox,
        'followers': followers,
        'following': following,
        'preferredUsername': preferredUsername,
        'name': name,
        'publicKey': publicKey.toJson(),
        if (summary != null) 'summary': summary,
        if (icon != null) 'icon': {'type': 'Image', 'url': icon},
        if (url != null) 'url': url,
        if (manuallyApprovesFollowers != null)
          'manuallyApprovesFollowers': manuallyApprovesFollowers,
        if (publishedAt != null) 'published': publishedAt!.toIso8601String(),
      };
}
