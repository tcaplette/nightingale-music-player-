import 'package:nightingale/core/activitypub/ap_context.dart';

class ApOrderedCollection {
  const ApOrderedCollection({
    required this.id,
    required this.totalItems,
    this.first,
    this.orderedItems,
  });

  final String id;
  final int totalItems;
  // For paginated collections (outbox, followers, etc.)
  final String? first;
  // For inline collections (playlists served as a single response)
  final List<dynamic>? orderedItems;

  factory ApOrderedCollection.fromJson(Map<String, dynamic> json) =>
      ApOrderedCollection(
        id: json['id'] as String,
        totalItems: json['totalItems'] as int? ?? 0,
        first: json['first'] as String?,
        orderedItems: json['orderedItems'] as List<dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        '@context': kDefaultApContext,
        'id': id,
        'type': 'OrderedCollection',
        'totalItems': totalItems,
        if (first != null) 'first': first,
        if (orderedItems != null) 'orderedItems': orderedItems,
      };
}

class ApOrderedCollectionPage {
  const ApOrderedCollectionPage({
    required this.id,
    required this.partOf,
    required this.orderedItems,
    this.next,
    this.prev,
  });

  final String id;
  final String partOf;
  final List<dynamic> orderedItems;
  final String? next;
  final String? prev;

  factory ApOrderedCollectionPage.fromJson(Map<String, dynamic> json) =>
      ApOrderedCollectionPage(
        id: json['id'] as String,
        partOf: json['partOf'] as String,
        orderedItems: (json['orderedItems'] as List?)?.cast<dynamic>() ?? [],
        next: json['next'] as String?,
        prev: json['prev'] as String?,
      );

  Map<String, dynamic> toJson() => {
        '@context': kDefaultApContext,
        'id': id,
        'type': 'OrderedCollectionPage',
        'partOf': partOf,
        'orderedItems': orderedItems,
        if (next != null) 'next': next,
        if (prev != null) 'prev': prev,
      };
}
