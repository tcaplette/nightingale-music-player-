import 'package:nightingale/core/activitypub/ap_context.dart';

sealed class ApActivity {
  const ApActivity({
    required this.id,
    required this.type,
    required this.actor,
    this.object,
    this.target,
    this.to,
    this.cc,
    this.published,
  });

  final String id;
  final String type;
  final String actor;
  final dynamic object;
  final String? target;
  final List<String>? to;
  final List<String>? cc;
  final DateTime? published;

  static ApActivity fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'Create' => ApCreate.fromJson(json),
      'Update' => ApUpdate.fromJson(json),
      'Delete' => ApDelete.fromJson(json),
      'Follow' => ApFollow.fromJson(json),
      'Accept' => ApAccept.fromJson(json),
      'Reject' => ApReject.fromJson(json),
      'Undo' => ApUndo.fromJson(json),
      'Like' => ApLike.fromJson(json),
      'Announce' => ApAnnounce.fromJson(json),
      'Block' => ApBlock.fromJson(json),
      'Move' => ApMove.fromJson(json),
      'Listen' => ApListen.fromJson(json),
      _ => throw UnrecognizedActivityTypeException(type ?? 'null'),
    };
  }

  Map<String, dynamic> toJson();

  Map<String, dynamic> _baseJson() => {
        '@context': kDefaultApContext,
        'id': id,
        'type': type,
        'actor': actor,
        if (object != null) 'object': object,
        if (target != null) 'target': target,
        if (to != null) 'to': to,
        if (cc != null) 'cc': cc,
        if (published != null) 'published': published!.toUtc().toIso8601String(),
      };
}

class UnrecognizedActivityTypeException implements Exception {
  const UnrecognizedActivityTypeException(this.type);
  final String type;
  @override
  String toString() => 'UnrecognizedActivityTypeException: $type';
}

List<String>? _toList(dynamic v) {
  if (v == null) return null;
  if (v is List) return v.cast<String>();
  if (v is String) return [v];
  return null;
}

DateTime? _parseDate(dynamic v) =>
    v is String ? DateTime.tryParse(v) : null;

class ApCreate extends ApActivity {
  const ApCreate({
    required super.id,
    required super.actor,
    super.object,
    super.to,
    super.cc,
    super.published,
  }) : super(type: 'Create');

  factory ApCreate.fromJson(Map<String, dynamic> j) => ApCreate(
        id: j['id'] as String,
        actor: j['actor'] as String,
        object: j['object'],
        to: _toList(j['to']),
        cc: _toList(j['cc']),
        published: _parseDate(j['published']),
      );

  @override
  Map<String, dynamic> toJson() => _baseJson();
}

class ApUpdate extends ApActivity {
  const ApUpdate({
    required super.id,
    required super.actor,
    super.object,
    super.to,
    super.cc,
    super.published,
  }) : super(type: 'Update');

  factory ApUpdate.fromJson(Map<String, dynamic> j) => ApUpdate(
        id: j['id'] as String,
        actor: j['actor'] as String,
        object: j['object'],
        to: _toList(j['to']),
        cc: _toList(j['cc']),
        published: _parseDate(j['published']),
      );

  @override
  Map<String, dynamic> toJson() => _baseJson();
}

class ApDelete extends ApActivity {
  const ApDelete({
    required super.id,
    required super.actor,
    super.object,
    super.to,
    super.cc,
    super.published,
  }) : super(type: 'Delete');

  factory ApDelete.fromJson(Map<String, dynamic> j) => ApDelete(
        id: j['id'] as String,
        actor: j['actor'] as String,
        object: j['object'],
        to: _toList(j['to']),
        cc: _toList(j['cc']),
        published: _parseDate(j['published']),
      );

  @override
  Map<String, dynamic> toJson() => _baseJson();
}

class ApFollow extends ApActivity {
  const ApFollow({
    required super.id,
    required super.actor,
    super.object,
    super.to,
    super.cc,
    super.published,
  }) : super(type: 'Follow');

  factory ApFollow.fromJson(Map<String, dynamic> j) => ApFollow(
        id: j['id'] as String,
        actor: j['actor'] as String,
        object: j['object'],
        to: _toList(j['to']),
        cc: _toList(j['cc']),
        published: _parseDate(j['published']),
      );

  @override
  Map<String, dynamic> toJson() => _baseJson();
}

class ApListen extends ApActivity {
  const ApListen({
    required super.id,
    required super.actor,
    super.object,
    super.to,
    super.cc,
    super.published,
  }) : super(type: 'Listen');

  factory ApListen.fromJson(Map<String, dynamic> j) => ApListen(
        id: j['id'] as String,
        actor: j['actor'] as String,
        object: j['object'],
        to: _toList(j['to']),
        cc: _toList(j['cc']),
        published: _parseDate(j['published']),
      );

  @override
  Map<String, dynamic> toJson() => _baseJson();
}

class ApAccept extends ApActivity {
  const ApAccept({
    required super.id,
    required super.actor,
    super.object,
    super.to,
    super.cc,
    super.published,
  }) : super(type: 'Accept');

  factory ApAccept.fromJson(Map<String, dynamic> j) => ApAccept(
        id: j['id'] as String,
        actor: j['actor'] as String,
        object: j['object'],
        to: _toList(j['to']),
        cc: _toList(j['cc']),
        published: _parseDate(j['published']),
      );

  @override
  Map<String, dynamic> toJson() => _baseJson();
}

class ApReject extends ApActivity {
  const ApReject({
    required super.id,
    required super.actor,
    super.object,
    super.to,
    super.cc,
    super.published,
  }) : super(type: 'Reject');

  factory ApReject.fromJson(Map<String, dynamic> j) => ApReject(
        id: j['id'] as String,
        actor: j['actor'] as String,
        object: j['object'],
        to: _toList(j['to']),
        cc: _toList(j['cc']),
        published: _parseDate(j['published']),
      );

  @override
  Map<String, dynamic> toJson() => _baseJson();
}

class ApUndo extends ApActivity {
  const ApUndo({
    required super.id,
    required super.actor,
    super.object,
    super.to,
    super.cc,
    super.published,
  }) : super(type: 'Undo');

  factory ApUndo.fromJson(Map<String, dynamic> j) => ApUndo(
        id: j['id'] as String,
        actor: j['actor'] as String,
        object: j['object'],
        to: _toList(j['to']),
        cc: _toList(j['cc']),
        published: _parseDate(j['published']),
      );

  @override
  Map<String, dynamic> toJson() => _baseJson();
}

class ApLike extends ApActivity {
  const ApLike({
    required super.id,
    required super.actor,
    super.object,
    super.to,
    super.cc,
    super.published,
  }) : super(type: 'Like');

  factory ApLike.fromJson(Map<String, dynamic> j) => ApLike(
        id: j['id'] as String,
        actor: j['actor'] as String,
        object: j['object'],
        to: _toList(j['to']),
        cc: _toList(j['cc']),
        published: _parseDate(j['published']),
      );

  @override
  Map<String, dynamic> toJson() => _baseJson();
}

class ApAnnounce extends ApActivity {
  const ApAnnounce({
    required super.id,
    required super.actor,
    super.object,
    super.to,
    super.cc,
    super.published,
  }) : super(type: 'Announce');

  factory ApAnnounce.fromJson(Map<String, dynamic> j) => ApAnnounce(
        id: j['id'] as String,
        actor: j['actor'] as String,
        object: j['object'],
        to: _toList(j['to']),
        cc: _toList(j['cc']),
        published: _parseDate(j['published']),
      );

  @override
  Map<String, dynamic> toJson() => _baseJson();
}

class ApBlock extends ApActivity {
  const ApBlock({
    required super.id,
    required super.actor,
    super.object,
    super.to,
    super.cc,
    super.published,
  }) : super(type: 'Block');

  factory ApBlock.fromJson(Map<String, dynamic> j) => ApBlock(
        id: j['id'] as String,
        actor: j['actor'] as String,
        object: j['object'],
        to: _toList(j['to']),
        cc: _toList(j['cc']),
        published: _parseDate(j['published']),
      );

  @override
  Map<String, dynamic> toJson() => _baseJson();
}

class ApMove extends ApActivity {
  const ApMove({
    required super.id,
    required super.actor,
    super.object,
    super.target,
    super.to,
    super.cc,
    super.published,
  }) : super(type: 'Move');

  factory ApMove.fromJson(Map<String, dynamic> j) => ApMove(
        id: j['id'] as String,
        actor: j['actor'] as String,
        object: j['object'],
        target: j['target'] as String?,
        to: _toList(j['to']),
        cc: _toList(j['cc']),
        published: _parseDate(j['published']),
      );

  @override
  Map<String, dynamic> toJson() => _baseJson();
}
