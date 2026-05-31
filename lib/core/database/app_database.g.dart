// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AlbumsTableTable extends AlbumsTable
    with TableInfo<$AlbumsTableTable, AlbumsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Unknown Artist'),
  );
  static const VerificationMeta _artworkPathMeta = const VerificationMeta(
    'artworkPath',
  );
  @override
  late final GeneratedColumn<String> artworkPath = GeneratedColumn<String>(
    'artwork_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseYearMeta = const VerificationMeta(
    'releaseYear',
  );
  @override
  late final GeneratedColumn<int> releaseYear = GeneratedColumn<int>(
    'release_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackCountMeta = const VerificationMeta(
    'trackCount',
  );
  @override
  late final GeneratedColumn<int> trackCount = GeneratedColumn<int>(
    'track_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    artist,
    artworkPath,
    releaseYear,
    trackCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'albums';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlbumsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('artwork_path')) {
      context.handle(
        _artworkPathMeta,
        artworkPath.isAcceptableOrUnknown(
          data['artwork_path']!,
          _artworkPathMeta,
        ),
      );
    }
    if (data.containsKey('release_year')) {
      context.handle(
        _releaseYearMeta,
        releaseYear.isAcceptableOrUnknown(
          data['release_year']!,
          _releaseYearMeta,
        ),
      );
    }
    if (data.containsKey('track_count')) {
      context.handle(
        _trackCountMeta,
        trackCount.isAcceptableOrUnknown(data['track_count']!, _trackCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlbumsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlbumsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      artworkPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_path'],
      ),
      releaseYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}release_year'],
      ),
      trackCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_count'],
      )!,
    );
  }

  @override
  $AlbumsTableTable createAlias(String alias) {
    return $AlbumsTableTable(attachedDatabase, alias);
  }
}

class AlbumsTableData extends DataClass implements Insertable<AlbumsTableData> {
  final int id;
  final String name;
  final String artist;
  final String? artworkPath;
  final int? releaseYear;
  final int trackCount;
  const AlbumsTableData({
    required this.id,
    required this.name,
    required this.artist,
    this.artworkPath,
    this.releaseYear,
    required this.trackCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['artist'] = Variable<String>(artist);
    if (!nullToAbsent || artworkPath != null) {
      map['artwork_path'] = Variable<String>(artworkPath);
    }
    if (!nullToAbsent || releaseYear != null) {
      map['release_year'] = Variable<int>(releaseYear);
    }
    map['track_count'] = Variable<int>(trackCount);
    return map;
  }

  AlbumsTableCompanion toCompanion(bool nullToAbsent) {
    return AlbumsTableCompanion(
      id: Value(id),
      name: Value(name),
      artist: Value(artist),
      artworkPath: artworkPath == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkPath),
      releaseYear: releaseYear == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseYear),
      trackCount: Value(trackCount),
    );
  }

  factory AlbumsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlbumsTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      artist: serializer.fromJson<String>(json['artist']),
      artworkPath: serializer.fromJson<String?>(json['artworkPath']),
      releaseYear: serializer.fromJson<int?>(json['releaseYear']),
      trackCount: serializer.fromJson<int>(json['trackCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'artist': serializer.toJson<String>(artist),
      'artworkPath': serializer.toJson<String?>(artworkPath),
      'releaseYear': serializer.toJson<int?>(releaseYear),
      'trackCount': serializer.toJson<int>(trackCount),
    };
  }

  AlbumsTableData copyWith({
    int? id,
    String? name,
    String? artist,
    Value<String?> artworkPath = const Value.absent(),
    Value<int?> releaseYear = const Value.absent(),
    int? trackCount,
  }) => AlbumsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    artist: artist ?? this.artist,
    artworkPath: artworkPath.present ? artworkPath.value : this.artworkPath,
    releaseYear: releaseYear.present ? releaseYear.value : this.releaseYear,
    trackCount: trackCount ?? this.trackCount,
  );
  AlbumsTableData copyWithCompanion(AlbumsTableCompanion data) {
    return AlbumsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      artist: data.artist.present ? data.artist.value : this.artist,
      artworkPath: data.artworkPath.present
          ? data.artworkPath.value
          : this.artworkPath,
      releaseYear: data.releaseYear.present
          ? data.releaseYear.value
          : this.releaseYear,
      trackCount: data.trackCount.present
          ? data.trackCount.value
          : this.trackCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlbumsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('artist: $artist, ')
          ..write('artworkPath: $artworkPath, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('trackCount: $trackCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, artist, artworkPath, releaseYear, trackCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlbumsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.artist == this.artist &&
          other.artworkPath == this.artworkPath &&
          other.releaseYear == this.releaseYear &&
          other.trackCount == this.trackCount);
}

class AlbumsTableCompanion extends UpdateCompanion<AlbumsTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> artist;
  final Value<String?> artworkPath;
  final Value<int?> releaseYear;
  final Value<int> trackCount;
  const AlbumsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.artist = const Value.absent(),
    this.artworkPath = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.trackCount = const Value.absent(),
  });
  AlbumsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.artist = const Value.absent(),
    this.artworkPath = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.trackCount = const Value.absent(),
  }) : name = Value(name);
  static Insertable<AlbumsTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? artist,
    Expression<String>? artworkPath,
    Expression<int>? releaseYear,
    Expression<int>? trackCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (artist != null) 'artist': artist,
      if (artworkPath != null) 'artwork_path': artworkPath,
      if (releaseYear != null) 'release_year': releaseYear,
      if (trackCount != null) 'track_count': trackCount,
    });
  }

  AlbumsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? artist,
    Value<String?>? artworkPath,
    Value<int?>? releaseYear,
    Value<int>? trackCount,
  }) {
    return AlbumsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      artworkPath: artworkPath ?? this.artworkPath,
      releaseYear: releaseYear ?? this.releaseYear,
      trackCount: trackCount ?? this.trackCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (artworkPath.present) {
      map['artwork_path'] = Variable<String>(artworkPath.value);
    }
    if (releaseYear.present) {
      map['release_year'] = Variable<int>(releaseYear.value);
    }
    if (trackCount.present) {
      map['track_count'] = Variable<int>(trackCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('artist: $artist, ')
          ..write('artworkPath: $artworkPath, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('trackCount: $trackCount')
          ..write(')'))
        .toString();
  }
}

class $TracksTableTable extends TracksTable
    with TableInfo<$TracksTableTable, TracksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Unknown Artist'),
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<int> albumId = GeneratedColumn<int>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES albums (id)',
    ),
  );
  static const VerificationMeta _albumArtistMeta = const VerificationMeta(
    'albumArtist',
  );
  @override
  late final GeneratedColumn<String> albumArtist = GeneratedColumn<String>(
    'album_artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackNumberMeta = const VerificationMeta(
    'trackNumber',
  );
  @override
  late final GeneratedColumn<int> trackNumber = GeneratedColumn<int>(
    'track_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discNumberMeta = const VerificationMeta(
    'discNumber',
  );
  @override
  late final GeneratedColumn<int> discNumber = GeneratedColumn<int>(
    'disc_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseYearMeta = const VerificationMeta(
    'releaseYear',
  );
  @override
  late final GeneratedColumn<int> releaseYear = GeneratedColumn<int>(
    'release_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _artworkPathMeta = const VerificationMeta(
    'artworkPath',
  );
  @override
  late final GeneratedColumn<String> artworkPath = GeneratedColumn<String>(
    'artwork_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filePath,
    title,
    artist,
    albumId,
    albumArtist,
    trackNumber,
    discNumber,
    genre,
    releaseYear,
    durationMs,
    artworkPath,
    dateAdded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TracksTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('album_artist')) {
      context.handle(
        _albumArtistMeta,
        albumArtist.isAcceptableOrUnknown(
          data['album_artist']!,
          _albumArtistMeta,
        ),
      );
    }
    if (data.containsKey('track_number')) {
      context.handle(
        _trackNumberMeta,
        trackNumber.isAcceptableOrUnknown(
          data['track_number']!,
          _trackNumberMeta,
        ),
      );
    }
    if (data.containsKey('disc_number')) {
      context.handle(
        _discNumberMeta,
        discNumber.isAcceptableOrUnknown(data['disc_number']!, _discNumberMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('release_year')) {
      context.handle(
        _releaseYearMeta,
        releaseYear.isAcceptableOrUnknown(
          data['release_year']!,
          _releaseYearMeta,
        ),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('artwork_path')) {
      context.handle(
        _artworkPathMeta,
        artworkPath.isAcceptableOrUnknown(
          data['artwork_path']!,
          _artworkPathMeta,
        ),
      );
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TracksTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TracksTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_id'],
      ),
      albumArtist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_artist'],
      ),
      trackNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_number'],
      ),
      discNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disc_number'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      releaseYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}release_year'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      artworkPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_path'],
      ),
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added'],
      )!,
    );
  }

  @override
  $TracksTableTable createAlias(String alias) {
    return $TracksTableTable(attachedDatabase, alias);
  }
}

class TracksTableData extends DataClass implements Insertable<TracksTableData> {
  final int id;
  final String filePath;
  final String title;
  final String artist;
  final int? albumId;
  final String? albumArtist;
  final int? trackNumber;
  final int? discNumber;
  final String? genre;
  final int? releaseYear;
  final int durationMs;
  final String? artworkPath;
  final DateTime dateAdded;
  const TracksTableData({
    required this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    this.albumId,
    this.albumArtist,
    this.trackNumber,
    this.discNumber,
    this.genre,
    this.releaseYear,
    required this.durationMs,
    this.artworkPath,
    required this.dateAdded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_path'] = Variable<String>(filePath);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<int>(albumId);
    }
    if (!nullToAbsent || albumArtist != null) {
      map['album_artist'] = Variable<String>(albumArtist);
    }
    if (!nullToAbsent || trackNumber != null) {
      map['track_number'] = Variable<int>(trackNumber);
    }
    if (!nullToAbsent || discNumber != null) {
      map['disc_number'] = Variable<int>(discNumber);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || releaseYear != null) {
      map['release_year'] = Variable<int>(releaseYear);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || artworkPath != null) {
      map['artwork_path'] = Variable<String>(artworkPath);
    }
    map['date_added'] = Variable<DateTime>(dateAdded);
    return map;
  }

  TracksTableCompanion toCompanion(bool nullToAbsent) {
    return TracksTableCompanion(
      id: Value(id),
      filePath: Value(filePath),
      title: Value(title),
      artist: Value(artist),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      albumArtist: albumArtist == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtist),
      trackNumber: trackNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNumber),
      discNumber: discNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(discNumber),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      releaseYear: releaseYear == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseYear),
      durationMs: Value(durationMs),
      artworkPath: artworkPath == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkPath),
      dateAdded: Value(dateAdded),
    );
  }

  factory TracksTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TracksTableData(
      id: serializer.fromJson<int>(json['id']),
      filePath: serializer.fromJson<String>(json['filePath']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      albumId: serializer.fromJson<int?>(json['albumId']),
      albumArtist: serializer.fromJson<String?>(json['albumArtist']),
      trackNumber: serializer.fromJson<int?>(json['trackNumber']),
      discNumber: serializer.fromJson<int?>(json['discNumber']),
      genre: serializer.fromJson<String?>(json['genre']),
      releaseYear: serializer.fromJson<int?>(json['releaseYear']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      artworkPath: serializer.fromJson<String?>(json['artworkPath']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'filePath': serializer.toJson<String>(filePath),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'albumId': serializer.toJson<int?>(albumId),
      'albumArtist': serializer.toJson<String?>(albumArtist),
      'trackNumber': serializer.toJson<int?>(trackNumber),
      'discNumber': serializer.toJson<int?>(discNumber),
      'genre': serializer.toJson<String?>(genre),
      'releaseYear': serializer.toJson<int?>(releaseYear),
      'durationMs': serializer.toJson<int>(durationMs),
      'artworkPath': serializer.toJson<String?>(artworkPath),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
    };
  }

  TracksTableData copyWith({
    int? id,
    String? filePath,
    String? title,
    String? artist,
    Value<int?> albumId = const Value.absent(),
    Value<String?> albumArtist = const Value.absent(),
    Value<int?> trackNumber = const Value.absent(),
    Value<int?> discNumber = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<int?> releaseYear = const Value.absent(),
    int? durationMs,
    Value<String?> artworkPath = const Value.absent(),
    DateTime? dateAdded,
  }) => TracksTableData(
    id: id ?? this.id,
    filePath: filePath ?? this.filePath,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    albumId: albumId.present ? albumId.value : this.albumId,
    albumArtist: albumArtist.present ? albumArtist.value : this.albumArtist,
    trackNumber: trackNumber.present ? trackNumber.value : this.trackNumber,
    discNumber: discNumber.present ? discNumber.value : this.discNumber,
    genre: genre.present ? genre.value : this.genre,
    releaseYear: releaseYear.present ? releaseYear.value : this.releaseYear,
    durationMs: durationMs ?? this.durationMs,
    artworkPath: artworkPath.present ? artworkPath.value : this.artworkPath,
    dateAdded: dateAdded ?? this.dateAdded,
  );
  TracksTableData copyWithCompanion(TracksTableCompanion data) {
    return TracksTableData(
      id: data.id.present ? data.id.value : this.id,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      albumArtist: data.albumArtist.present
          ? data.albumArtist.value
          : this.albumArtist,
      trackNumber: data.trackNumber.present
          ? data.trackNumber.value
          : this.trackNumber,
      discNumber: data.discNumber.present
          ? data.discNumber.value
          : this.discNumber,
      genre: data.genre.present ? data.genre.value : this.genre,
      releaseYear: data.releaseYear.present
          ? data.releaseYear.value
          : this.releaseYear,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      artworkPath: data.artworkPath.present
          ? data.artworkPath.value
          : this.artworkPath,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TracksTableData(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('albumId: $albumId, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('genre: $genre, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('durationMs: $durationMs, ')
          ..write('artworkPath: $artworkPath, ')
          ..write('dateAdded: $dateAdded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filePath,
    title,
    artist,
    albumId,
    albumArtist,
    trackNumber,
    discNumber,
    genre,
    releaseYear,
    durationMs,
    artworkPath,
    dateAdded,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TracksTableData &&
          other.id == this.id &&
          other.filePath == this.filePath &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.albumId == this.albumId &&
          other.albumArtist == this.albumArtist &&
          other.trackNumber == this.trackNumber &&
          other.discNumber == this.discNumber &&
          other.genre == this.genre &&
          other.releaseYear == this.releaseYear &&
          other.durationMs == this.durationMs &&
          other.artworkPath == this.artworkPath &&
          other.dateAdded == this.dateAdded);
}

class TracksTableCompanion extends UpdateCompanion<TracksTableData> {
  final Value<int> id;
  final Value<String> filePath;
  final Value<String> title;
  final Value<String> artist;
  final Value<int?> albumId;
  final Value<String?> albumArtist;
  final Value<int?> trackNumber;
  final Value<int?> discNumber;
  final Value<String?> genre;
  final Value<int?> releaseYear;
  final Value<int> durationMs;
  final Value<String?> artworkPath;
  final Value<DateTime> dateAdded;
  const TracksTableCompanion({
    this.id = const Value.absent(),
    this.filePath = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.albumId = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.genre = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.artworkPath = const Value.absent(),
    this.dateAdded = const Value.absent(),
  });
  TracksTableCompanion.insert({
    this.id = const Value.absent(),
    required String filePath,
    required String title,
    this.artist = const Value.absent(),
    this.albumId = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.genre = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.artworkPath = const Value.absent(),
    this.dateAdded = const Value.absent(),
  }) : filePath = Value(filePath),
       title = Value(title);
  static Insertable<TracksTableData> custom({
    Expression<int>? id,
    Expression<String>? filePath,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<int>? albumId,
    Expression<String>? albumArtist,
    Expression<int>? trackNumber,
    Expression<int>? discNumber,
    Expression<String>? genre,
    Expression<int>? releaseYear,
    Expression<int>? durationMs,
    Expression<String>? artworkPath,
    Expression<DateTime>? dateAdded,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filePath != null) 'file_path': filePath,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (albumId != null) 'album_id': albumId,
      if (albumArtist != null) 'album_artist': albumArtist,
      if (trackNumber != null) 'track_number': trackNumber,
      if (discNumber != null) 'disc_number': discNumber,
      if (genre != null) 'genre': genre,
      if (releaseYear != null) 'release_year': releaseYear,
      if (durationMs != null) 'duration_ms': durationMs,
      if (artworkPath != null) 'artwork_path': artworkPath,
      if (dateAdded != null) 'date_added': dateAdded,
    });
  }

  TracksTableCompanion copyWith({
    Value<int>? id,
    Value<String>? filePath,
    Value<String>? title,
    Value<String>? artist,
    Value<int?>? albumId,
    Value<String?>? albumArtist,
    Value<int?>? trackNumber,
    Value<int?>? discNumber,
    Value<String?>? genre,
    Value<int?>? releaseYear,
    Value<int>? durationMs,
    Value<String?>? artworkPath,
    Value<DateTime>? dateAdded,
  }) {
    return TracksTableCompanion(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumId: albumId ?? this.albumId,
      albumArtist: albumArtist ?? this.albumArtist,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      genre: genre ?? this.genre,
      releaseYear: releaseYear ?? this.releaseYear,
      durationMs: durationMs ?? this.durationMs,
      artworkPath: artworkPath ?? this.artworkPath,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<int>(albumId.value);
    }
    if (albumArtist.present) {
      map['album_artist'] = Variable<String>(albumArtist.value);
    }
    if (trackNumber.present) {
      map['track_number'] = Variable<int>(trackNumber.value);
    }
    if (discNumber.present) {
      map['disc_number'] = Variable<int>(discNumber.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (releaseYear.present) {
      map['release_year'] = Variable<int>(releaseYear.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (artworkPath.present) {
      map['artwork_path'] = Variable<String>(artworkPath.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksTableCompanion(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('albumId: $albumId, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('genre: $genre, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('durationMs: $durationMs, ')
          ..write('artworkPath: $artworkPath, ')
          ..write('dateAdded: $dateAdded')
          ..write(')'))
        .toString();
  }
}

class $ArtistsTableTable extends ArtistsTable
    with TableInfo<$ArtistsTableTable, ArtistsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtistsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artists';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArtistsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArtistsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArtistsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $ArtistsTableTable createAlias(String alias) {
    return $ArtistsTableTable(attachedDatabase, alias);
  }
}

class ArtistsTableData extends DataClass
    implements Insertable<ArtistsTableData> {
  final int id;
  final String name;
  const ArtistsTableData({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  ArtistsTableCompanion toCompanion(bool nullToAbsent) {
    return ArtistsTableCompanion(id: Value(id), name: Value(name));
  }

  factory ArtistsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArtistsTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  ArtistsTableData copyWith({int? id, String? name}) =>
      ArtistsTableData(id: id ?? this.id, name: name ?? this.name);
  ArtistsTableData copyWithCompanion(ArtistsTableCompanion data) {
    return ArtistsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArtistsTableData(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArtistsTableData &&
          other.id == this.id &&
          other.name == this.name);
}

class ArtistsTableCompanion extends UpdateCompanion<ArtistsTableData> {
  final Value<int> id;
  final Value<String> name;
  const ArtistsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  ArtistsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<ArtistsTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  ArtistsTableCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return ArtistsTableCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtistsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $NodeIdentityTableTable extends NodeIdentityTable
    with TableInfo<$NodeIdentityTableTable, NodeIdentityTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodeIdentityTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actorUrlMeta = const VerificationMeta(
    'actorUrl',
  );
  @override
  late final GeneratedColumn<String> actorUrl = GeneratedColumn<String>(
    'actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _publicKeyPemMeta = const VerificationMeta(
    'publicKeyPem',
  );
  @override
  late final GeneratedColumn<String> publicKeyPem = GeneratedColumn<String>(
    'public_key_pem',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preferredUsernameMeta = const VerificationMeta(
    'preferredUsername',
  );
  @override
  late final GeneratedColumn<String> preferredUsername =
      GeneratedColumn<String>(
        'preferred_username',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _nodePublicAddressMeta = const VerificationMeta(
    'nodePublicAddress',
  );
  @override
  late final GeneratedColumn<String> nodePublicAddress =
      GeneratedColumn<String>(
        'node_public_address',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    actorUrl,
    publicKeyPem,
    preferredUsername,
    displayName,
    createdAt,
    nodePublicAddress,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'node_identity';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeIdentityTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('actor_url')) {
      context.handle(
        _actorUrlMeta,
        actorUrl.isAcceptableOrUnknown(data['actor_url']!, _actorUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_actorUrlMeta);
    }
    if (data.containsKey('public_key_pem')) {
      context.handle(
        _publicKeyPemMeta,
        publicKeyPem.isAcceptableOrUnknown(
          data['public_key_pem']!,
          _publicKeyPemMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicKeyPemMeta);
    }
    if (data.containsKey('preferred_username')) {
      context.handle(
        _preferredUsernameMeta,
        preferredUsername.isAcceptableOrUnknown(
          data['preferred_username']!,
          _preferredUsernameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_preferredUsernameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('node_public_address')) {
      context.handle(
        _nodePublicAddressMeta,
        nodePublicAddress.isAcceptableOrUnknown(
          data['node_public_address']!,
          _nodePublicAddressMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NodeIdentityTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeIdentityTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      actorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_url'],
      )!,
      publicKeyPem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key_pem'],
      )!,
      preferredUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_username'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      nodePublicAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_public_address'],
      ),
    );
  }

  @override
  $NodeIdentityTableTable createAlias(String alias) {
    return $NodeIdentityTableTable(attachedDatabase, alias);
  }
}

class NodeIdentityTableData extends DataClass
    implements Insertable<NodeIdentityTableData> {
  final int id;
  final String actorUrl;
  final String publicKeyPem;
  final String preferredUsername;
  final String displayName;
  final DateTime createdAt;
  final String? nodePublicAddress;
  const NodeIdentityTableData({
    required this.id,
    required this.actorUrl,
    required this.publicKeyPem,
    required this.preferredUsername,
    required this.displayName,
    required this.createdAt,
    this.nodePublicAddress,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['actor_url'] = Variable<String>(actorUrl);
    map['public_key_pem'] = Variable<String>(publicKeyPem);
    map['preferred_username'] = Variable<String>(preferredUsername);
    map['display_name'] = Variable<String>(displayName);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || nodePublicAddress != null) {
      map['node_public_address'] = Variable<String>(nodePublicAddress);
    }
    return map;
  }

  NodeIdentityTableCompanion toCompanion(bool nullToAbsent) {
    return NodeIdentityTableCompanion(
      id: Value(id),
      actorUrl: Value(actorUrl),
      publicKeyPem: Value(publicKeyPem),
      preferredUsername: Value(preferredUsername),
      displayName: Value(displayName),
      createdAt: Value(createdAt),
      nodePublicAddress: nodePublicAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(nodePublicAddress),
    );
  }

  factory NodeIdentityTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeIdentityTableData(
      id: serializer.fromJson<int>(json['id']),
      actorUrl: serializer.fromJson<String>(json['actorUrl']),
      publicKeyPem: serializer.fromJson<String>(json['publicKeyPem']),
      preferredUsername: serializer.fromJson<String>(json['preferredUsername']),
      displayName: serializer.fromJson<String>(json['displayName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      nodePublicAddress: serializer.fromJson<String?>(
        json['nodePublicAddress'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'actorUrl': serializer.toJson<String>(actorUrl),
      'publicKeyPem': serializer.toJson<String>(publicKeyPem),
      'preferredUsername': serializer.toJson<String>(preferredUsername),
      'displayName': serializer.toJson<String>(displayName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'nodePublicAddress': serializer.toJson<String?>(nodePublicAddress),
    };
  }

  NodeIdentityTableData copyWith({
    int? id,
    String? actorUrl,
    String? publicKeyPem,
    String? preferredUsername,
    String? displayName,
    DateTime? createdAt,
    Value<String?> nodePublicAddress = const Value.absent(),
  }) => NodeIdentityTableData(
    id: id ?? this.id,
    actorUrl: actorUrl ?? this.actorUrl,
    publicKeyPem: publicKeyPem ?? this.publicKeyPem,
    preferredUsername: preferredUsername ?? this.preferredUsername,
    displayName: displayName ?? this.displayName,
    createdAt: createdAt ?? this.createdAt,
    nodePublicAddress: nodePublicAddress.present
        ? nodePublicAddress.value
        : this.nodePublicAddress,
  );
  NodeIdentityTableData copyWithCompanion(NodeIdentityTableCompanion data) {
    return NodeIdentityTableData(
      id: data.id.present ? data.id.value : this.id,
      actorUrl: data.actorUrl.present ? data.actorUrl.value : this.actorUrl,
      publicKeyPem: data.publicKeyPem.present
          ? data.publicKeyPem.value
          : this.publicKeyPem,
      preferredUsername: data.preferredUsername.present
          ? data.preferredUsername.value
          : this.preferredUsername,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      nodePublicAddress: data.nodePublicAddress.present
          ? data.nodePublicAddress.value
          : this.nodePublicAddress,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeIdentityTableData(')
          ..write('id: $id, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('publicKeyPem: $publicKeyPem, ')
          ..write('preferredUsername: $preferredUsername, ')
          ..write('displayName: $displayName, ')
          ..write('createdAt: $createdAt, ')
          ..write('nodePublicAddress: $nodePublicAddress')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    actorUrl,
    publicKeyPem,
    preferredUsername,
    displayName,
    createdAt,
    nodePublicAddress,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeIdentityTableData &&
          other.id == this.id &&
          other.actorUrl == this.actorUrl &&
          other.publicKeyPem == this.publicKeyPem &&
          other.preferredUsername == this.preferredUsername &&
          other.displayName == this.displayName &&
          other.createdAt == this.createdAt &&
          other.nodePublicAddress == this.nodePublicAddress);
}

class NodeIdentityTableCompanion
    extends UpdateCompanion<NodeIdentityTableData> {
  final Value<int> id;
  final Value<String> actorUrl;
  final Value<String> publicKeyPem;
  final Value<String> preferredUsername;
  final Value<String> displayName;
  final Value<DateTime> createdAt;
  final Value<String?> nodePublicAddress;
  const NodeIdentityTableCompanion({
    this.id = const Value.absent(),
    this.actorUrl = const Value.absent(),
    this.publicKeyPem = const Value.absent(),
    this.preferredUsername = const Value.absent(),
    this.displayName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.nodePublicAddress = const Value.absent(),
  });
  NodeIdentityTableCompanion.insert({
    this.id = const Value.absent(),
    required String actorUrl,
    required String publicKeyPem,
    required String preferredUsername,
    required String displayName,
    this.createdAt = const Value.absent(),
    this.nodePublicAddress = const Value.absent(),
  }) : actorUrl = Value(actorUrl),
       publicKeyPem = Value(publicKeyPem),
       preferredUsername = Value(preferredUsername),
       displayName = Value(displayName);
  static Insertable<NodeIdentityTableData> custom({
    Expression<int>? id,
    Expression<String>? actorUrl,
    Expression<String>? publicKeyPem,
    Expression<String>? preferredUsername,
    Expression<String>? displayName,
    Expression<DateTime>? createdAt,
    Expression<String>? nodePublicAddress,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actorUrl != null) 'actor_url': actorUrl,
      if (publicKeyPem != null) 'public_key_pem': publicKeyPem,
      if (preferredUsername != null) 'preferred_username': preferredUsername,
      if (displayName != null) 'display_name': displayName,
      if (createdAt != null) 'created_at': createdAt,
      if (nodePublicAddress != null) 'node_public_address': nodePublicAddress,
    });
  }

  NodeIdentityTableCompanion copyWith({
    Value<int>? id,
    Value<String>? actorUrl,
    Value<String>? publicKeyPem,
    Value<String>? preferredUsername,
    Value<String>? displayName,
    Value<DateTime>? createdAt,
    Value<String?>? nodePublicAddress,
  }) {
    return NodeIdentityTableCompanion(
      id: id ?? this.id,
      actorUrl: actorUrl ?? this.actorUrl,
      publicKeyPem: publicKeyPem ?? this.publicKeyPem,
      preferredUsername: preferredUsername ?? this.preferredUsername,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      nodePublicAddress: nodePublicAddress ?? this.nodePublicAddress,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (actorUrl.present) {
      map['actor_url'] = Variable<String>(actorUrl.value);
    }
    if (publicKeyPem.present) {
      map['public_key_pem'] = Variable<String>(publicKeyPem.value);
    }
    if (preferredUsername.present) {
      map['preferred_username'] = Variable<String>(preferredUsername.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (nodePublicAddress.present) {
      map['node_public_address'] = Variable<String>(nodePublicAddress.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodeIdentityTableCompanion(')
          ..write('id: $id, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('publicKeyPem: $publicKeyPem, ')
          ..write('preferredUsername: $preferredUsername, ')
          ..write('displayName: $displayName, ')
          ..write('createdAt: $createdAt, ')
          ..write('nodePublicAddress: $nodePublicAddress')
          ..write(')'))
        .toString();
  }
}

class $InboxActivitiesTableTable extends InboxActivitiesTable
    with TableInfo<$InboxActivitiesTableTable, InboxActivitiesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InboxActivitiesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorUrlMeta = const VerificationMeta(
    'actorUrl',
  );
  @override
  late final GeneratedColumn<String> actorUrl = GeneratedColumn<String>(
    'actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _objectJsonMeta = const VerificationMeta(
    'objectJson',
  );
  @override
  late final GeneratedColumn<String> objectJson = GeneratedColumn<String>(
    'object_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _processedMeta = const VerificationMeta(
    'processed',
  );
  @override
  late final GeneratedColumn<bool> processed = GeneratedColumn<bool>(
    'processed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("processed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    activityId,
    type,
    actorUrl,
    objectJson,
    rawJson,
    receivedAt,
    processed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inbox_activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<InboxActivitiesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('actor_url')) {
      context.handle(
        _actorUrlMeta,
        actorUrl.isAcceptableOrUnknown(data['actor_url']!, _actorUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_actorUrlMeta);
    }
    if (data.containsKey('object_json')) {
      context.handle(
        _objectJsonMeta,
        objectJson.isAcceptableOrUnknown(data['object_json']!, _objectJsonMeta),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    }
    if (data.containsKey('processed')) {
      context.handle(
        _processedMeta,
        processed.isAcceptableOrUnknown(data['processed']!, _processedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  InboxActivitiesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InboxActivitiesTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      actorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_url'],
      )!,
      objectJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object_json'],
      ),
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      processed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}processed'],
      )!,
    );
  }

  @override
  $InboxActivitiesTableTable createAlias(String alias) {
    return $InboxActivitiesTableTable(attachedDatabase, alias);
  }
}

class InboxActivitiesTableData extends DataClass
    implements Insertable<InboxActivitiesTableData> {
  final int rowId;
  final String activityId;
  final String type;
  final String actorUrl;
  final String? objectJson;
  final String rawJson;
  final DateTime receivedAt;
  final bool processed;
  const InboxActivitiesTableData({
    required this.rowId,
    required this.activityId,
    required this.type,
    required this.actorUrl,
    this.objectJson,
    required this.rawJson,
    required this.receivedAt,
    required this.processed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['activity_id'] = Variable<String>(activityId);
    map['type'] = Variable<String>(type);
    map['actor_url'] = Variable<String>(actorUrl);
    if (!nullToAbsent || objectJson != null) {
      map['object_json'] = Variable<String>(objectJson);
    }
    map['raw_json'] = Variable<String>(rawJson);
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['processed'] = Variable<bool>(processed);
    return map;
  }

  InboxActivitiesTableCompanion toCompanion(bool nullToAbsent) {
    return InboxActivitiesTableCompanion(
      rowId: Value(rowId),
      activityId: Value(activityId),
      type: Value(type),
      actorUrl: Value(actorUrl),
      objectJson: objectJson == null && nullToAbsent
          ? const Value.absent()
          : Value(objectJson),
      rawJson: Value(rawJson),
      receivedAt: Value(receivedAt),
      processed: Value(processed),
    );
  }

  factory InboxActivitiesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InboxActivitiesTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      activityId: serializer.fromJson<String>(json['activityId']),
      type: serializer.fromJson<String>(json['type']),
      actorUrl: serializer.fromJson<String>(json['actorUrl']),
      objectJson: serializer.fromJson<String?>(json['objectJson']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      processed: serializer.fromJson<bool>(json['processed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'activityId': serializer.toJson<String>(activityId),
      'type': serializer.toJson<String>(type),
      'actorUrl': serializer.toJson<String>(actorUrl),
      'objectJson': serializer.toJson<String?>(objectJson),
      'rawJson': serializer.toJson<String>(rawJson),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'processed': serializer.toJson<bool>(processed),
    };
  }

  InboxActivitiesTableData copyWith({
    int? rowId,
    String? activityId,
    String? type,
    String? actorUrl,
    Value<String?> objectJson = const Value.absent(),
    String? rawJson,
    DateTime? receivedAt,
    bool? processed,
  }) => InboxActivitiesTableData(
    rowId: rowId ?? this.rowId,
    activityId: activityId ?? this.activityId,
    type: type ?? this.type,
    actorUrl: actorUrl ?? this.actorUrl,
    objectJson: objectJson.present ? objectJson.value : this.objectJson,
    rawJson: rawJson ?? this.rawJson,
    receivedAt: receivedAt ?? this.receivedAt,
    processed: processed ?? this.processed,
  );
  InboxActivitiesTableData copyWithCompanion(
    InboxActivitiesTableCompanion data,
  ) {
    return InboxActivitiesTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      type: data.type.present ? data.type.value : this.type,
      actorUrl: data.actorUrl.present ? data.actorUrl.value : this.actorUrl,
      objectJson: data.objectJson.present
          ? data.objectJson.value
          : this.objectJson,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      processed: data.processed.present ? data.processed.value : this.processed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InboxActivitiesTableData(')
          ..write('rowId: $rowId, ')
          ..write('activityId: $activityId, ')
          ..write('type: $type, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('objectJson: $objectJson, ')
          ..write('rawJson: $rawJson, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('processed: $processed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    activityId,
    type,
    actorUrl,
    objectJson,
    rawJson,
    receivedAt,
    processed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InboxActivitiesTableData &&
          other.rowId == this.rowId &&
          other.activityId == this.activityId &&
          other.type == this.type &&
          other.actorUrl == this.actorUrl &&
          other.objectJson == this.objectJson &&
          other.rawJson == this.rawJson &&
          other.receivedAt == this.receivedAt &&
          other.processed == this.processed);
}

class InboxActivitiesTableCompanion
    extends UpdateCompanion<InboxActivitiesTableData> {
  final Value<int> rowId;
  final Value<String> activityId;
  final Value<String> type;
  final Value<String> actorUrl;
  final Value<String?> objectJson;
  final Value<String> rawJson;
  final Value<DateTime> receivedAt;
  final Value<bool> processed;
  const InboxActivitiesTableCompanion({
    this.rowId = const Value.absent(),
    this.activityId = const Value.absent(),
    this.type = const Value.absent(),
    this.actorUrl = const Value.absent(),
    this.objectJson = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.processed = const Value.absent(),
  });
  InboxActivitiesTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String activityId,
    required String type,
    required String actorUrl,
    this.objectJson = const Value.absent(),
    required String rawJson,
    this.receivedAt = const Value.absent(),
    this.processed = const Value.absent(),
  }) : activityId = Value(activityId),
       type = Value(type),
       actorUrl = Value(actorUrl),
       rawJson = Value(rawJson);
  static Insertable<InboxActivitiesTableData> custom({
    Expression<int>? rowId,
    Expression<String>? activityId,
    Expression<String>? type,
    Expression<String>? actorUrl,
    Expression<String>? objectJson,
    Expression<String>? rawJson,
    Expression<DateTime>? receivedAt,
    Expression<bool>? processed,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (activityId != null) 'activity_id': activityId,
      if (type != null) 'type': type,
      if (actorUrl != null) 'actor_url': actorUrl,
      if (objectJson != null) 'object_json': objectJson,
      if (rawJson != null) 'raw_json': rawJson,
      if (receivedAt != null) 'received_at': receivedAt,
      if (processed != null) 'processed': processed,
    });
  }

  InboxActivitiesTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? activityId,
    Value<String>? type,
    Value<String>? actorUrl,
    Value<String?>? objectJson,
    Value<String>? rawJson,
    Value<DateTime>? receivedAt,
    Value<bool>? processed,
  }) {
    return InboxActivitiesTableCompanion(
      rowId: rowId ?? this.rowId,
      activityId: activityId ?? this.activityId,
      type: type ?? this.type,
      actorUrl: actorUrl ?? this.actorUrl,
      objectJson: objectJson ?? this.objectJson,
      rawJson: rawJson ?? this.rawJson,
      receivedAt: receivedAt ?? this.receivedAt,
      processed: processed ?? this.processed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (actorUrl.present) {
      map['actor_url'] = Variable<String>(actorUrl.value);
    }
    if (objectJson.present) {
      map['object_json'] = Variable<String>(objectJson.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (processed.present) {
      map['processed'] = Variable<bool>(processed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InboxActivitiesTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('activityId: $activityId, ')
          ..write('type: $type, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('objectJson: $objectJson, ')
          ..write('rawJson: $rawJson, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('processed: $processed')
          ..write(')'))
        .toString();
  }
}

class $OutboxActivitiesTableTable extends OutboxActivitiesTable
    with TableInfo<$OutboxActivitiesTableTable, OutboxActivitiesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxActivitiesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetInboxUrlMeta = const VerificationMeta(
    'targetInboxUrl',
  );
  @override
  late final GeneratedColumn<String> targetInboxUrl = GeneratedColumn<String>(
    'target_inbox_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _relayReferenceIdMeta = const VerificationMeta(
    'relayReferenceId',
  );
  @override
  late final GeneratedColumn<String> relayReferenceId = GeneratedColumn<String>(
    'relay_reference_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastAttemptedAtMeta = const VerificationMeta(
    'lastAttemptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptedAt =
      GeneratedColumn<DateTime>(
        'last_attempted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    activityId,
    type,
    targetInboxUrl,
    payloadJson,
    status,
    attemptCount,
    relayReferenceId,
    createdAt,
    lastAttemptedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxActivitiesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('target_inbox_url')) {
      context.handle(
        _targetInboxUrlMeta,
        targetInboxUrl.isAcceptableOrUnknown(
          data['target_inbox_url']!,
          _targetInboxUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetInboxUrlMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('relay_reference_id')) {
      context.handle(
        _relayReferenceIdMeta,
        relayReferenceId.isAcceptableOrUnknown(
          data['relay_reference_id']!,
          _relayReferenceIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_attempted_at')) {
      context.handle(
        _lastAttemptedAtMeta,
        lastAttemptedAt.isAcceptableOrUnknown(
          data['last_attempted_at']!,
          _lastAttemptedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  OutboxActivitiesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxActivitiesTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      targetInboxUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_inbox_url'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      relayReferenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relay_reference_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempted_at'],
      ),
    );
  }

  @override
  $OutboxActivitiesTableTable createAlias(String alias) {
    return $OutboxActivitiesTableTable(attachedDatabase, alias);
  }
}

class OutboxActivitiesTableData extends DataClass
    implements Insertable<OutboxActivitiesTableData> {
  final int rowId;
  final String activityId;
  final String type;
  final String targetInboxUrl;
  final String payloadJson;
  final String status;
  final int attemptCount;
  final String? relayReferenceId;
  final DateTime createdAt;
  final DateTime? lastAttemptedAt;
  const OutboxActivitiesTableData({
    required this.rowId,
    required this.activityId,
    required this.type,
    required this.targetInboxUrl,
    required this.payloadJson,
    required this.status,
    required this.attemptCount,
    this.relayReferenceId,
    required this.createdAt,
    this.lastAttemptedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['activity_id'] = Variable<String>(activityId);
    map['type'] = Variable<String>(type);
    map['target_inbox_url'] = Variable<String>(targetInboxUrl);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || relayReferenceId != null) {
      map['relay_reference_id'] = Variable<String>(relayReferenceId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptedAt != null) {
      map['last_attempted_at'] = Variable<DateTime>(lastAttemptedAt);
    }
    return map;
  }

  OutboxActivitiesTableCompanion toCompanion(bool nullToAbsent) {
    return OutboxActivitiesTableCompanion(
      rowId: Value(rowId),
      activityId: Value(activityId),
      type: Value(type),
      targetInboxUrl: Value(targetInboxUrl),
      payloadJson: Value(payloadJson),
      status: Value(status),
      attemptCount: Value(attemptCount),
      relayReferenceId: relayReferenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(relayReferenceId),
      createdAt: Value(createdAt),
      lastAttemptedAt: lastAttemptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptedAt),
    );
  }

  factory OutboxActivitiesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxActivitiesTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      activityId: serializer.fromJson<String>(json['activityId']),
      type: serializer.fromJson<String>(json['type']),
      targetInboxUrl: serializer.fromJson<String>(json['targetInboxUrl']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      relayReferenceId: serializer.fromJson<String?>(json['relayReferenceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptedAt: serializer.fromJson<DateTime?>(json['lastAttemptedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'activityId': serializer.toJson<String>(activityId),
      'type': serializer.toJson<String>(type),
      'targetInboxUrl': serializer.toJson<String>(targetInboxUrl),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'relayReferenceId': serializer.toJson<String?>(relayReferenceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptedAt': serializer.toJson<DateTime?>(lastAttemptedAt),
    };
  }

  OutboxActivitiesTableData copyWith({
    int? rowId,
    String? activityId,
    String? type,
    String? targetInboxUrl,
    String? payloadJson,
    String? status,
    int? attemptCount,
    Value<String?> relayReferenceId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> lastAttemptedAt = const Value.absent(),
  }) => OutboxActivitiesTableData(
    rowId: rowId ?? this.rowId,
    activityId: activityId ?? this.activityId,
    type: type ?? this.type,
    targetInboxUrl: targetInboxUrl ?? this.targetInboxUrl,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    relayReferenceId: relayReferenceId.present
        ? relayReferenceId.value
        : this.relayReferenceId,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptedAt: lastAttemptedAt.present
        ? lastAttemptedAt.value
        : this.lastAttemptedAt,
  );
  OutboxActivitiesTableData copyWithCompanion(
    OutboxActivitiesTableCompanion data,
  ) {
    return OutboxActivitiesTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      type: data.type.present ? data.type.value : this.type,
      targetInboxUrl: data.targetInboxUrl.present
          ? data.targetInboxUrl.value
          : this.targetInboxUrl,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      relayReferenceId: data.relayReferenceId.present
          ? data.relayReferenceId.value
          : this.relayReferenceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptedAt: data.lastAttemptedAt.present
          ? data.lastAttemptedAt.value
          : this.lastAttemptedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxActivitiesTableData(')
          ..write('rowId: $rowId, ')
          ..write('activityId: $activityId, ')
          ..write('type: $type, ')
          ..write('targetInboxUrl: $targetInboxUrl, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('relayReferenceId: $relayReferenceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptedAt: $lastAttemptedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    activityId,
    type,
    targetInboxUrl,
    payloadJson,
    status,
    attemptCount,
    relayReferenceId,
    createdAt,
    lastAttemptedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxActivitiesTableData &&
          other.rowId == this.rowId &&
          other.activityId == this.activityId &&
          other.type == this.type &&
          other.targetInboxUrl == this.targetInboxUrl &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.relayReferenceId == this.relayReferenceId &&
          other.createdAt == this.createdAt &&
          other.lastAttemptedAt == this.lastAttemptedAt);
}

class OutboxActivitiesTableCompanion
    extends UpdateCompanion<OutboxActivitiesTableData> {
  final Value<int> rowId;
  final Value<String> activityId;
  final Value<String> type;
  final Value<String> targetInboxUrl;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<String?> relayReferenceId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptedAt;
  const OutboxActivitiesTableCompanion({
    this.rowId = const Value.absent(),
    this.activityId = const Value.absent(),
    this.type = const Value.absent(),
    this.targetInboxUrl = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.relayReferenceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptedAt = const Value.absent(),
  });
  OutboxActivitiesTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String activityId,
    required String type,
    required String targetInboxUrl,
    required String payloadJson,
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.relayReferenceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptedAt = const Value.absent(),
  }) : activityId = Value(activityId),
       type = Value(type),
       targetInboxUrl = Value(targetInboxUrl),
       payloadJson = Value(payloadJson);
  static Insertable<OutboxActivitiesTableData> custom({
    Expression<int>? rowId,
    Expression<String>? activityId,
    Expression<String>? type,
    Expression<String>? targetInboxUrl,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<String>? relayReferenceId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptedAt,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (activityId != null) 'activity_id': activityId,
      if (type != null) 'type': type,
      if (targetInboxUrl != null) 'target_inbox_url': targetInboxUrl,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (relayReferenceId != null) 'relay_reference_id': relayReferenceId,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptedAt != null) 'last_attempted_at': lastAttemptedAt,
    });
  }

  OutboxActivitiesTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? activityId,
    Value<String>? type,
    Value<String>? targetInboxUrl,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<int>? attemptCount,
    Value<String?>? relayReferenceId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptedAt,
  }) {
    return OutboxActivitiesTableCompanion(
      rowId: rowId ?? this.rowId,
      activityId: activityId ?? this.activityId,
      type: type ?? this.type,
      targetInboxUrl: targetInboxUrl ?? this.targetInboxUrl,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      relayReferenceId: relayReferenceId ?? this.relayReferenceId,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptedAt: lastAttemptedAt ?? this.lastAttemptedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (targetInboxUrl.present) {
      map['target_inbox_url'] = Variable<String>(targetInboxUrl.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (relayReferenceId.present) {
      map['relay_reference_id'] = Variable<String>(relayReferenceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptedAt.present) {
      map['last_attempted_at'] = Variable<DateTime>(lastAttemptedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxActivitiesTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('activityId: $activityId, ')
          ..write('type: $type, ')
          ..write('targetInboxUrl: $targetInboxUrl, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('relayReferenceId: $relayReferenceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptedAt: $lastAttemptedAt')
          ..write(')'))
        .toString();
  }
}

class $ActorCacheTableTable extends ActorCacheTable
    with TableInfo<$ActorCacheTableTable, ActorCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActorCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actorUrlMeta = const VerificationMeta(
    'actorUrl',
  );
  @override
  late final GeneratedColumn<String> actorUrl = GeneratedColumn<String>(
    'actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _actorJsonMeta = const VerificationMeta(
    'actorJson',
  );
  @override
  late final GeneratedColumn<String> actorJson = GeneratedColumn<String>(
    'actor_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _ttlSecondsMeta = const VerificationMeta(
    'ttlSeconds',
  );
  @override
  late final GeneratedColumn<int> ttlSeconds = GeneratedColumn<int>(
    'ttl_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(900),
  );
  static const VerificationMeta _discoverySourceMeta = const VerificationMeta(
    'discoverySource',
  );
  @override
  late final GeneratedColumn<String> discoverySource = GeneratedColumn<String>(
    'discovery_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    actorUrl,
    actorJson,
    cachedAt,
    ttlSeconds,
    discoverySource,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'actor_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActorCacheTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('actor_url')) {
      context.handle(
        _actorUrlMeta,
        actorUrl.isAcceptableOrUnknown(data['actor_url']!, _actorUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_actorUrlMeta);
    }
    if (data.containsKey('actor_json')) {
      context.handle(
        _actorJsonMeta,
        actorJson.isAcceptableOrUnknown(data['actor_json']!, _actorJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_actorJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    if (data.containsKey('ttl_seconds')) {
      context.handle(
        _ttlSecondsMeta,
        ttlSeconds.isAcceptableOrUnknown(data['ttl_seconds']!, _ttlSecondsMeta),
      );
    }
    if (data.containsKey('discovery_source')) {
      context.handle(
        _discoverySourceMeta,
        discoverySource.isAcceptableOrUnknown(
          data['discovery_source']!,
          _discoverySourceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  ActorCacheTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActorCacheTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      actorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_url'],
      )!,
      actorJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      ttlSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ttl_seconds'],
      )!,
      discoverySource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discovery_source'],
      )!,
    );
  }

  @override
  $ActorCacheTableTable createAlias(String alias) {
    return $ActorCacheTableTable(attachedDatabase, alias);
  }
}

class ActorCacheTableData extends DataClass
    implements Insertable<ActorCacheTableData> {
  final int rowId;
  final String actorUrl;
  final String actorJson;
  final DateTime cachedAt;
  final int ttlSeconds;
  final String discoverySource;
  const ActorCacheTableData({
    required this.rowId,
    required this.actorUrl,
    required this.actorJson,
    required this.cachedAt,
    required this.ttlSeconds,
    required this.discoverySource,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['actor_url'] = Variable<String>(actorUrl);
    map['actor_json'] = Variable<String>(actorJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['ttl_seconds'] = Variable<int>(ttlSeconds);
    map['discovery_source'] = Variable<String>(discoverySource);
    return map;
  }

  ActorCacheTableCompanion toCompanion(bool nullToAbsent) {
    return ActorCacheTableCompanion(
      rowId: Value(rowId),
      actorUrl: Value(actorUrl),
      actorJson: Value(actorJson),
      cachedAt: Value(cachedAt),
      ttlSeconds: Value(ttlSeconds),
      discoverySource: Value(discoverySource),
    );
  }

  factory ActorCacheTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActorCacheTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      actorUrl: serializer.fromJson<String>(json['actorUrl']),
      actorJson: serializer.fromJson<String>(json['actorJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      ttlSeconds: serializer.fromJson<int>(json['ttlSeconds']),
      discoverySource: serializer.fromJson<String>(json['discoverySource']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'actorUrl': serializer.toJson<String>(actorUrl),
      'actorJson': serializer.toJson<String>(actorJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'ttlSeconds': serializer.toJson<int>(ttlSeconds),
      'discoverySource': serializer.toJson<String>(discoverySource),
    };
  }

  ActorCacheTableData copyWith({
    int? rowId,
    String? actorUrl,
    String? actorJson,
    DateTime? cachedAt,
    int? ttlSeconds,
    String? discoverySource,
  }) => ActorCacheTableData(
    rowId: rowId ?? this.rowId,
    actorUrl: actorUrl ?? this.actorUrl,
    actorJson: actorJson ?? this.actorJson,
    cachedAt: cachedAt ?? this.cachedAt,
    ttlSeconds: ttlSeconds ?? this.ttlSeconds,
    discoverySource: discoverySource ?? this.discoverySource,
  );
  ActorCacheTableData copyWithCompanion(ActorCacheTableCompanion data) {
    return ActorCacheTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      actorUrl: data.actorUrl.present ? data.actorUrl.value : this.actorUrl,
      actorJson: data.actorJson.present ? data.actorJson.value : this.actorJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      ttlSeconds: data.ttlSeconds.present
          ? data.ttlSeconds.value
          : this.ttlSeconds,
      discoverySource: data.discoverySource.present
          ? data.discoverySource.value
          : this.discoverySource,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActorCacheTableData(')
          ..write('rowId: $rowId, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('actorJson: $actorJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('ttlSeconds: $ttlSeconds, ')
          ..write('discoverySource: $discoverySource')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    actorUrl,
    actorJson,
    cachedAt,
    ttlSeconds,
    discoverySource,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActorCacheTableData &&
          other.rowId == this.rowId &&
          other.actorUrl == this.actorUrl &&
          other.actorJson == this.actorJson &&
          other.cachedAt == this.cachedAt &&
          other.ttlSeconds == this.ttlSeconds &&
          other.discoverySource == this.discoverySource);
}

class ActorCacheTableCompanion extends UpdateCompanion<ActorCacheTableData> {
  final Value<int> rowId;
  final Value<String> actorUrl;
  final Value<String> actorJson;
  final Value<DateTime> cachedAt;
  final Value<int> ttlSeconds;
  final Value<String> discoverySource;
  const ActorCacheTableCompanion({
    this.rowId = const Value.absent(),
    this.actorUrl = const Value.absent(),
    this.actorJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.ttlSeconds = const Value.absent(),
    this.discoverySource = const Value.absent(),
  });
  ActorCacheTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String actorUrl,
    required String actorJson,
    this.cachedAt = const Value.absent(),
    this.ttlSeconds = const Value.absent(),
    this.discoverySource = const Value.absent(),
  }) : actorUrl = Value(actorUrl),
       actorJson = Value(actorJson);
  static Insertable<ActorCacheTableData> custom({
    Expression<int>? rowId,
    Expression<String>? actorUrl,
    Expression<String>? actorJson,
    Expression<DateTime>? cachedAt,
    Expression<int>? ttlSeconds,
    Expression<String>? discoverySource,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (actorUrl != null) 'actor_url': actorUrl,
      if (actorJson != null) 'actor_json': actorJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (ttlSeconds != null) 'ttl_seconds': ttlSeconds,
      if (discoverySource != null) 'discovery_source': discoverySource,
    });
  }

  ActorCacheTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? actorUrl,
    Value<String>? actorJson,
    Value<DateTime>? cachedAt,
    Value<int>? ttlSeconds,
    Value<String>? discoverySource,
  }) {
    return ActorCacheTableCompanion(
      rowId: rowId ?? this.rowId,
      actorUrl: actorUrl ?? this.actorUrl,
      actorJson: actorJson ?? this.actorJson,
      cachedAt: cachedAt ?? this.cachedAt,
      ttlSeconds: ttlSeconds ?? this.ttlSeconds,
      discoverySource: discoverySource ?? this.discoverySource,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (actorUrl.present) {
      map['actor_url'] = Variable<String>(actorUrl.value);
    }
    if (actorJson.present) {
      map['actor_json'] = Variable<String>(actorJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (ttlSeconds.present) {
      map['ttl_seconds'] = Variable<int>(ttlSeconds.value);
    }
    if (discoverySource.present) {
      map['discovery_source'] = Variable<String>(discoverySource.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActorCacheTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('actorJson: $actorJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('ttlSeconds: $ttlSeconds, ')
          ..write('discoverySource: $discoverySource')
          ..write(')'))
        .toString();
  }
}

class $FollowersTableTable extends FollowersTable
    with TableInfo<$FollowersTableTable, FollowersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FollowersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actorUrlMeta = const VerificationMeta(
    'actorUrl',
  );
  @override
  late final GeneratedColumn<String> actorUrl = GeneratedColumn<String>(
    'actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _followedAtMeta = const VerificationMeta(
    'followedAt',
  );
  @override
  late final GeneratedColumn<DateTime> followedAt = GeneratedColumn<DateTime>(
    'followed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [rowId, actorUrl, followedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'followers';
  @override
  VerificationContext validateIntegrity(
    Insertable<FollowersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('actor_url')) {
      context.handle(
        _actorUrlMeta,
        actorUrl.isAcceptableOrUnknown(data['actor_url']!, _actorUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_actorUrlMeta);
    }
    if (data.containsKey('followed_at')) {
      context.handle(
        _followedAtMeta,
        followedAt.isAcceptableOrUnknown(data['followed_at']!, _followedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  FollowersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FollowersTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      actorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_url'],
      )!,
      followedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}followed_at'],
      )!,
    );
  }

  @override
  $FollowersTableTable createAlias(String alias) {
    return $FollowersTableTable(attachedDatabase, alias);
  }
}

class FollowersTableData extends DataClass
    implements Insertable<FollowersTableData> {
  final int rowId;
  final String actorUrl;
  final DateTime followedAt;
  const FollowersTableData({
    required this.rowId,
    required this.actorUrl,
    required this.followedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['actor_url'] = Variable<String>(actorUrl);
    map['followed_at'] = Variable<DateTime>(followedAt);
    return map;
  }

  FollowersTableCompanion toCompanion(bool nullToAbsent) {
    return FollowersTableCompanion(
      rowId: Value(rowId),
      actorUrl: Value(actorUrl),
      followedAt: Value(followedAt),
    );
  }

  factory FollowersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FollowersTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      actorUrl: serializer.fromJson<String>(json['actorUrl']),
      followedAt: serializer.fromJson<DateTime>(json['followedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'actorUrl': serializer.toJson<String>(actorUrl),
      'followedAt': serializer.toJson<DateTime>(followedAt),
    };
  }

  FollowersTableData copyWith({
    int? rowId,
    String? actorUrl,
    DateTime? followedAt,
  }) => FollowersTableData(
    rowId: rowId ?? this.rowId,
    actorUrl: actorUrl ?? this.actorUrl,
    followedAt: followedAt ?? this.followedAt,
  );
  FollowersTableData copyWithCompanion(FollowersTableCompanion data) {
    return FollowersTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      actorUrl: data.actorUrl.present ? data.actorUrl.value : this.actorUrl,
      followedAt: data.followedAt.present
          ? data.followedAt.value
          : this.followedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FollowersTableData(')
          ..write('rowId: $rowId, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('followedAt: $followedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, actorUrl, followedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FollowersTableData &&
          other.rowId == this.rowId &&
          other.actorUrl == this.actorUrl &&
          other.followedAt == this.followedAt);
}

class FollowersTableCompanion extends UpdateCompanion<FollowersTableData> {
  final Value<int> rowId;
  final Value<String> actorUrl;
  final Value<DateTime> followedAt;
  const FollowersTableCompanion({
    this.rowId = const Value.absent(),
    this.actorUrl = const Value.absent(),
    this.followedAt = const Value.absent(),
  });
  FollowersTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String actorUrl,
    this.followedAt = const Value.absent(),
  }) : actorUrl = Value(actorUrl);
  static Insertable<FollowersTableData> custom({
    Expression<int>? rowId,
    Expression<String>? actorUrl,
    Expression<DateTime>? followedAt,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (actorUrl != null) 'actor_url': actorUrl,
      if (followedAt != null) 'followed_at': followedAt,
    });
  }

  FollowersTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? actorUrl,
    Value<DateTime>? followedAt,
  }) {
    return FollowersTableCompanion(
      rowId: rowId ?? this.rowId,
      actorUrl: actorUrl ?? this.actorUrl,
      followedAt: followedAt ?? this.followedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (actorUrl.present) {
      map['actor_url'] = Variable<String>(actorUrl.value);
    }
    if (followedAt.present) {
      map['followed_at'] = Variable<DateTime>(followedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowersTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('followedAt: $followedAt')
          ..write(')'))
        .toString();
  }
}

class $FollowingTableTable extends FollowingTable
    with TableInfo<$FollowingTableTable, FollowingTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FollowingTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actorUrlMeta = const VerificationMeta(
    'actorUrl',
  );
  @override
  late final GeneratedColumn<String> actorUrl = GeneratedColumn<String>(
    'actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _followedAtMeta = const VerificationMeta(
    'followedAt',
  );
  @override
  late final GeneratedColumn<DateTime> followedAt = GeneratedColumn<DateTime>(
    'followed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [rowId, actorUrl, followedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'following';
  @override
  VerificationContext validateIntegrity(
    Insertable<FollowingTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('actor_url')) {
      context.handle(
        _actorUrlMeta,
        actorUrl.isAcceptableOrUnknown(data['actor_url']!, _actorUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_actorUrlMeta);
    }
    if (data.containsKey('followed_at')) {
      context.handle(
        _followedAtMeta,
        followedAt.isAcceptableOrUnknown(data['followed_at']!, _followedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  FollowingTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FollowingTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      actorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_url'],
      )!,
      followedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}followed_at'],
      )!,
    );
  }

  @override
  $FollowingTableTable createAlias(String alias) {
    return $FollowingTableTable(attachedDatabase, alias);
  }
}

class FollowingTableData extends DataClass
    implements Insertable<FollowingTableData> {
  final int rowId;
  final String actorUrl;
  final DateTime followedAt;
  const FollowingTableData({
    required this.rowId,
    required this.actorUrl,
    required this.followedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['actor_url'] = Variable<String>(actorUrl);
    map['followed_at'] = Variable<DateTime>(followedAt);
    return map;
  }

  FollowingTableCompanion toCompanion(bool nullToAbsent) {
    return FollowingTableCompanion(
      rowId: Value(rowId),
      actorUrl: Value(actorUrl),
      followedAt: Value(followedAt),
    );
  }

  factory FollowingTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FollowingTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      actorUrl: serializer.fromJson<String>(json['actorUrl']),
      followedAt: serializer.fromJson<DateTime>(json['followedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'actorUrl': serializer.toJson<String>(actorUrl),
      'followedAt': serializer.toJson<DateTime>(followedAt),
    };
  }

  FollowingTableData copyWith({
    int? rowId,
    String? actorUrl,
    DateTime? followedAt,
  }) => FollowingTableData(
    rowId: rowId ?? this.rowId,
    actorUrl: actorUrl ?? this.actorUrl,
    followedAt: followedAt ?? this.followedAt,
  );
  FollowingTableData copyWithCompanion(FollowingTableCompanion data) {
    return FollowingTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      actorUrl: data.actorUrl.present ? data.actorUrl.value : this.actorUrl,
      followedAt: data.followedAt.present
          ? data.followedAt.value
          : this.followedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FollowingTableData(')
          ..write('rowId: $rowId, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('followedAt: $followedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, actorUrl, followedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FollowingTableData &&
          other.rowId == this.rowId &&
          other.actorUrl == this.actorUrl &&
          other.followedAt == this.followedAt);
}

class FollowingTableCompanion extends UpdateCompanion<FollowingTableData> {
  final Value<int> rowId;
  final Value<String> actorUrl;
  final Value<DateTime> followedAt;
  const FollowingTableCompanion({
    this.rowId = const Value.absent(),
    this.actorUrl = const Value.absent(),
    this.followedAt = const Value.absent(),
  });
  FollowingTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String actorUrl,
    this.followedAt = const Value.absent(),
  }) : actorUrl = Value(actorUrl);
  static Insertable<FollowingTableData> custom({
    Expression<int>? rowId,
    Expression<String>? actorUrl,
    Expression<DateTime>? followedAt,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (actorUrl != null) 'actor_url': actorUrl,
      if (followedAt != null) 'followed_at': followedAt,
    });
  }

  FollowingTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? actorUrl,
    Value<DateTime>? followedAt,
  }) {
    return FollowingTableCompanion(
      rowId: rowId ?? this.rowId,
      actorUrl: actorUrl ?? this.actorUrl,
      followedAt: followedAt ?? this.followedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (actorUrl.present) {
      map['actor_url'] = Variable<String>(actorUrl.value);
    }
    if (followedAt.present) {
      map['followed_at'] = Variable<DateTime>(followedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowingTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('followedAt: $followedAt')
          ..write(')'))
        .toString();
  }
}

class $DefederatedNodesTableTable extends DefederatedNodesTable
    with TableInfo<$DefederatedNodesTableTable, DefederatedNodesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DefederatedNodesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _blockedAtMeta = const VerificationMeta(
    'blockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> blockedAt = GeneratedColumn<DateTime>(
    'blocked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [rowId, domain, blockedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'defederated_nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<DefederatedNodesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
    }
    if (data.containsKey('blocked_at')) {
      context.handle(
        _blockedAtMeta,
        blockedAt.isAcceptableOrUnknown(data['blocked_at']!, _blockedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  DefederatedNodesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DefederatedNodesTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      blockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}blocked_at'],
      )!,
    );
  }

  @override
  $DefederatedNodesTableTable createAlias(String alias) {
    return $DefederatedNodesTableTable(attachedDatabase, alias);
  }
}

class DefederatedNodesTableData extends DataClass
    implements Insertable<DefederatedNodesTableData> {
  final int rowId;
  final String domain;
  final DateTime blockedAt;
  const DefederatedNodesTableData({
    required this.rowId,
    required this.domain,
    required this.blockedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['domain'] = Variable<String>(domain);
    map['blocked_at'] = Variable<DateTime>(blockedAt);
    return map;
  }

  DefederatedNodesTableCompanion toCompanion(bool nullToAbsent) {
    return DefederatedNodesTableCompanion(
      rowId: Value(rowId),
      domain: Value(domain),
      blockedAt: Value(blockedAt),
    );
  }

  factory DefederatedNodesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DefederatedNodesTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      domain: serializer.fromJson<String>(json['domain']),
      blockedAt: serializer.fromJson<DateTime>(json['blockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'domain': serializer.toJson<String>(domain),
      'blockedAt': serializer.toJson<DateTime>(blockedAt),
    };
  }

  DefederatedNodesTableData copyWith({
    int? rowId,
    String? domain,
    DateTime? blockedAt,
  }) => DefederatedNodesTableData(
    rowId: rowId ?? this.rowId,
    domain: domain ?? this.domain,
    blockedAt: blockedAt ?? this.blockedAt,
  );
  DefederatedNodesTableData copyWithCompanion(
    DefederatedNodesTableCompanion data,
  ) {
    return DefederatedNodesTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      domain: data.domain.present ? data.domain.value : this.domain,
      blockedAt: data.blockedAt.present ? data.blockedAt.value : this.blockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DefederatedNodesTableData(')
          ..write('rowId: $rowId, ')
          ..write('domain: $domain, ')
          ..write('blockedAt: $blockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, domain, blockedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DefederatedNodesTableData &&
          other.rowId == this.rowId &&
          other.domain == this.domain &&
          other.blockedAt == this.blockedAt);
}

class DefederatedNodesTableCompanion
    extends UpdateCompanion<DefederatedNodesTableData> {
  final Value<int> rowId;
  final Value<String> domain;
  final Value<DateTime> blockedAt;
  const DefederatedNodesTableCompanion({
    this.rowId = const Value.absent(),
    this.domain = const Value.absent(),
    this.blockedAt = const Value.absent(),
  });
  DefederatedNodesTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String domain,
    this.blockedAt = const Value.absent(),
  }) : domain = Value(domain);
  static Insertable<DefederatedNodesTableData> custom({
    Expression<int>? rowId,
    Expression<String>? domain,
    Expression<DateTime>? blockedAt,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (domain != null) 'domain': domain,
      if (blockedAt != null) 'blocked_at': blockedAt,
    });
  }

  DefederatedNodesTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? domain,
    Value<DateTime>? blockedAt,
  }) {
    return DefederatedNodesTableCompanion(
      rowId: rowId ?? this.rowId,
      domain: domain ?? this.domain,
      blockedAt: blockedAt ?? this.blockedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (blockedAt.present) {
      map['blocked_at'] = Variable<DateTime>(blockedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DefederatedNodesTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('domain: $domain, ')
          ..write('blockedAt: $blockedAt')
          ..write(')'))
        .toString();
  }
}

class $NodeAllowDenyListTableTable extends NodeAllowDenyListTable
    with TableInfo<$NodeAllowDenyListTableTable, NodeAllowDenyListTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodeAllowDenyListTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _policyMeta = const VerificationMeta('policy');
  @override
  late final GeneratedColumn<String> policy = GeneratedColumn<String>(
    'policy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [rowId, domain, policy, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'node_allow_deny_list';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeAllowDenyListTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
    }
    if (data.containsKey('policy')) {
      context.handle(
        _policyMeta,
        policy.isAcceptableOrUnknown(data['policy']!, _policyMeta),
      );
    } else if (isInserting) {
      context.missing(_policyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  NodeAllowDenyListTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeAllowDenyListTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      policy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}policy'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $NodeAllowDenyListTableTable createAlias(String alias) {
    return $NodeAllowDenyListTableTable(attachedDatabase, alias);
  }
}

class NodeAllowDenyListTableData extends DataClass
    implements Insertable<NodeAllowDenyListTableData> {
  final int rowId;
  final String domain;
  final String policy;
  final DateTime createdAt;
  const NodeAllowDenyListTableData({
    required this.rowId,
    required this.domain,
    required this.policy,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['domain'] = Variable<String>(domain);
    map['policy'] = Variable<String>(policy);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NodeAllowDenyListTableCompanion toCompanion(bool nullToAbsent) {
    return NodeAllowDenyListTableCompanion(
      rowId: Value(rowId),
      domain: Value(domain),
      policy: Value(policy),
      createdAt: Value(createdAt),
    );
  }

  factory NodeAllowDenyListTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeAllowDenyListTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      domain: serializer.fromJson<String>(json['domain']),
      policy: serializer.fromJson<String>(json['policy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'domain': serializer.toJson<String>(domain),
      'policy': serializer.toJson<String>(policy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NodeAllowDenyListTableData copyWith({
    int? rowId,
    String? domain,
    String? policy,
    DateTime? createdAt,
  }) => NodeAllowDenyListTableData(
    rowId: rowId ?? this.rowId,
    domain: domain ?? this.domain,
    policy: policy ?? this.policy,
    createdAt: createdAt ?? this.createdAt,
  );
  NodeAllowDenyListTableData copyWithCompanion(
    NodeAllowDenyListTableCompanion data,
  ) {
    return NodeAllowDenyListTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      domain: data.domain.present ? data.domain.value : this.domain,
      policy: data.policy.present ? data.policy.value : this.policy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeAllowDenyListTableData(')
          ..write('rowId: $rowId, ')
          ..write('domain: $domain, ')
          ..write('policy: $policy, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, domain, policy, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeAllowDenyListTableData &&
          other.rowId == this.rowId &&
          other.domain == this.domain &&
          other.policy == this.policy &&
          other.createdAt == this.createdAt);
}

class NodeAllowDenyListTableCompanion
    extends UpdateCompanion<NodeAllowDenyListTableData> {
  final Value<int> rowId;
  final Value<String> domain;
  final Value<String> policy;
  final Value<DateTime> createdAt;
  const NodeAllowDenyListTableCompanion({
    this.rowId = const Value.absent(),
    this.domain = const Value.absent(),
    this.policy = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  NodeAllowDenyListTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String domain,
    required String policy,
    this.createdAt = const Value.absent(),
  }) : domain = Value(domain),
       policy = Value(policy);
  static Insertable<NodeAllowDenyListTableData> custom({
    Expression<int>? rowId,
    Expression<String>? domain,
    Expression<String>? policy,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (domain != null) 'domain': domain,
      if (policy != null) 'policy': policy,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  NodeAllowDenyListTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? domain,
    Value<String>? policy,
    Value<DateTime>? createdAt,
  }) {
    return NodeAllowDenyListTableCompanion(
      rowId: rowId ?? this.rowId,
      domain: domain ?? this.domain,
      policy: policy ?? this.policy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (policy.present) {
      map['policy'] = Variable<String>(policy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodeAllowDenyListTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('domain: $domain, ')
          ..write('policy: $policy, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MigrationTokensTableTable extends MigrationTokensTable
    with TableInfo<$MigrationTokensTableTable, MigrationTokensTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MigrationTokensTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tokenHashMeta = const VerificationMeta(
    'tokenHash',
  );
  @override
  late final GeneratedColumn<String> tokenHash = GeneratedColumn<String>(
    'token_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _newActorUrlMeta = const VerificationMeta(
    'newActorUrl',
  );
  @override
  late final GeneratedColumn<String> newActorUrl = GeneratedColumn<String>(
    'new_actor_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usedAtMeta = const VerificationMeta('usedAt');
  @override
  late final GeneratedColumn<DateTime> usedAt = GeneratedColumn<DateTime>(
    'used_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    tokenHash,
    newActorUrl,
    usedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'migration_tokens';
  @override
  VerificationContext validateIntegrity(
    Insertable<MigrationTokensTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('token_hash')) {
      context.handle(
        _tokenHashMeta,
        tokenHash.isAcceptableOrUnknown(data['token_hash']!, _tokenHashMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenHashMeta);
    }
    if (data.containsKey('new_actor_url')) {
      context.handle(
        _newActorUrlMeta,
        newActorUrl.isAcceptableOrUnknown(
          data['new_actor_url']!,
          _newActorUrlMeta,
        ),
      );
    }
    if (data.containsKey('used_at')) {
      context.handle(
        _usedAtMeta,
        usedAt.isAcceptableOrUnknown(data['used_at']!, _usedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  MigrationTokensTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MigrationTokensTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      tokenHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token_hash'],
      )!,
      newActorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_actor_url'],
      ),
      usedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}used_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MigrationTokensTableTable createAlias(String alias) {
    return $MigrationTokensTableTable(attachedDatabase, alias);
  }
}

class MigrationTokensTableData extends DataClass
    implements Insertable<MigrationTokensTableData> {
  final int rowId;
  final String tokenHash;
  final String? newActorUrl;
  final DateTime? usedAt;
  final DateTime createdAt;
  const MigrationTokensTableData({
    required this.rowId,
    required this.tokenHash,
    this.newActorUrl,
    this.usedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['token_hash'] = Variable<String>(tokenHash);
    if (!nullToAbsent || newActorUrl != null) {
      map['new_actor_url'] = Variable<String>(newActorUrl);
    }
    if (!nullToAbsent || usedAt != null) {
      map['used_at'] = Variable<DateTime>(usedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MigrationTokensTableCompanion toCompanion(bool nullToAbsent) {
    return MigrationTokensTableCompanion(
      rowId: Value(rowId),
      tokenHash: Value(tokenHash),
      newActorUrl: newActorUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(newActorUrl),
      usedAt: usedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(usedAt),
      createdAt: Value(createdAt),
    );
  }

  factory MigrationTokensTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MigrationTokensTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      tokenHash: serializer.fromJson<String>(json['tokenHash']),
      newActorUrl: serializer.fromJson<String?>(json['newActorUrl']),
      usedAt: serializer.fromJson<DateTime?>(json['usedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'tokenHash': serializer.toJson<String>(tokenHash),
      'newActorUrl': serializer.toJson<String?>(newActorUrl),
      'usedAt': serializer.toJson<DateTime?>(usedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MigrationTokensTableData copyWith({
    int? rowId,
    String? tokenHash,
    Value<String?> newActorUrl = const Value.absent(),
    Value<DateTime?> usedAt = const Value.absent(),
    DateTime? createdAt,
  }) => MigrationTokensTableData(
    rowId: rowId ?? this.rowId,
    tokenHash: tokenHash ?? this.tokenHash,
    newActorUrl: newActorUrl.present ? newActorUrl.value : this.newActorUrl,
    usedAt: usedAt.present ? usedAt.value : this.usedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  MigrationTokensTableData copyWithCompanion(
    MigrationTokensTableCompanion data,
  ) {
    return MigrationTokensTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      tokenHash: data.tokenHash.present ? data.tokenHash.value : this.tokenHash,
      newActorUrl: data.newActorUrl.present
          ? data.newActorUrl.value
          : this.newActorUrl,
      usedAt: data.usedAt.present ? data.usedAt.value : this.usedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MigrationTokensTableData(')
          ..write('rowId: $rowId, ')
          ..write('tokenHash: $tokenHash, ')
          ..write('newActorUrl: $newActorUrl, ')
          ..write('usedAt: $usedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(rowId, tokenHash, newActorUrl, usedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MigrationTokensTableData &&
          other.rowId == this.rowId &&
          other.tokenHash == this.tokenHash &&
          other.newActorUrl == this.newActorUrl &&
          other.usedAt == this.usedAt &&
          other.createdAt == this.createdAt);
}

class MigrationTokensTableCompanion
    extends UpdateCompanion<MigrationTokensTableData> {
  final Value<int> rowId;
  final Value<String> tokenHash;
  final Value<String?> newActorUrl;
  final Value<DateTime?> usedAt;
  final Value<DateTime> createdAt;
  const MigrationTokensTableCompanion({
    this.rowId = const Value.absent(),
    this.tokenHash = const Value.absent(),
    this.newActorUrl = const Value.absent(),
    this.usedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MigrationTokensTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String tokenHash,
    this.newActorUrl = const Value.absent(),
    this.usedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : tokenHash = Value(tokenHash);
  static Insertable<MigrationTokensTableData> custom({
    Expression<int>? rowId,
    Expression<String>? tokenHash,
    Expression<String>? newActorUrl,
    Expression<DateTime>? usedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (tokenHash != null) 'token_hash': tokenHash,
      if (newActorUrl != null) 'new_actor_url': newActorUrl,
      if (usedAt != null) 'used_at': usedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MigrationTokensTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? tokenHash,
    Value<String?>? newActorUrl,
    Value<DateTime?>? usedAt,
    Value<DateTime>? createdAt,
  }) {
    return MigrationTokensTableCompanion(
      rowId: rowId ?? this.rowId,
      tokenHash: tokenHash ?? this.tokenHash,
      newActorUrl: newActorUrl ?? this.newActorUrl,
      usedAt: usedAt ?? this.usedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (tokenHash.present) {
      map['token_hash'] = Variable<String>(tokenHash.value);
    }
    if (newActorUrl.present) {
      map['new_actor_url'] = Variable<String>(newActorUrl.value);
    }
    if (usedAt.present) {
      map['used_at'] = Variable<DateTime>(usedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MigrationTokensTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('tokenHash: $tokenHash, ')
          ..write('newActorUrl: $newActorUrl, ')
          ..write('usedAt: $usedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RemoteLibrariesTableTable extends RemoteLibrariesTable
    with TableInfo<$RemoteLibrariesTableTable, RemoteLibrariesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteLibrariesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _actorUrlMeta = const VerificationMeta(
    'actorUrl',
  );
  @override
  late final GeneratedColumn<String> actorUrl = GeneratedColumn<String>(
    'actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionJsonMeta = const VerificationMeta(
    'collectionJson',
  );
  @override
  late final GeneratedColumn<String> collectionJson = GeneratedColumn<String>(
    'collection_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    actorUrl,
    collectionJson,
    fetchedAt,
    etag,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_libraries';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemoteLibrariesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('actor_url')) {
      context.handle(
        _actorUrlMeta,
        actorUrl.isAcceptableOrUnknown(data['actor_url']!, _actorUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_actorUrlMeta);
    }
    if (data.containsKey('collection_json')) {
      context.handle(
        _collectionJsonMeta,
        collectionJson.isAcceptableOrUnknown(
          data['collection_json']!,
          _collectionJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actorUrl};
  @override
  RemoteLibrariesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteLibrariesTableData(
      actorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_url'],
      )!,
      collectionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
    );
  }

  @override
  $RemoteLibrariesTableTable createAlias(String alias) {
    return $RemoteLibrariesTableTable(attachedDatabase, alias);
  }
}

class RemoteLibrariesTableData extends DataClass
    implements Insertable<RemoteLibrariesTableData> {
  final String actorUrl;
  final String collectionJson;
  final DateTime fetchedAt;
  final String? etag;
  const RemoteLibrariesTableData({
    required this.actorUrl,
    required this.collectionJson,
    required this.fetchedAt,
    this.etag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['actor_url'] = Variable<String>(actorUrl);
    map['collection_json'] = Variable<String>(collectionJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    return map;
  }

  RemoteLibrariesTableCompanion toCompanion(bool nullToAbsent) {
    return RemoteLibrariesTableCompanion(
      actorUrl: Value(actorUrl),
      collectionJson: Value(collectionJson),
      fetchedAt: Value(fetchedAt),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
    );
  }

  factory RemoteLibrariesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteLibrariesTableData(
      actorUrl: serializer.fromJson<String>(json['actorUrl']),
      collectionJson: serializer.fromJson<String>(json['collectionJson']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      etag: serializer.fromJson<String?>(json['etag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actorUrl': serializer.toJson<String>(actorUrl),
      'collectionJson': serializer.toJson<String>(collectionJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'etag': serializer.toJson<String?>(etag),
    };
  }

  RemoteLibrariesTableData copyWith({
    String? actorUrl,
    String? collectionJson,
    DateTime? fetchedAt,
    Value<String?> etag = const Value.absent(),
  }) => RemoteLibrariesTableData(
    actorUrl: actorUrl ?? this.actorUrl,
    collectionJson: collectionJson ?? this.collectionJson,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    etag: etag.present ? etag.value : this.etag,
  );
  RemoteLibrariesTableData copyWithCompanion(
    RemoteLibrariesTableCompanion data,
  ) {
    return RemoteLibrariesTableData(
      actorUrl: data.actorUrl.present ? data.actorUrl.value : this.actorUrl,
      collectionJson: data.collectionJson.present
          ? data.collectionJson.value
          : this.collectionJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      etag: data.etag.present ? data.etag.value : this.etag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteLibrariesTableData(')
          ..write('actorUrl: $actorUrl, ')
          ..write('collectionJson: $collectionJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('etag: $etag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(actorUrl, collectionJson, fetchedAt, etag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteLibrariesTableData &&
          other.actorUrl == this.actorUrl &&
          other.collectionJson == this.collectionJson &&
          other.fetchedAt == this.fetchedAt &&
          other.etag == this.etag);
}

class RemoteLibrariesTableCompanion
    extends UpdateCompanion<RemoteLibrariesTableData> {
  final Value<String> actorUrl;
  final Value<String> collectionJson;
  final Value<DateTime> fetchedAt;
  final Value<String?> etag;
  final Value<int> rowid;
  const RemoteLibrariesTableCompanion({
    this.actorUrl = const Value.absent(),
    this.collectionJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemoteLibrariesTableCompanion.insert({
    required String actorUrl,
    required String collectionJson,
    this.fetchedAt = const Value.absent(),
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : actorUrl = Value(actorUrl),
       collectionJson = Value(collectionJson);
  static Insertable<RemoteLibrariesTableData> custom({
    Expression<String>? actorUrl,
    Expression<String>? collectionJson,
    Expression<DateTime>? fetchedAt,
    Expression<String>? etag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (actorUrl != null) 'actor_url': actorUrl,
      if (collectionJson != null) 'collection_json': collectionJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (etag != null) 'etag': etag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemoteLibrariesTableCompanion copyWith({
    Value<String>? actorUrl,
    Value<String>? collectionJson,
    Value<DateTime>? fetchedAt,
    Value<String?>? etag,
    Value<int>? rowid,
  }) {
    return RemoteLibrariesTableCompanion(
      actorUrl: actorUrl ?? this.actorUrl,
      collectionJson: collectionJson ?? this.collectionJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      etag: etag ?? this.etag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actorUrl.present) {
      map['actor_url'] = Variable<String>(actorUrl.value);
    }
    if (collectionJson.present) {
      map['collection_json'] = Variable<String>(collectionJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteLibrariesTableCompanion(')
          ..write('actorUrl: $actorUrl, ')
          ..write('collectionJson: $collectionJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('etag: $etag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AudioCacheTableTable extends AudioCacheTable
    with TableInfo<$AudioCacheTableTable, AudioCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceActorUrlMeta = const VerificationMeta(
    'sourceActorUrl',
  );
  @override
  late final GeneratedColumn<String> sourceActorUrl = GeneratedColumn<String>(
    'source_actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastAccessedMeta = const VerificationMeta(
    'lastAccessed',
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessed = GeneratedColumn<DateTime>(
    'last_accessed',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    trackId,
    sourceActorUrl,
    localPath,
    fetchedAt,
    lastAccessed,
    sizeBytes,
    isPinned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioCacheTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('source_actor_url')) {
      context.handle(
        _sourceActorUrlMeta,
        sourceActorUrl.isAcceptableOrUnknown(
          data['source_actor_url']!,
          _sourceActorUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceActorUrlMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    if (data.containsKey('last_accessed')) {
      context.handle(
        _lastAccessedMeta,
        lastAccessed.isAcceptableOrUnknown(
          data['last_accessed']!,
          _lastAccessedMeta,
        ),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId, sourceActorUrl};
  @override
  AudioCacheTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioCacheTableData(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      sourceActorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_actor_url'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      lastAccessed: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
    );
  }

  @override
  $AudioCacheTableTable createAlias(String alias) {
    return $AudioCacheTableTable(attachedDatabase, alias);
  }
}

class AudioCacheTableData extends DataClass
    implements Insertable<AudioCacheTableData> {
  final String trackId;
  final String sourceActorUrl;
  final String localPath;
  final DateTime fetchedAt;
  final DateTime lastAccessed;
  final int sizeBytes;
  final bool isPinned;
  const AudioCacheTableData({
    required this.trackId,
    required this.sourceActorUrl,
    required this.localPath,
    required this.fetchedAt,
    required this.lastAccessed,
    required this.sizeBytes,
    required this.isPinned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<String>(trackId);
    map['source_actor_url'] = Variable<String>(sourceActorUrl);
    map['local_path'] = Variable<String>(localPath);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['last_accessed'] = Variable<DateTime>(lastAccessed);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['is_pinned'] = Variable<bool>(isPinned);
    return map;
  }

  AudioCacheTableCompanion toCompanion(bool nullToAbsent) {
    return AudioCacheTableCompanion(
      trackId: Value(trackId),
      sourceActorUrl: Value(sourceActorUrl),
      localPath: Value(localPath),
      fetchedAt: Value(fetchedAt),
      lastAccessed: Value(lastAccessed),
      sizeBytes: Value(sizeBytes),
      isPinned: Value(isPinned),
    );
  }

  factory AudioCacheTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioCacheTableData(
      trackId: serializer.fromJson<String>(json['trackId']),
      sourceActorUrl: serializer.fromJson<String>(json['sourceActorUrl']),
      localPath: serializer.fromJson<String>(json['localPath']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      lastAccessed: serializer.fromJson<DateTime>(json['lastAccessed']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<String>(trackId),
      'sourceActorUrl': serializer.toJson<String>(sourceActorUrl),
      'localPath': serializer.toJson<String>(localPath),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'lastAccessed': serializer.toJson<DateTime>(lastAccessed),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'isPinned': serializer.toJson<bool>(isPinned),
    };
  }

  AudioCacheTableData copyWith({
    String? trackId,
    String? sourceActorUrl,
    String? localPath,
    DateTime? fetchedAt,
    DateTime? lastAccessed,
    int? sizeBytes,
    bool? isPinned,
  }) => AudioCacheTableData(
    trackId: trackId ?? this.trackId,
    sourceActorUrl: sourceActorUrl ?? this.sourceActorUrl,
    localPath: localPath ?? this.localPath,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    lastAccessed: lastAccessed ?? this.lastAccessed,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    isPinned: isPinned ?? this.isPinned,
  );
  AudioCacheTableData copyWithCompanion(AudioCacheTableCompanion data) {
    return AudioCacheTableData(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      sourceActorUrl: data.sourceActorUrl.present
          ? data.sourceActorUrl.value
          : this.sourceActorUrl,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      lastAccessed: data.lastAccessed.present
          ? data.lastAccessed.value
          : this.lastAccessed,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioCacheTableData(')
          ..write('trackId: $trackId, ')
          ..write('sourceActorUrl: $sourceActorUrl, ')
          ..write('localPath: $localPath, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('lastAccessed: $lastAccessed, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('isPinned: $isPinned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    trackId,
    sourceActorUrl,
    localPath,
    fetchedAt,
    lastAccessed,
    sizeBytes,
    isPinned,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioCacheTableData &&
          other.trackId == this.trackId &&
          other.sourceActorUrl == this.sourceActorUrl &&
          other.localPath == this.localPath &&
          other.fetchedAt == this.fetchedAt &&
          other.lastAccessed == this.lastAccessed &&
          other.sizeBytes == this.sizeBytes &&
          other.isPinned == this.isPinned);
}

class AudioCacheTableCompanion extends UpdateCompanion<AudioCacheTableData> {
  final Value<String> trackId;
  final Value<String> sourceActorUrl;
  final Value<String> localPath;
  final Value<DateTime> fetchedAt;
  final Value<DateTime> lastAccessed;
  final Value<int> sizeBytes;
  final Value<bool> isPinned;
  final Value<int> rowid;
  const AudioCacheTableCompanion({
    this.trackId = const Value.absent(),
    this.sourceActorUrl = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.lastAccessed = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudioCacheTableCompanion.insert({
    required String trackId,
    required String sourceActorUrl,
    required String localPath,
    this.fetchedAt = const Value.absent(),
    this.lastAccessed = const Value.absent(),
    required int sizeBytes,
    this.isPinned = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : trackId = Value(trackId),
       sourceActorUrl = Value(sourceActorUrl),
       localPath = Value(localPath),
       sizeBytes = Value(sizeBytes);
  static Insertable<AudioCacheTableData> custom({
    Expression<String>? trackId,
    Expression<String>? sourceActorUrl,
    Expression<String>? localPath,
    Expression<DateTime>? fetchedAt,
    Expression<DateTime>? lastAccessed,
    Expression<int>? sizeBytes,
    Expression<bool>? isPinned,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (sourceActorUrl != null) 'source_actor_url': sourceActorUrl,
      if (localPath != null) 'local_path': localPath,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (lastAccessed != null) 'last_accessed': lastAccessed,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (isPinned != null) 'is_pinned': isPinned,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudioCacheTableCompanion copyWith({
    Value<String>? trackId,
    Value<String>? sourceActorUrl,
    Value<String>? localPath,
    Value<DateTime>? fetchedAt,
    Value<DateTime>? lastAccessed,
    Value<int>? sizeBytes,
    Value<bool>? isPinned,
    Value<int>? rowid,
  }) {
    return AudioCacheTableCompanion(
      trackId: trackId ?? this.trackId,
      sourceActorUrl: sourceActorUrl ?? this.sourceActorUrl,
      localPath: localPath ?? this.localPath,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      isPinned: isPinned ?? this.isPinned,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (sourceActorUrl.present) {
      map['source_actor_url'] = Variable<String>(sourceActorUrl.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (lastAccessed.present) {
      map['last_accessed'] = Variable<DateTime>(lastAccessed.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioCacheTableCompanion(')
          ..write('trackId: $trackId, ')
          ..write('sourceActorUrl: $sourceActorUrl, ')
          ..write('localPath: $localPath, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('lastAccessed: $lastAccessed, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('isPinned: $isPinned, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListenActivitiesTableTable extends ListenActivitiesTable
    with TableInfo<$ListenActivitiesTableTable, ListenActivitiesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListenActivitiesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actorUrlMeta = const VerificationMeta(
    'actorUrl',
  );
  @override
  late final GeneratedColumn<String> actorUrl = GeneratedColumn<String>(
    'actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackTitleMeta = const VerificationMeta(
    'trackTitle',
  );
  @override
  late final GeneratedColumn<String> trackTitle = GeneratedColumn<String>(
    'track_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackArtistMeta = const VerificationMeta(
    'trackArtist',
  );
  @override
  late final GeneratedColumn<String> trackArtist = GeneratedColumn<String>(
    'track_artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listenedAtMeta = const VerificationMeta(
    'listenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> listenedAt = GeneratedColumn<DateTime>(
    'listened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    actorUrl,
    trackId,
    trackTitle,
    trackArtist,
    listenedAt,
    durationMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listen_activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListenActivitiesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('actor_url')) {
      context.handle(
        _actorUrlMeta,
        actorUrl.isAcceptableOrUnknown(data['actor_url']!, _actorUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_actorUrlMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('track_title')) {
      context.handle(
        _trackTitleMeta,
        trackTitle.isAcceptableOrUnknown(data['track_title']!, _trackTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_trackTitleMeta);
    }
    if (data.containsKey('track_artist')) {
      context.handle(
        _trackArtistMeta,
        trackArtist.isAcceptableOrUnknown(
          data['track_artist']!,
          _trackArtistMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackArtistMeta);
    }
    if (data.containsKey('listened_at')) {
      context.handle(
        _listenedAtMeta,
        listenedAt.isAcceptableOrUnknown(data['listened_at']!, _listenedAtMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  ListenActivitiesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListenActivitiesTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      actorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_url'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      trackTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_title'],
      )!,
      trackArtist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_artist'],
      )!,
      listenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}listened_at'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
    );
  }

  @override
  $ListenActivitiesTableTable createAlias(String alias) {
    return $ListenActivitiesTableTable(attachedDatabase, alias);
  }
}

class ListenActivitiesTableData extends DataClass
    implements Insertable<ListenActivitiesTableData> {
  final int rowId;
  final String actorUrl;
  final String trackId;
  final String trackTitle;
  final String trackArtist;
  final DateTime listenedAt;
  final int durationMs;
  const ListenActivitiesTableData({
    required this.rowId,
    required this.actorUrl,
    required this.trackId,
    required this.trackTitle,
    required this.trackArtist,
    required this.listenedAt,
    required this.durationMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['actor_url'] = Variable<String>(actorUrl);
    map['track_id'] = Variable<String>(trackId);
    map['track_title'] = Variable<String>(trackTitle);
    map['track_artist'] = Variable<String>(trackArtist);
    map['listened_at'] = Variable<DateTime>(listenedAt);
    map['duration_ms'] = Variable<int>(durationMs);
    return map;
  }

  ListenActivitiesTableCompanion toCompanion(bool nullToAbsent) {
    return ListenActivitiesTableCompanion(
      rowId: Value(rowId),
      actorUrl: Value(actorUrl),
      trackId: Value(trackId),
      trackTitle: Value(trackTitle),
      trackArtist: Value(trackArtist),
      listenedAt: Value(listenedAt),
      durationMs: Value(durationMs),
    );
  }

  factory ListenActivitiesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListenActivitiesTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      actorUrl: serializer.fromJson<String>(json['actorUrl']),
      trackId: serializer.fromJson<String>(json['trackId']),
      trackTitle: serializer.fromJson<String>(json['trackTitle']),
      trackArtist: serializer.fromJson<String>(json['trackArtist']),
      listenedAt: serializer.fromJson<DateTime>(json['listenedAt']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'actorUrl': serializer.toJson<String>(actorUrl),
      'trackId': serializer.toJson<String>(trackId),
      'trackTitle': serializer.toJson<String>(trackTitle),
      'trackArtist': serializer.toJson<String>(trackArtist),
      'listenedAt': serializer.toJson<DateTime>(listenedAt),
      'durationMs': serializer.toJson<int>(durationMs),
    };
  }

  ListenActivitiesTableData copyWith({
    int? rowId,
    String? actorUrl,
    String? trackId,
    String? trackTitle,
    String? trackArtist,
    DateTime? listenedAt,
    int? durationMs,
  }) => ListenActivitiesTableData(
    rowId: rowId ?? this.rowId,
    actorUrl: actorUrl ?? this.actorUrl,
    trackId: trackId ?? this.trackId,
    trackTitle: trackTitle ?? this.trackTitle,
    trackArtist: trackArtist ?? this.trackArtist,
    listenedAt: listenedAt ?? this.listenedAt,
    durationMs: durationMs ?? this.durationMs,
  );
  ListenActivitiesTableData copyWithCompanion(
    ListenActivitiesTableCompanion data,
  ) {
    return ListenActivitiesTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      actorUrl: data.actorUrl.present ? data.actorUrl.value : this.actorUrl,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      trackTitle: data.trackTitle.present
          ? data.trackTitle.value
          : this.trackTitle,
      trackArtist: data.trackArtist.present
          ? data.trackArtist.value
          : this.trackArtist,
      listenedAt: data.listenedAt.present
          ? data.listenedAt.value
          : this.listenedAt,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListenActivitiesTableData(')
          ..write('rowId: $rowId, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('trackId: $trackId, ')
          ..write('trackTitle: $trackTitle, ')
          ..write('trackArtist: $trackArtist, ')
          ..write('listenedAt: $listenedAt, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    actorUrl,
    trackId,
    trackTitle,
    trackArtist,
    listenedAt,
    durationMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListenActivitiesTableData &&
          other.rowId == this.rowId &&
          other.actorUrl == this.actorUrl &&
          other.trackId == this.trackId &&
          other.trackTitle == this.trackTitle &&
          other.trackArtist == this.trackArtist &&
          other.listenedAt == this.listenedAt &&
          other.durationMs == this.durationMs);
}

class ListenActivitiesTableCompanion
    extends UpdateCompanion<ListenActivitiesTableData> {
  final Value<int> rowId;
  final Value<String> actorUrl;
  final Value<String> trackId;
  final Value<String> trackTitle;
  final Value<String> trackArtist;
  final Value<DateTime> listenedAt;
  final Value<int> durationMs;
  const ListenActivitiesTableCompanion({
    this.rowId = const Value.absent(),
    this.actorUrl = const Value.absent(),
    this.trackId = const Value.absent(),
    this.trackTitle = const Value.absent(),
    this.trackArtist = const Value.absent(),
    this.listenedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
  });
  ListenActivitiesTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String actorUrl,
    required String trackId,
    required String trackTitle,
    required String trackArtist,
    this.listenedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
  }) : actorUrl = Value(actorUrl),
       trackId = Value(trackId),
       trackTitle = Value(trackTitle),
       trackArtist = Value(trackArtist);
  static Insertable<ListenActivitiesTableData> custom({
    Expression<int>? rowId,
    Expression<String>? actorUrl,
    Expression<String>? trackId,
    Expression<String>? trackTitle,
    Expression<String>? trackArtist,
    Expression<DateTime>? listenedAt,
    Expression<int>? durationMs,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (actorUrl != null) 'actor_url': actorUrl,
      if (trackId != null) 'track_id': trackId,
      if (trackTitle != null) 'track_title': trackTitle,
      if (trackArtist != null) 'track_artist': trackArtist,
      if (listenedAt != null) 'listened_at': listenedAt,
      if (durationMs != null) 'duration_ms': durationMs,
    });
  }

  ListenActivitiesTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? actorUrl,
    Value<String>? trackId,
    Value<String>? trackTitle,
    Value<String>? trackArtist,
    Value<DateTime>? listenedAt,
    Value<int>? durationMs,
  }) {
    return ListenActivitiesTableCompanion(
      rowId: rowId ?? this.rowId,
      actorUrl: actorUrl ?? this.actorUrl,
      trackId: trackId ?? this.trackId,
      trackTitle: trackTitle ?? this.trackTitle,
      trackArtist: trackArtist ?? this.trackArtist,
      listenedAt: listenedAt ?? this.listenedAt,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (actorUrl.present) {
      map['actor_url'] = Variable<String>(actorUrl.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (trackTitle.present) {
      map['track_title'] = Variable<String>(trackTitle.value);
    }
    if (trackArtist.present) {
      map['track_artist'] = Variable<String>(trackArtist.value);
    }
    if (listenedAt.present) {
      map['listened_at'] = Variable<DateTime>(listenedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListenActivitiesTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('trackId: $trackId, ')
          ..write('trackTitle: $trackTitle, ')
          ..write('trackArtist: $trackArtist, ')
          ..write('listenedAt: $listenedAt, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }
}

class $FingerprintsTableTable extends FingerprintsTable
    with TableInfo<$FingerprintsTableTable, FingerprintsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FingerprintsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chromaprintHashMeta = const VerificationMeta(
    'chromaprintHash',
  );
  @override
  late final GeneratedColumn<String> chromaprintHash = GeneratedColumn<String>(
    'chromaprint_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _computedAtMeta = const VerificationMeta(
    'computedAt',
  );
  @override
  late final GeneratedColumn<DateTime> computedAt = GeneratedColumn<DateTime>(
    'computed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    trackId,
    chromaprintHash,
    durationMs,
    computedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fingerprints';
  @override
  VerificationContext validateIntegrity(
    Insertable<FingerprintsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('chromaprint_hash')) {
      context.handle(
        _chromaprintHashMeta,
        chromaprintHash.isAcceptableOrUnknown(
          data['chromaprint_hash']!,
          _chromaprintHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chromaprintHashMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('computed_at')) {
      context.handle(
        _computedAtMeta,
        computedAt.isAcceptableOrUnknown(data['computed_at']!, _computedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId};
  @override
  FingerprintsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FingerprintsTableData(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      chromaprintHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chromaprint_hash'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      computedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}computed_at'],
      )!,
    );
  }

  @override
  $FingerprintsTableTable createAlias(String alias) {
    return $FingerprintsTableTable(attachedDatabase, alias);
  }
}

class FingerprintsTableData extends DataClass
    implements Insertable<FingerprintsTableData> {
  final int trackId;
  final String chromaprintHash;
  final int durationMs;
  final DateTime computedAt;
  const FingerprintsTableData({
    required this.trackId,
    required this.chromaprintHash,
    required this.durationMs,
    required this.computedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<int>(trackId);
    map['chromaprint_hash'] = Variable<String>(chromaprintHash);
    map['duration_ms'] = Variable<int>(durationMs);
    map['computed_at'] = Variable<DateTime>(computedAt);
    return map;
  }

  FingerprintsTableCompanion toCompanion(bool nullToAbsent) {
    return FingerprintsTableCompanion(
      trackId: Value(trackId),
      chromaprintHash: Value(chromaprintHash),
      durationMs: Value(durationMs),
      computedAt: Value(computedAt),
    );
  }

  factory FingerprintsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FingerprintsTableData(
      trackId: serializer.fromJson<int>(json['trackId']),
      chromaprintHash: serializer.fromJson<String>(json['chromaprintHash']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      computedAt: serializer.fromJson<DateTime>(json['computedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'chromaprintHash': serializer.toJson<String>(chromaprintHash),
      'durationMs': serializer.toJson<int>(durationMs),
      'computedAt': serializer.toJson<DateTime>(computedAt),
    };
  }

  FingerprintsTableData copyWith({
    int? trackId,
    String? chromaprintHash,
    int? durationMs,
    DateTime? computedAt,
  }) => FingerprintsTableData(
    trackId: trackId ?? this.trackId,
    chromaprintHash: chromaprintHash ?? this.chromaprintHash,
    durationMs: durationMs ?? this.durationMs,
    computedAt: computedAt ?? this.computedAt,
  );
  FingerprintsTableData copyWithCompanion(FingerprintsTableCompanion data) {
    return FingerprintsTableData(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      chromaprintHash: data.chromaprintHash.present
          ? data.chromaprintHash.value
          : this.chromaprintHash,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      computedAt: data.computedAt.present
          ? data.computedAt.value
          : this.computedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FingerprintsTableData(')
          ..write('trackId: $trackId, ')
          ..write('chromaprintHash: $chromaprintHash, ')
          ..write('durationMs: $durationMs, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(trackId, chromaprintHash, durationMs, computedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FingerprintsTableData &&
          other.trackId == this.trackId &&
          other.chromaprintHash == this.chromaprintHash &&
          other.durationMs == this.durationMs &&
          other.computedAt == this.computedAt);
}

class FingerprintsTableCompanion
    extends UpdateCompanion<FingerprintsTableData> {
  final Value<int> trackId;
  final Value<String> chromaprintHash;
  final Value<int> durationMs;
  final Value<DateTime> computedAt;
  const FingerprintsTableCompanion({
    this.trackId = const Value.absent(),
    this.chromaprintHash = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.computedAt = const Value.absent(),
  });
  FingerprintsTableCompanion.insert({
    this.trackId = const Value.absent(),
    required String chromaprintHash,
    required int durationMs,
    this.computedAt = const Value.absent(),
  }) : chromaprintHash = Value(chromaprintHash),
       durationMs = Value(durationMs);
  static Insertable<FingerprintsTableData> custom({
    Expression<int>? trackId,
    Expression<String>? chromaprintHash,
    Expression<int>? durationMs,
    Expression<DateTime>? computedAt,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (chromaprintHash != null) 'chromaprint_hash': chromaprintHash,
      if (durationMs != null) 'duration_ms': durationMs,
      if (computedAt != null) 'computed_at': computedAt,
    });
  }

  FingerprintsTableCompanion copyWith({
    Value<int>? trackId,
    Value<String>? chromaprintHash,
    Value<int>? durationMs,
    Value<DateTime>? computedAt,
  }) {
    return FingerprintsTableCompanion(
      trackId: trackId ?? this.trackId,
      chromaprintHash: chromaprintHash ?? this.chromaprintHash,
      durationMs: durationMs ?? this.durationMs,
      computedAt: computedAt ?? this.computedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (chromaprintHash.present) {
      map['chromaprint_hash'] = Variable<String>(chromaprintHash.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<DateTime>(computedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FingerprintsTableCompanion(')
          ..write('trackId: $trackId, ')
          ..write('chromaprintHash: $chromaprintHash, ')
          ..write('durationMs: $durationMs, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }
}

class $MergeProvenanceTableTable extends MergeProvenanceTable
    with TableInfo<$MergeProvenanceTableTable, MergeProvenanceTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MergeProvenanceTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fingerprintAMeta = const VerificationMeta(
    'fingerprintA',
  );
  @override
  late final GeneratedColumn<String> fingerprintA = GeneratedColumn<String>(
    'fingerprint_a',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fingerprintBMeta = const VerificationMeta(
    'fingerprintB',
  );
  @override
  late final GeneratedColumn<String> fingerprintB = GeneratedColumn<String>(
    'fingerprint_b',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _similarityScoreMeta = const VerificationMeta(
    'similarityScore',
  );
  @override
  late final GeneratedColumn<double> similarityScore = GeneratedColumn<double>(
    'similarity_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mergedAtMeta = const VerificationMeta(
    'mergedAt',
  );
  @override
  late final GeneratedColumn<DateTime> mergedAt = GeneratedColumn<DateTime>(
    'merged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _undoneAtMeta = const VerificationMeta(
    'undoneAt',
  );
  @override
  late final GeneratedColumn<DateTime> undoneAt = GeneratedColumn<DateTime>(
    'undone_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    fingerprintA,
    fingerprintB,
    similarityScore,
    mergedAt,
    undoneAt,
    reason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'merge_provenance';
  @override
  VerificationContext validateIntegrity(
    Insertable<MergeProvenanceTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('fingerprint_a')) {
      context.handle(
        _fingerprintAMeta,
        fingerprintA.isAcceptableOrUnknown(
          data['fingerprint_a']!,
          _fingerprintAMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintAMeta);
    }
    if (data.containsKey('fingerprint_b')) {
      context.handle(
        _fingerprintBMeta,
        fingerprintB.isAcceptableOrUnknown(
          data['fingerprint_b']!,
          _fingerprintBMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintBMeta);
    }
    if (data.containsKey('similarity_score')) {
      context.handle(
        _similarityScoreMeta,
        similarityScore.isAcceptableOrUnknown(
          data['similarity_score']!,
          _similarityScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_similarityScoreMeta);
    }
    if (data.containsKey('merged_at')) {
      context.handle(
        _mergedAtMeta,
        mergedAt.isAcceptableOrUnknown(data['merged_at']!, _mergedAtMeta),
      );
    }
    if (data.containsKey('undone_at')) {
      context.handle(
        _undoneAtMeta,
        undoneAt.isAcceptableOrUnknown(data['undone_at']!, _undoneAtMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  MergeProvenanceTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MergeProvenanceTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      fingerprintA: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint_a'],
      )!,
      fingerprintB: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint_b'],
      )!,
      similarityScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}similarity_score'],
      )!,
      mergedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}merged_at'],
      )!,
      undoneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}undone_at'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
    );
  }

  @override
  $MergeProvenanceTableTable createAlias(String alias) {
    return $MergeProvenanceTableTable(attachedDatabase, alias);
  }
}

class MergeProvenanceTableData extends DataClass
    implements Insertable<MergeProvenanceTableData> {
  final int rowId;
  final String fingerprintA;
  final String fingerprintB;
  final double similarityScore;
  final DateTime mergedAt;
  final DateTime? undoneAt;
  final String reason;
  const MergeProvenanceTableData({
    required this.rowId,
    required this.fingerprintA,
    required this.fingerprintB,
    required this.similarityScore,
    required this.mergedAt,
    this.undoneAt,
    required this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['fingerprint_a'] = Variable<String>(fingerprintA);
    map['fingerprint_b'] = Variable<String>(fingerprintB);
    map['similarity_score'] = Variable<double>(similarityScore);
    map['merged_at'] = Variable<DateTime>(mergedAt);
    if (!nullToAbsent || undoneAt != null) {
      map['undone_at'] = Variable<DateTime>(undoneAt);
    }
    map['reason'] = Variable<String>(reason);
    return map;
  }

  MergeProvenanceTableCompanion toCompanion(bool nullToAbsent) {
    return MergeProvenanceTableCompanion(
      rowId: Value(rowId),
      fingerprintA: Value(fingerprintA),
      fingerprintB: Value(fingerprintB),
      similarityScore: Value(similarityScore),
      mergedAt: Value(mergedAt),
      undoneAt: undoneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(undoneAt),
      reason: Value(reason),
    );
  }

  factory MergeProvenanceTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MergeProvenanceTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      fingerprintA: serializer.fromJson<String>(json['fingerprintA']),
      fingerprintB: serializer.fromJson<String>(json['fingerprintB']),
      similarityScore: serializer.fromJson<double>(json['similarityScore']),
      mergedAt: serializer.fromJson<DateTime>(json['mergedAt']),
      undoneAt: serializer.fromJson<DateTime?>(json['undoneAt']),
      reason: serializer.fromJson<String>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'fingerprintA': serializer.toJson<String>(fingerprintA),
      'fingerprintB': serializer.toJson<String>(fingerprintB),
      'similarityScore': serializer.toJson<double>(similarityScore),
      'mergedAt': serializer.toJson<DateTime>(mergedAt),
      'undoneAt': serializer.toJson<DateTime?>(undoneAt),
      'reason': serializer.toJson<String>(reason),
    };
  }

  MergeProvenanceTableData copyWith({
    int? rowId,
    String? fingerprintA,
    String? fingerprintB,
    double? similarityScore,
    DateTime? mergedAt,
    Value<DateTime?> undoneAt = const Value.absent(),
    String? reason,
  }) => MergeProvenanceTableData(
    rowId: rowId ?? this.rowId,
    fingerprintA: fingerprintA ?? this.fingerprintA,
    fingerprintB: fingerprintB ?? this.fingerprintB,
    similarityScore: similarityScore ?? this.similarityScore,
    mergedAt: mergedAt ?? this.mergedAt,
    undoneAt: undoneAt.present ? undoneAt.value : this.undoneAt,
    reason: reason ?? this.reason,
  );
  MergeProvenanceTableData copyWithCompanion(
    MergeProvenanceTableCompanion data,
  ) {
    return MergeProvenanceTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      fingerprintA: data.fingerprintA.present
          ? data.fingerprintA.value
          : this.fingerprintA,
      fingerprintB: data.fingerprintB.present
          ? data.fingerprintB.value
          : this.fingerprintB,
      similarityScore: data.similarityScore.present
          ? data.similarityScore.value
          : this.similarityScore,
      mergedAt: data.mergedAt.present ? data.mergedAt.value : this.mergedAt,
      undoneAt: data.undoneAt.present ? data.undoneAt.value : this.undoneAt,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MergeProvenanceTableData(')
          ..write('rowId: $rowId, ')
          ..write('fingerprintA: $fingerprintA, ')
          ..write('fingerprintB: $fingerprintB, ')
          ..write('similarityScore: $similarityScore, ')
          ..write('mergedAt: $mergedAt, ')
          ..write('undoneAt: $undoneAt, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    fingerprintA,
    fingerprintB,
    similarityScore,
    mergedAt,
    undoneAt,
    reason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MergeProvenanceTableData &&
          other.rowId == this.rowId &&
          other.fingerprintA == this.fingerprintA &&
          other.fingerprintB == this.fingerprintB &&
          other.similarityScore == this.similarityScore &&
          other.mergedAt == this.mergedAt &&
          other.undoneAt == this.undoneAt &&
          other.reason == this.reason);
}

class MergeProvenanceTableCompanion
    extends UpdateCompanion<MergeProvenanceTableData> {
  final Value<int> rowId;
  final Value<String> fingerprintA;
  final Value<String> fingerprintB;
  final Value<double> similarityScore;
  final Value<DateTime> mergedAt;
  final Value<DateTime?> undoneAt;
  final Value<String> reason;
  const MergeProvenanceTableCompanion({
    this.rowId = const Value.absent(),
    this.fingerprintA = const Value.absent(),
    this.fingerprintB = const Value.absent(),
    this.similarityScore = const Value.absent(),
    this.mergedAt = const Value.absent(),
    this.undoneAt = const Value.absent(),
    this.reason = const Value.absent(),
  });
  MergeProvenanceTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String fingerprintA,
    required String fingerprintB,
    required double similarityScore,
    this.mergedAt = const Value.absent(),
    this.undoneAt = const Value.absent(),
    required String reason,
  }) : fingerprintA = Value(fingerprintA),
       fingerprintB = Value(fingerprintB),
       similarityScore = Value(similarityScore),
       reason = Value(reason);
  static Insertable<MergeProvenanceTableData> custom({
    Expression<int>? rowId,
    Expression<String>? fingerprintA,
    Expression<String>? fingerprintB,
    Expression<double>? similarityScore,
    Expression<DateTime>? mergedAt,
    Expression<DateTime>? undoneAt,
    Expression<String>? reason,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (fingerprintA != null) 'fingerprint_a': fingerprintA,
      if (fingerprintB != null) 'fingerprint_b': fingerprintB,
      if (similarityScore != null) 'similarity_score': similarityScore,
      if (mergedAt != null) 'merged_at': mergedAt,
      if (undoneAt != null) 'undone_at': undoneAt,
      if (reason != null) 'reason': reason,
    });
  }

  MergeProvenanceTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? fingerprintA,
    Value<String>? fingerprintB,
    Value<double>? similarityScore,
    Value<DateTime>? mergedAt,
    Value<DateTime?>? undoneAt,
    Value<String>? reason,
  }) {
    return MergeProvenanceTableCompanion(
      rowId: rowId ?? this.rowId,
      fingerprintA: fingerprintA ?? this.fingerprintA,
      fingerprintB: fingerprintB ?? this.fingerprintB,
      similarityScore: similarityScore ?? this.similarityScore,
      mergedAt: mergedAt ?? this.mergedAt,
      undoneAt: undoneAt ?? this.undoneAt,
      reason: reason ?? this.reason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (fingerprintA.present) {
      map['fingerprint_a'] = Variable<String>(fingerprintA.value);
    }
    if (fingerprintB.present) {
      map['fingerprint_b'] = Variable<String>(fingerprintB.value);
    }
    if (similarityScore.present) {
      map['similarity_score'] = Variable<double>(similarityScore.value);
    }
    if (mergedAt.present) {
      map['merged_at'] = Variable<DateTime>(mergedAt.value);
    }
    if (undoneAt.present) {
      map['undone_at'] = Variable<DateTime>(undoneAt.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MergeProvenanceTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('fingerprintA: $fingerprintA, ')
          ..write('fingerprintB: $fingerprintB, ')
          ..write('similarityScore: $similarityScore, ')
          ..write('mergedAt: $mergedAt, ')
          ..write('undoneAt: $undoneAt, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }
}

class $FollowsTableTable extends FollowsTable
    with TableInfo<$FollowsTableTable, FollowsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FollowsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localActorIdMeta = const VerificationMeta(
    'localActorId',
  );
  @override
  late final GeneratedColumn<String> localActorId = GeneratedColumn<String>(
    'local_actor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteActorUrlMeta = const VerificationMeta(
    'remoteActorUrl',
  );
  @override
  late final GeneratedColumn<String> remoteActorUrl = GeneratedColumn<String>(
    'remote_actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('accepted'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    localActorId,
    remoteActorUrl,
    state,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'follows';
  @override
  VerificationContext validateIntegrity(
    Insertable<FollowsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('local_actor_id')) {
      context.handle(
        _localActorIdMeta,
        localActorId.isAcceptableOrUnknown(
          data['local_actor_id']!,
          _localActorIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localActorIdMeta);
    }
    if (data.containsKey('remote_actor_url')) {
      context.handle(
        _remoteActorUrlMeta,
        remoteActorUrl.isAcceptableOrUnknown(
          data['remote_actor_url']!,
          _remoteActorUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteActorUrlMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  FollowsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FollowsTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      localActorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_actor_id'],
      )!,
      remoteActorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_actor_url'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FollowsTableTable createAlias(String alias) {
    return $FollowsTableTable(attachedDatabase, alias);
  }
}

class FollowsTableData extends DataClass
    implements Insertable<FollowsTableData> {
  final int rowId;
  final String localActorId;
  final String remoteActorUrl;
  final String state;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FollowsTableData({
    required this.rowId,
    required this.localActorId,
    required this.remoteActorUrl,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['local_actor_id'] = Variable<String>(localActorId);
    map['remote_actor_url'] = Variable<String>(remoteActorUrl);
    map['state'] = Variable<String>(state);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FollowsTableCompanion toCompanion(bool nullToAbsent) {
    return FollowsTableCompanion(
      rowId: Value(rowId),
      localActorId: Value(localActorId),
      remoteActorUrl: Value(remoteActorUrl),
      state: Value(state),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FollowsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FollowsTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      localActorId: serializer.fromJson<String>(json['localActorId']),
      remoteActorUrl: serializer.fromJson<String>(json['remoteActorUrl']),
      state: serializer.fromJson<String>(json['state']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'localActorId': serializer.toJson<String>(localActorId),
      'remoteActorUrl': serializer.toJson<String>(remoteActorUrl),
      'state': serializer.toJson<String>(state),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FollowsTableData copyWith({
    int? rowId,
    String? localActorId,
    String? remoteActorUrl,
    String? state,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FollowsTableData(
    rowId: rowId ?? this.rowId,
    localActorId: localActorId ?? this.localActorId,
    remoteActorUrl: remoteActorUrl ?? this.remoteActorUrl,
    state: state ?? this.state,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FollowsTableData copyWithCompanion(FollowsTableCompanion data) {
    return FollowsTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      localActorId: data.localActorId.present
          ? data.localActorId.value
          : this.localActorId,
      remoteActorUrl: data.remoteActorUrl.present
          ? data.remoteActorUrl.value
          : this.remoteActorUrl,
      state: data.state.present ? data.state.value : this.state,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FollowsTableData(')
          ..write('rowId: $rowId, ')
          ..write('localActorId: $localActorId, ')
          ..write('remoteActorUrl: $remoteActorUrl, ')
          ..write('state: $state, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    localActorId,
    remoteActorUrl,
    state,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FollowsTableData &&
          other.rowId == this.rowId &&
          other.localActorId == this.localActorId &&
          other.remoteActorUrl == this.remoteActorUrl &&
          other.state == this.state &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FollowsTableCompanion extends UpdateCompanion<FollowsTableData> {
  final Value<int> rowId;
  final Value<String> localActorId;
  final Value<String> remoteActorUrl;
  final Value<String> state;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FollowsTableCompanion({
    this.rowId = const Value.absent(),
    this.localActorId = const Value.absent(),
    this.remoteActorUrl = const Value.absent(),
    this.state = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FollowsTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String localActorId,
    required String remoteActorUrl,
    this.state = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : localActorId = Value(localActorId),
       remoteActorUrl = Value(remoteActorUrl);
  static Insertable<FollowsTableData> custom({
    Expression<int>? rowId,
    Expression<String>? localActorId,
    Expression<String>? remoteActorUrl,
    Expression<String>? state,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (localActorId != null) 'local_actor_id': localActorId,
      if (remoteActorUrl != null) 'remote_actor_url': remoteActorUrl,
      if (state != null) 'state': state,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FollowsTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? localActorId,
    Value<String>? remoteActorUrl,
    Value<String>? state,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return FollowsTableCompanion(
      rowId: rowId ?? this.rowId,
      localActorId: localActorId ?? this.localActorId,
      remoteActorUrl: remoteActorUrl ?? this.remoteActorUrl,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (localActorId.present) {
      map['local_actor_id'] = Variable<String>(localActorId.value);
    }
    if (remoteActorUrl.present) {
      map['remote_actor_url'] = Variable<String>(remoteActorUrl.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowsTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('localActorId: $localActorId, ')
          ..write('remoteActorUrl: $remoteActorUrl, ')
          ..write('state: $state, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FollowRequestsTableTable extends FollowRequestsTable
    with TableInfo<$FollowRequestsTableTable, FollowRequestsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FollowRequestsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorUrlMeta = const VerificationMeta(
    'actorUrl',
  );
  @override
  late final GeneratedColumn<String> actorUrl = GeneratedColumn<String>(
    'actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    direction,
    actorUrl,
    state,
    activityId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'follow_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<FollowRequestsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('actor_url')) {
      context.handle(
        _actorUrlMeta,
        actorUrl.isAcceptableOrUnknown(data['actor_url']!, _actorUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_actorUrlMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  FollowRequestsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FollowRequestsTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      actorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_url'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FollowRequestsTableTable createAlias(String alias) {
    return $FollowRequestsTableTable(attachedDatabase, alias);
  }
}

class FollowRequestsTableData extends DataClass
    implements Insertable<FollowRequestsTableData> {
  final int rowId;
  final String direction;
  final String actorUrl;
  final String state;
  final String? activityId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FollowRequestsTableData({
    required this.rowId,
    required this.direction,
    required this.actorUrl,
    required this.state,
    this.activityId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['direction'] = Variable<String>(direction);
    map['actor_url'] = Variable<String>(actorUrl);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || activityId != null) {
      map['activity_id'] = Variable<String>(activityId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FollowRequestsTableCompanion toCompanion(bool nullToAbsent) {
    return FollowRequestsTableCompanion(
      rowId: Value(rowId),
      direction: Value(direction),
      actorUrl: Value(actorUrl),
      state: Value(state),
      activityId: activityId == null && nullToAbsent
          ? const Value.absent()
          : Value(activityId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FollowRequestsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FollowRequestsTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      direction: serializer.fromJson<String>(json['direction']),
      actorUrl: serializer.fromJson<String>(json['actorUrl']),
      state: serializer.fromJson<String>(json['state']),
      activityId: serializer.fromJson<String?>(json['activityId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'direction': serializer.toJson<String>(direction),
      'actorUrl': serializer.toJson<String>(actorUrl),
      'state': serializer.toJson<String>(state),
      'activityId': serializer.toJson<String?>(activityId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FollowRequestsTableData copyWith({
    int? rowId,
    String? direction,
    String? actorUrl,
    String? state,
    Value<String?> activityId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FollowRequestsTableData(
    rowId: rowId ?? this.rowId,
    direction: direction ?? this.direction,
    actorUrl: actorUrl ?? this.actorUrl,
    state: state ?? this.state,
    activityId: activityId.present ? activityId.value : this.activityId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FollowRequestsTableData copyWithCompanion(FollowRequestsTableCompanion data) {
    return FollowRequestsTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      direction: data.direction.present ? data.direction.value : this.direction,
      actorUrl: data.actorUrl.present ? data.actorUrl.value : this.actorUrl,
      state: data.state.present ? data.state.value : this.state,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FollowRequestsTableData(')
          ..write('rowId: $rowId, ')
          ..write('direction: $direction, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('state: $state, ')
          ..write('activityId: $activityId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    direction,
    actorUrl,
    state,
    activityId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FollowRequestsTableData &&
          other.rowId == this.rowId &&
          other.direction == this.direction &&
          other.actorUrl == this.actorUrl &&
          other.state == this.state &&
          other.activityId == this.activityId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FollowRequestsTableCompanion
    extends UpdateCompanion<FollowRequestsTableData> {
  final Value<int> rowId;
  final Value<String> direction;
  final Value<String> actorUrl;
  final Value<String> state;
  final Value<String?> activityId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FollowRequestsTableCompanion({
    this.rowId = const Value.absent(),
    this.direction = const Value.absent(),
    this.actorUrl = const Value.absent(),
    this.state = const Value.absent(),
    this.activityId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FollowRequestsTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String direction,
    required String actorUrl,
    this.state = const Value.absent(),
    this.activityId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : direction = Value(direction),
       actorUrl = Value(actorUrl);
  static Insertable<FollowRequestsTableData> custom({
    Expression<int>? rowId,
    Expression<String>? direction,
    Expression<String>? actorUrl,
    Expression<String>? state,
    Expression<String>? activityId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (direction != null) 'direction': direction,
      if (actorUrl != null) 'actor_url': actorUrl,
      if (state != null) 'state': state,
      if (activityId != null) 'activity_id': activityId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FollowRequestsTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? direction,
    Value<String>? actorUrl,
    Value<String>? state,
    Value<String?>? activityId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return FollowRequestsTableCompanion(
      rowId: rowId ?? this.rowId,
      direction: direction ?? this.direction,
      actorUrl: actorUrl ?? this.actorUrl,
      state: state ?? this.state,
      activityId: activityId ?? this.activityId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (actorUrl.present) {
      map['actor_url'] = Variable<String>(actorUrl.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowRequestsTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('direction: $direction, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('state: $state, ')
          ..write('activityId: $activityId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BlocksTableTable extends BlocksTable
    with TableInfo<$BlocksTableTable, BlocksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlocksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actorUrlMeta = const VerificationMeta(
    'actorUrl',
  );
  @override
  late final GeneratedColumn<String> actorUrl = GeneratedColumn<String>(
    'actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [rowId, actorUrl, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlocksTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('actor_url')) {
      context.handle(
        _actorUrlMeta,
        actorUrl.isAcceptableOrUnknown(data['actor_url']!, _actorUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_actorUrlMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  BlocksTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlocksTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      actorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_url'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BlocksTableTable createAlias(String alias) {
    return $BlocksTableTable(attachedDatabase, alias);
  }
}

class BlocksTableData extends DataClass implements Insertable<BlocksTableData> {
  final int rowId;
  final String actorUrl;
  final DateTime createdAt;
  const BlocksTableData({
    required this.rowId,
    required this.actorUrl,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['actor_url'] = Variable<String>(actorUrl);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BlocksTableCompanion toCompanion(bool nullToAbsent) {
    return BlocksTableCompanion(
      rowId: Value(rowId),
      actorUrl: Value(actorUrl),
      createdAt: Value(createdAt),
    );
  }

  factory BlocksTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlocksTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      actorUrl: serializer.fromJson<String>(json['actorUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'actorUrl': serializer.toJson<String>(actorUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BlocksTableData copyWith({
    int? rowId,
    String? actorUrl,
    DateTime? createdAt,
  }) => BlocksTableData(
    rowId: rowId ?? this.rowId,
    actorUrl: actorUrl ?? this.actorUrl,
    createdAt: createdAt ?? this.createdAt,
  );
  BlocksTableData copyWithCompanion(BlocksTableCompanion data) {
    return BlocksTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      actorUrl: data.actorUrl.present ? data.actorUrl.value : this.actorUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlocksTableData(')
          ..write('rowId: $rowId, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, actorUrl, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlocksTableData &&
          other.rowId == this.rowId &&
          other.actorUrl == this.actorUrl &&
          other.createdAt == this.createdAt);
}

class BlocksTableCompanion extends UpdateCompanion<BlocksTableData> {
  final Value<int> rowId;
  final Value<String> actorUrl;
  final Value<DateTime> createdAt;
  const BlocksTableCompanion({
    this.rowId = const Value.absent(),
    this.actorUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BlocksTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String actorUrl,
    this.createdAt = const Value.absent(),
  }) : actorUrl = Value(actorUrl);
  static Insertable<BlocksTableData> custom({
    Expression<int>? rowId,
    Expression<String>? actorUrl,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (actorUrl != null) 'actor_url': actorUrl,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BlocksTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? actorUrl,
    Value<DateTime>? createdAt,
  }) {
    return BlocksTableCompanion(
      rowId: rowId ?? this.rowId,
      actorUrl: actorUrl ?? this.actorUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (actorUrl.present) {
      map['actor_url'] = Variable<String>(actorUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlocksTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MutesTableTable extends MutesTable
    with TableInfo<$MutesTableTable, MutesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MutesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actorUrlMeta = const VerificationMeta(
    'actorUrl',
  );
  @override
  late final GeneratedColumn<String> actorUrl = GeneratedColumn<String>(
    'actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [rowId, actorUrl, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mutes';
  @override
  VerificationContext validateIntegrity(
    Insertable<MutesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('actor_url')) {
      context.handle(
        _actorUrlMeta,
        actorUrl.isAcceptableOrUnknown(data['actor_url']!, _actorUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_actorUrlMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  MutesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MutesTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      actorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_url'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MutesTableTable createAlias(String alias) {
    return $MutesTableTable(attachedDatabase, alias);
  }
}

class MutesTableData extends DataClass implements Insertable<MutesTableData> {
  final int rowId;
  final String actorUrl;
  final DateTime createdAt;
  const MutesTableData({
    required this.rowId,
    required this.actorUrl,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['actor_url'] = Variable<String>(actorUrl);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MutesTableCompanion toCompanion(bool nullToAbsent) {
    return MutesTableCompanion(
      rowId: Value(rowId),
      actorUrl: Value(actorUrl),
      createdAt: Value(createdAt),
    );
  }

  factory MutesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MutesTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      actorUrl: serializer.fromJson<String>(json['actorUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'actorUrl': serializer.toJson<String>(actorUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MutesTableData copyWith({
    int? rowId,
    String? actorUrl,
    DateTime? createdAt,
  }) => MutesTableData(
    rowId: rowId ?? this.rowId,
    actorUrl: actorUrl ?? this.actorUrl,
    createdAt: createdAt ?? this.createdAt,
  );
  MutesTableData copyWithCompanion(MutesTableCompanion data) {
    return MutesTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      actorUrl: data.actorUrl.present ? data.actorUrl.value : this.actorUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MutesTableData(')
          ..write('rowId: $rowId, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, actorUrl, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MutesTableData &&
          other.rowId == this.rowId &&
          other.actorUrl == this.actorUrl &&
          other.createdAt == this.createdAt);
}

class MutesTableCompanion extends UpdateCompanion<MutesTableData> {
  final Value<int> rowId;
  final Value<String> actorUrl;
  final Value<DateTime> createdAt;
  const MutesTableCompanion({
    this.rowId = const Value.absent(),
    this.actorUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MutesTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String actorUrl,
    this.createdAt = const Value.absent(),
  }) : actorUrl = Value(actorUrl);
  static Insertable<MutesTableData> custom({
    Expression<int>? rowId,
    Expression<String>? actorUrl,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (actorUrl != null) 'actor_url': actorUrl,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MutesTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? actorUrl,
    Value<DateTime>? createdAt,
  }) {
    return MutesTableCompanion(
      rowId: rowId ?? this.rowId,
      actorUrl: actorUrl ?? this.actorUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (actorUrl.present) {
      map['actor_url'] = Variable<String>(actorUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MutesTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SocialActivitiesTableTable extends SocialActivitiesTable
    with TableInfo<$SocialActivitiesTableTable, SocialActivitiesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SocialActivitiesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorUrlMeta = const VerificationMeta(
    'actorUrl',
  );
  @override
  late final GeneratedColumn<String> actorUrl = GeneratedColumn<String>(
    'actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _objectJsonMeta = const VerificationMeta(
    'objectJson',
  );
  @override
  late final GeneratedColumn<String> objectJson = GeneratedColumn<String>(
    'object_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storedAtMeta = const VerificationMeta(
    'storedAt',
  );
  @override
  late final GeneratedColumn<DateTime> storedAt = GeneratedColumn<DateTime>(
    'stored_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    activityId,
    type,
    actorUrl,
    objectJson,
    rawJson,
    publishedAt,
    storedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'social_activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<SocialActivitiesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('actor_url')) {
      context.handle(
        _actorUrlMeta,
        actorUrl.isAcceptableOrUnknown(data['actor_url']!, _actorUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_actorUrlMeta);
    }
    if (data.containsKey('object_json')) {
      context.handle(
        _objectJsonMeta,
        objectJson.isAcceptableOrUnknown(data['object_json']!, _objectJsonMeta),
      );
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publishedAtMeta);
    }
    if (data.containsKey('stored_at')) {
      context.handle(
        _storedAtMeta,
        storedAt.isAcceptableOrUnknown(data['stored_at']!, _storedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  SocialActivitiesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SocialActivitiesTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      actorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_url'],
      )!,
      objectJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object_json'],
      ),
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      )!,
      storedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}stored_at'],
      )!,
    );
  }

  @override
  $SocialActivitiesTableTable createAlias(String alias) {
    return $SocialActivitiesTableTable(attachedDatabase, alias);
  }
}

class SocialActivitiesTableData extends DataClass
    implements Insertable<SocialActivitiesTableData> {
  final int rowId;
  final String activityId;
  final String type;
  final String actorUrl;
  final String? objectJson;
  final String rawJson;
  final DateTime publishedAt;
  final DateTime storedAt;
  const SocialActivitiesTableData({
    required this.rowId,
    required this.activityId,
    required this.type,
    required this.actorUrl,
    this.objectJson,
    required this.rawJson,
    required this.publishedAt,
    required this.storedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['activity_id'] = Variable<String>(activityId);
    map['type'] = Variable<String>(type);
    map['actor_url'] = Variable<String>(actorUrl);
    if (!nullToAbsent || objectJson != null) {
      map['object_json'] = Variable<String>(objectJson);
    }
    map['raw_json'] = Variable<String>(rawJson);
    map['published_at'] = Variable<DateTime>(publishedAt);
    map['stored_at'] = Variable<DateTime>(storedAt);
    return map;
  }

  SocialActivitiesTableCompanion toCompanion(bool nullToAbsent) {
    return SocialActivitiesTableCompanion(
      rowId: Value(rowId),
      activityId: Value(activityId),
      type: Value(type),
      actorUrl: Value(actorUrl),
      objectJson: objectJson == null && nullToAbsent
          ? const Value.absent()
          : Value(objectJson),
      rawJson: Value(rawJson),
      publishedAt: Value(publishedAt),
      storedAt: Value(storedAt),
    );
  }

  factory SocialActivitiesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SocialActivitiesTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      activityId: serializer.fromJson<String>(json['activityId']),
      type: serializer.fromJson<String>(json['type']),
      actorUrl: serializer.fromJson<String>(json['actorUrl']),
      objectJson: serializer.fromJson<String?>(json['objectJson']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      publishedAt: serializer.fromJson<DateTime>(json['publishedAt']),
      storedAt: serializer.fromJson<DateTime>(json['storedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'activityId': serializer.toJson<String>(activityId),
      'type': serializer.toJson<String>(type),
      'actorUrl': serializer.toJson<String>(actorUrl),
      'objectJson': serializer.toJson<String?>(objectJson),
      'rawJson': serializer.toJson<String>(rawJson),
      'publishedAt': serializer.toJson<DateTime>(publishedAt),
      'storedAt': serializer.toJson<DateTime>(storedAt),
    };
  }

  SocialActivitiesTableData copyWith({
    int? rowId,
    String? activityId,
    String? type,
    String? actorUrl,
    Value<String?> objectJson = const Value.absent(),
    String? rawJson,
    DateTime? publishedAt,
    DateTime? storedAt,
  }) => SocialActivitiesTableData(
    rowId: rowId ?? this.rowId,
    activityId: activityId ?? this.activityId,
    type: type ?? this.type,
    actorUrl: actorUrl ?? this.actorUrl,
    objectJson: objectJson.present ? objectJson.value : this.objectJson,
    rawJson: rawJson ?? this.rawJson,
    publishedAt: publishedAt ?? this.publishedAt,
    storedAt: storedAt ?? this.storedAt,
  );
  SocialActivitiesTableData copyWithCompanion(
    SocialActivitiesTableCompanion data,
  ) {
    return SocialActivitiesTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      type: data.type.present ? data.type.value : this.type,
      actorUrl: data.actorUrl.present ? data.actorUrl.value : this.actorUrl,
      objectJson: data.objectJson.present
          ? data.objectJson.value
          : this.objectJson,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      storedAt: data.storedAt.present ? data.storedAt.value : this.storedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SocialActivitiesTableData(')
          ..write('rowId: $rowId, ')
          ..write('activityId: $activityId, ')
          ..write('type: $type, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('objectJson: $objectJson, ')
          ..write('rawJson: $rawJson, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('storedAt: $storedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    activityId,
    type,
    actorUrl,
    objectJson,
    rawJson,
    publishedAt,
    storedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SocialActivitiesTableData &&
          other.rowId == this.rowId &&
          other.activityId == this.activityId &&
          other.type == this.type &&
          other.actorUrl == this.actorUrl &&
          other.objectJson == this.objectJson &&
          other.rawJson == this.rawJson &&
          other.publishedAt == this.publishedAt &&
          other.storedAt == this.storedAt);
}

class SocialActivitiesTableCompanion
    extends UpdateCompanion<SocialActivitiesTableData> {
  final Value<int> rowId;
  final Value<String> activityId;
  final Value<String> type;
  final Value<String> actorUrl;
  final Value<String?> objectJson;
  final Value<String> rawJson;
  final Value<DateTime> publishedAt;
  final Value<DateTime> storedAt;
  const SocialActivitiesTableCompanion({
    this.rowId = const Value.absent(),
    this.activityId = const Value.absent(),
    this.type = const Value.absent(),
    this.actorUrl = const Value.absent(),
    this.objectJson = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.storedAt = const Value.absent(),
  });
  SocialActivitiesTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String activityId,
    required String type,
    required String actorUrl,
    this.objectJson = const Value.absent(),
    required String rawJson,
    required DateTime publishedAt,
    this.storedAt = const Value.absent(),
  }) : activityId = Value(activityId),
       type = Value(type),
       actorUrl = Value(actorUrl),
       rawJson = Value(rawJson),
       publishedAt = Value(publishedAt);
  static Insertable<SocialActivitiesTableData> custom({
    Expression<int>? rowId,
    Expression<String>? activityId,
    Expression<String>? type,
    Expression<String>? actorUrl,
    Expression<String>? objectJson,
    Expression<String>? rawJson,
    Expression<DateTime>? publishedAt,
    Expression<DateTime>? storedAt,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (activityId != null) 'activity_id': activityId,
      if (type != null) 'type': type,
      if (actorUrl != null) 'actor_url': actorUrl,
      if (objectJson != null) 'object_json': objectJson,
      if (rawJson != null) 'raw_json': rawJson,
      if (publishedAt != null) 'published_at': publishedAt,
      if (storedAt != null) 'stored_at': storedAt,
    });
  }

  SocialActivitiesTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? activityId,
    Value<String>? type,
    Value<String>? actorUrl,
    Value<String?>? objectJson,
    Value<String>? rawJson,
    Value<DateTime>? publishedAt,
    Value<DateTime>? storedAt,
  }) {
    return SocialActivitiesTableCompanion(
      rowId: rowId ?? this.rowId,
      activityId: activityId ?? this.activityId,
      type: type ?? this.type,
      actorUrl: actorUrl ?? this.actorUrl,
      objectJson: objectJson ?? this.objectJson,
      rawJson: rawJson ?? this.rawJson,
      publishedAt: publishedAt ?? this.publishedAt,
      storedAt: storedAt ?? this.storedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (actorUrl.present) {
      map['actor_url'] = Variable<String>(actorUrl.value);
    }
    if (objectJson.present) {
      map['object_json'] = Variable<String>(objectJson.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (storedAt.present) {
      map['stored_at'] = Variable<DateTime>(storedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SocialActivitiesTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('activityId: $activityId, ')
          ..write('type: $type, ')
          ..write('actorUrl: $actorUrl, ')
          ..write('objectJson: $objectJson, ')
          ..write('rawJson: $rawJson, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('storedAt: $storedAt')
          ..write(')'))
        .toString();
  }
}

class $NotificationsTableTable extends NotificationsTable
    with TableInfo<$NotificationsTableTable, NotificationsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromActorUrlMeta = const VerificationMeta(
    'fromActorUrl',
  );
  @override
  late final GeneratedColumn<String> fromActorUrl = GeneratedColumn<String>(
    'from_actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _objectRefMeta = const VerificationMeta(
    'objectRef',
  );
  @override
  late final GeneratedColumn<String> objectRef = GeneratedColumn<String>(
    'object_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    type,
    fromActorUrl,
    objectRef,
    isRead,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('from_actor_url')) {
      context.handle(
        _fromActorUrlMeta,
        fromActorUrl.isAcceptableOrUnknown(
          data['from_actor_url']!,
          _fromActorUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromActorUrlMeta);
    }
    if (data.containsKey('object_ref')) {
      context.handle(
        _objectRefMeta,
        objectRef.isAcceptableOrUnknown(data['object_ref']!, _objectRefMeta),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  NotificationsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationsTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      fromActorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_actor_url'],
      )!,
      objectRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object_ref'],
      ),
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $NotificationsTableTable createAlias(String alias) {
    return $NotificationsTableTable(attachedDatabase, alias);
  }
}

class NotificationsTableData extends DataClass
    implements Insertable<NotificationsTableData> {
  final int rowId;
  final String type;
  final String fromActorUrl;
  final String? objectRef;
  final bool isRead;
  final DateTime createdAt;
  const NotificationsTableData({
    required this.rowId,
    required this.type,
    required this.fromActorUrl,
    this.objectRef,
    required this.isRead,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['type'] = Variable<String>(type);
    map['from_actor_url'] = Variable<String>(fromActorUrl);
    if (!nullToAbsent || objectRef != null) {
      map['object_ref'] = Variable<String>(objectRef);
    }
    map['is_read'] = Variable<bool>(isRead);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NotificationsTableCompanion toCompanion(bool nullToAbsent) {
    return NotificationsTableCompanion(
      rowId: Value(rowId),
      type: Value(type),
      fromActorUrl: Value(fromActorUrl),
      objectRef: objectRef == null && nullToAbsent
          ? const Value.absent()
          : Value(objectRef),
      isRead: Value(isRead),
      createdAt: Value(createdAt),
    );
  }

  factory NotificationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationsTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      type: serializer.fromJson<String>(json['type']),
      fromActorUrl: serializer.fromJson<String>(json['fromActorUrl']),
      objectRef: serializer.fromJson<String?>(json['objectRef']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'type': serializer.toJson<String>(type),
      'fromActorUrl': serializer.toJson<String>(fromActorUrl),
      'objectRef': serializer.toJson<String?>(objectRef),
      'isRead': serializer.toJson<bool>(isRead),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NotificationsTableData copyWith({
    int? rowId,
    String? type,
    String? fromActorUrl,
    Value<String?> objectRef = const Value.absent(),
    bool? isRead,
    DateTime? createdAt,
  }) => NotificationsTableData(
    rowId: rowId ?? this.rowId,
    type: type ?? this.type,
    fromActorUrl: fromActorUrl ?? this.fromActorUrl,
    objectRef: objectRef.present ? objectRef.value : this.objectRef,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt ?? this.createdAt,
  );
  NotificationsTableData copyWithCompanion(NotificationsTableCompanion data) {
    return NotificationsTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      type: data.type.present ? data.type.value : this.type,
      fromActorUrl: data.fromActorUrl.present
          ? data.fromActorUrl.value
          : this.fromActorUrl,
      objectRef: data.objectRef.present ? data.objectRef.value : this.objectRef,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsTableData(')
          ..write('rowId: $rowId, ')
          ..write('type: $type, ')
          ..write('fromActorUrl: $fromActorUrl, ')
          ..write('objectRef: $objectRef, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(rowId, type, fromActorUrl, objectRef, isRead, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationsTableData &&
          other.rowId == this.rowId &&
          other.type == this.type &&
          other.fromActorUrl == this.fromActorUrl &&
          other.objectRef == this.objectRef &&
          other.isRead == this.isRead &&
          other.createdAt == this.createdAt);
}

class NotificationsTableCompanion
    extends UpdateCompanion<NotificationsTableData> {
  final Value<int> rowId;
  final Value<String> type;
  final Value<String> fromActorUrl;
  final Value<String?> objectRef;
  final Value<bool> isRead;
  final Value<DateTime> createdAt;
  const NotificationsTableCompanion({
    this.rowId = const Value.absent(),
    this.type = const Value.absent(),
    this.fromActorUrl = const Value.absent(),
    this.objectRef = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  NotificationsTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String type,
    required String fromActorUrl,
    this.objectRef = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : type = Value(type),
       fromActorUrl = Value(fromActorUrl);
  static Insertable<NotificationsTableData> custom({
    Expression<int>? rowId,
    Expression<String>? type,
    Expression<String>? fromActorUrl,
    Expression<String>? objectRef,
    Expression<bool>? isRead,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (type != null) 'type': type,
      if (fromActorUrl != null) 'from_actor_url': fromActorUrl,
      if (objectRef != null) 'object_ref': objectRef,
      if (isRead != null) 'is_read': isRead,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  NotificationsTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? type,
    Value<String>? fromActorUrl,
    Value<String?>? objectRef,
    Value<bool>? isRead,
    Value<DateTime>? createdAt,
  }) {
    return NotificationsTableCompanion(
      rowId: rowId ?? this.rowId,
      type: type ?? this.type,
      fromActorUrl: fromActorUrl ?? this.fromActorUrl,
      objectRef: objectRef ?? this.objectRef,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (fromActorUrl.present) {
      map['from_actor_url'] = Variable<String>(fromActorUrl.value);
    }
    if (objectRef.present) {
      map['object_ref'] = Variable<String>(objectRef.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('type: $type, ')
          ..write('fromActorUrl: $fromActorUrl, ')
          ..write('objectRef: $objectRef, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTableTable extends PlaylistsTable
    with TableInfo<$PlaylistsTableTable, PlaylistsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('private'),
  );
  static const VerificationMeta _collectionUrlMeta = const VerificationMeta(
    'collectionUrl',
  );
  @override
  late final GeneratedColumn<String> collectionUrl = GeneratedColumn<String>(
    'collection_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackIdsJsonMeta = const VerificationMeta(
    'trackIdsJson',
  );
  @override
  late final GeneratedColumn<String> trackIdsJson = GeneratedColumn<String>(
    'track_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    title,
    visibility,
    collectionUrl,
    trackIdsJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    }
    if (data.containsKey('collection_url')) {
      context.handle(
        _collectionUrlMeta,
        collectionUrl.isAcceptableOrUnknown(
          data['collection_url']!,
          _collectionUrlMeta,
        ),
      );
    }
    if (data.containsKey('track_ids_json')) {
      context.handle(
        _trackIdsJsonMeta,
        trackIdsJson.isAcceptableOrUnknown(
          data['track_ids_json']!,
          _trackIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  PlaylistsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistsTableData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      visibility: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visibility'],
      )!,
      collectionUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_url'],
      ),
      trackIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_ids_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlaylistsTableTable createAlias(String alias) {
    return $PlaylistsTableTable(attachedDatabase, alias);
  }
}

class PlaylistsTableData extends DataClass
    implements Insertable<PlaylistsTableData> {
  final int rowId;
  final String title;
  final String visibility;
  final String? collectionUrl;
  final String trackIdsJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PlaylistsTableData({
    required this.rowId,
    required this.title,
    required this.visibility,
    this.collectionUrl,
    required this.trackIdsJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['title'] = Variable<String>(title);
    map['visibility'] = Variable<String>(visibility);
    if (!nullToAbsent || collectionUrl != null) {
      map['collection_url'] = Variable<String>(collectionUrl);
    }
    map['track_ids_json'] = Variable<String>(trackIdsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlaylistsTableCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsTableCompanion(
      rowId: Value(rowId),
      title: Value(title),
      visibility: Value(visibility),
      collectionUrl: collectionUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(collectionUrl),
      trackIdsJson: Value(trackIdsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlaylistsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistsTableData(
      rowId: serializer.fromJson<int>(json['rowId']),
      title: serializer.fromJson<String>(json['title']),
      visibility: serializer.fromJson<String>(json['visibility']),
      collectionUrl: serializer.fromJson<String?>(json['collectionUrl']),
      trackIdsJson: serializer.fromJson<String>(json['trackIdsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'title': serializer.toJson<String>(title),
      'visibility': serializer.toJson<String>(visibility),
      'collectionUrl': serializer.toJson<String?>(collectionUrl),
      'trackIdsJson': serializer.toJson<String>(trackIdsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlaylistsTableData copyWith({
    int? rowId,
    String? title,
    String? visibility,
    Value<String?> collectionUrl = const Value.absent(),
    String? trackIdsJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PlaylistsTableData(
    rowId: rowId ?? this.rowId,
    title: title ?? this.title,
    visibility: visibility ?? this.visibility,
    collectionUrl: collectionUrl.present
        ? collectionUrl.value
        : this.collectionUrl,
    trackIdsJson: trackIdsJson ?? this.trackIdsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlaylistsTableData copyWithCompanion(PlaylistsTableCompanion data) {
    return PlaylistsTableData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      title: data.title.present ? data.title.value : this.title,
      visibility: data.visibility.present
          ? data.visibility.value
          : this.visibility,
      collectionUrl: data.collectionUrl.present
          ? data.collectionUrl.value
          : this.collectionUrl,
      trackIdsJson: data.trackIdsJson.present
          ? data.trackIdsJson.value
          : this.trackIdsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsTableData(')
          ..write('rowId: $rowId, ')
          ..write('title: $title, ')
          ..write('visibility: $visibility, ')
          ..write('collectionUrl: $collectionUrl, ')
          ..write('trackIdsJson: $trackIdsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    title,
    visibility,
    collectionUrl,
    trackIdsJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistsTableData &&
          other.rowId == this.rowId &&
          other.title == this.title &&
          other.visibility == this.visibility &&
          other.collectionUrl == this.collectionUrl &&
          other.trackIdsJson == this.trackIdsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlaylistsTableCompanion extends UpdateCompanion<PlaylistsTableData> {
  final Value<int> rowId;
  final Value<String> title;
  final Value<String> visibility;
  final Value<String?> collectionUrl;
  final Value<String> trackIdsJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PlaylistsTableCompanion({
    this.rowId = const Value.absent(),
    this.title = const Value.absent(),
    this.visibility = const Value.absent(),
    this.collectionUrl = const Value.absent(),
    this.trackIdsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PlaylistsTableCompanion.insert({
    this.rowId = const Value.absent(),
    required String title,
    this.visibility = const Value.absent(),
    this.collectionUrl = const Value.absent(),
    this.trackIdsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<PlaylistsTableData> custom({
    Expression<int>? rowId,
    Expression<String>? title,
    Expression<String>? visibility,
    Expression<String>? collectionUrl,
    Expression<String>? trackIdsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (title != null) 'title': title,
      if (visibility != null) 'visibility': visibility,
      if (collectionUrl != null) 'collection_url': collectionUrl,
      if (trackIdsJson != null) 'track_ids_json': trackIdsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PlaylistsTableCompanion copyWith({
    Value<int>? rowId,
    Value<String>? title,
    Value<String>? visibility,
    Value<String?>? collectionUrl,
    Value<String>? trackIdsJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PlaylistsTableCompanion(
      rowId: rowId ?? this.rowId,
      title: title ?? this.title,
      visibility: visibility ?? this.visibility,
      collectionUrl: collectionUrl ?? this.collectionUrl,
      trackIdsJson: trackIdsJson ?? this.trackIdsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (collectionUrl.present) {
      map['collection_url'] = Variable<String>(collectionUrl.value);
    }
    if (trackIdsJson.present) {
      map['track_ids_json'] = Variable<String>(trackIdsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsTableCompanion(')
          ..write('rowId: $rowId, ')
          ..write('title: $title, ')
          ..write('visibility: $visibility, ')
          ..write('collectionUrl: $collectionUrl, ')
          ..write('trackIdsJson: $trackIdsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SignalEventsTableTable extends SignalEventsTable
    with TableInfo<$SignalEventsTableTable, SignalEventsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalEventsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackFingerprintMeta = const VerificationMeta(
    'trackFingerprint',
  );
  @override
  late final GeneratedColumn<String> trackFingerprint = GeneratedColumn<String>(
    'track_fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceActorIdMeta = const VerificationMeta(
    'sourceActorId',
  );
  @override
  late final GeneratedColumn<String> sourceActorId = GeneratedColumn<String>(
    'source_actor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampUtcMsMeta = const VerificationMeta(
    'timestampUtcMs',
  );
  @override
  late final GeneratedColumn<int> timestampUtcMs = GeneratedColumn<int>(
    'timestamp_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackFingerprint,
    eventType,
    sourceActorId,
    timestampUtcMs,
    weight,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignalEventsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_fingerprint')) {
      context.handle(
        _trackFingerprintMeta,
        trackFingerprint.isAcceptableOrUnknown(
          data['track_fingerprint']!,
          _trackFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackFingerprintMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('source_actor_id')) {
      context.handle(
        _sourceActorIdMeta,
        sourceActorId.isAcceptableOrUnknown(
          data['source_actor_id']!,
          _sourceActorIdMeta,
        ),
      );
    }
    if (data.containsKey('timestamp_utc_ms')) {
      context.handle(
        _timestampUtcMsMeta,
        timestampUtcMs.isAcceptableOrUnknown(
          data['timestamp_utc_ms']!,
          _timestampUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timestampUtcMsMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SignalEventsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalEventsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_fingerprint'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      sourceActorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_actor_id'],
      ),
      timestampUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp_utc_ms'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
    );
  }

  @override
  $SignalEventsTableTable createAlias(String alias) {
    return $SignalEventsTableTable(attachedDatabase, alias);
  }
}

class SignalEventsTableData extends DataClass
    implements Insertable<SignalEventsTableData> {
  final int id;
  final String trackFingerprint;
  final String eventType;
  final String? sourceActorId;
  final int timestampUtcMs;
  final double weight;
  const SignalEventsTableData({
    required this.id,
    required this.trackFingerprint,
    required this.eventType,
    this.sourceActorId,
    required this.timestampUtcMs,
    required this.weight,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_fingerprint'] = Variable<String>(trackFingerprint);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || sourceActorId != null) {
      map['source_actor_id'] = Variable<String>(sourceActorId);
    }
    map['timestamp_utc_ms'] = Variable<int>(timestampUtcMs);
    map['weight'] = Variable<double>(weight);
    return map;
  }

  SignalEventsTableCompanion toCompanion(bool nullToAbsent) {
    return SignalEventsTableCompanion(
      id: Value(id),
      trackFingerprint: Value(trackFingerprint),
      eventType: Value(eventType),
      sourceActorId: sourceActorId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceActorId),
      timestampUtcMs: Value(timestampUtcMs),
      weight: Value(weight),
    );
  }

  factory SignalEventsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalEventsTableData(
      id: serializer.fromJson<int>(json['id']),
      trackFingerprint: serializer.fromJson<String>(json['trackFingerprint']),
      eventType: serializer.fromJson<String>(json['eventType']),
      sourceActorId: serializer.fromJson<String?>(json['sourceActorId']),
      timestampUtcMs: serializer.fromJson<int>(json['timestampUtcMs']),
      weight: serializer.fromJson<double>(json['weight']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackFingerprint': serializer.toJson<String>(trackFingerprint),
      'eventType': serializer.toJson<String>(eventType),
      'sourceActorId': serializer.toJson<String?>(sourceActorId),
      'timestampUtcMs': serializer.toJson<int>(timestampUtcMs),
      'weight': serializer.toJson<double>(weight),
    };
  }

  SignalEventsTableData copyWith({
    int? id,
    String? trackFingerprint,
    String? eventType,
    Value<String?> sourceActorId = const Value.absent(),
    int? timestampUtcMs,
    double? weight,
  }) => SignalEventsTableData(
    id: id ?? this.id,
    trackFingerprint: trackFingerprint ?? this.trackFingerprint,
    eventType: eventType ?? this.eventType,
    sourceActorId: sourceActorId.present
        ? sourceActorId.value
        : this.sourceActorId,
    timestampUtcMs: timestampUtcMs ?? this.timestampUtcMs,
    weight: weight ?? this.weight,
  );
  SignalEventsTableData copyWithCompanion(SignalEventsTableCompanion data) {
    return SignalEventsTableData(
      id: data.id.present ? data.id.value : this.id,
      trackFingerprint: data.trackFingerprint.present
          ? data.trackFingerprint.value
          : this.trackFingerprint,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      sourceActorId: data.sourceActorId.present
          ? data.sourceActorId.value
          : this.sourceActorId,
      timestampUtcMs: data.timestampUtcMs.present
          ? data.timestampUtcMs.value
          : this.timestampUtcMs,
      weight: data.weight.present ? data.weight.value : this.weight,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalEventsTableData(')
          ..write('id: $id, ')
          ..write('trackFingerprint: $trackFingerprint, ')
          ..write('eventType: $eventType, ')
          ..write('sourceActorId: $sourceActorId, ')
          ..write('timestampUtcMs: $timestampUtcMs, ')
          ..write('weight: $weight')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trackFingerprint,
    eventType,
    sourceActorId,
    timestampUtcMs,
    weight,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalEventsTableData &&
          other.id == this.id &&
          other.trackFingerprint == this.trackFingerprint &&
          other.eventType == this.eventType &&
          other.sourceActorId == this.sourceActorId &&
          other.timestampUtcMs == this.timestampUtcMs &&
          other.weight == this.weight);
}

class SignalEventsTableCompanion
    extends UpdateCompanion<SignalEventsTableData> {
  final Value<int> id;
  final Value<String> trackFingerprint;
  final Value<String> eventType;
  final Value<String?> sourceActorId;
  final Value<int> timestampUtcMs;
  final Value<double> weight;
  const SignalEventsTableCompanion({
    this.id = const Value.absent(),
    this.trackFingerprint = const Value.absent(),
    this.eventType = const Value.absent(),
    this.sourceActorId = const Value.absent(),
    this.timestampUtcMs = const Value.absent(),
    this.weight = const Value.absent(),
  });
  SignalEventsTableCompanion.insert({
    this.id = const Value.absent(),
    required String trackFingerprint,
    required String eventType,
    this.sourceActorId = const Value.absent(),
    required int timestampUtcMs,
    required double weight,
  }) : trackFingerprint = Value(trackFingerprint),
       eventType = Value(eventType),
       timestampUtcMs = Value(timestampUtcMs),
       weight = Value(weight);
  static Insertable<SignalEventsTableData> custom({
    Expression<int>? id,
    Expression<String>? trackFingerprint,
    Expression<String>? eventType,
    Expression<String>? sourceActorId,
    Expression<int>? timestampUtcMs,
    Expression<double>? weight,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackFingerprint != null) 'track_fingerprint': trackFingerprint,
      if (eventType != null) 'event_type': eventType,
      if (sourceActorId != null) 'source_actor_id': sourceActorId,
      if (timestampUtcMs != null) 'timestamp_utc_ms': timestampUtcMs,
      if (weight != null) 'weight': weight,
    });
  }

  SignalEventsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? trackFingerprint,
    Value<String>? eventType,
    Value<String?>? sourceActorId,
    Value<int>? timestampUtcMs,
    Value<double>? weight,
  }) {
    return SignalEventsTableCompanion(
      id: id ?? this.id,
      trackFingerprint: trackFingerprint ?? this.trackFingerprint,
      eventType: eventType ?? this.eventType,
      sourceActorId: sourceActorId ?? this.sourceActorId,
      timestampUtcMs: timestampUtcMs ?? this.timestampUtcMs,
      weight: weight ?? this.weight,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackFingerprint.present) {
      map['track_fingerprint'] = Variable<String>(trackFingerprint.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (sourceActorId.present) {
      map['source_actor_id'] = Variable<String>(sourceActorId.value);
    }
    if (timestampUtcMs.present) {
      map['timestamp_utc_ms'] = Variable<int>(timestampUtcMs.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalEventsTableCompanion(')
          ..write('id: $id, ')
          ..write('trackFingerprint: $trackFingerprint, ')
          ..write('eventType: $eventType, ')
          ..write('sourceActorId: $sourceActorId, ')
          ..write('timestampUtcMs: $timestampUtcMs, ')
          ..write('weight: $weight')
          ..write(')'))
        .toString();
  }
}

class $TasteScoresTableTable extends TasteScoresTable
    with TableInfo<$TasteScoresTableTable, TasteScoresTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasteScoresTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackFingerprintMeta = const VerificationMeta(
    'trackFingerprint',
  );
  @override
  late final GeneratedColumn<String> trackFingerprint = GeneratedColumn<String>(
    'track_fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [trackFingerprint, score];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'taste_scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<TasteScoresTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_fingerprint')) {
      context.handle(
        _trackFingerprintMeta,
        trackFingerprint.isAcceptableOrUnknown(
          data['track_fingerprint']!,
          _trackFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackFingerprintMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackFingerprint};
  @override
  TasteScoresTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TasteScoresTableData(
      trackFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_fingerprint'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
    );
  }

  @override
  $TasteScoresTableTable createAlias(String alias) {
    return $TasteScoresTableTable(attachedDatabase, alias);
  }
}

class TasteScoresTableData extends DataClass
    implements Insertable<TasteScoresTableData> {
  final String trackFingerprint;
  final double score;
  const TasteScoresTableData({
    required this.trackFingerprint,
    required this.score,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_fingerprint'] = Variable<String>(trackFingerprint);
    map['score'] = Variable<double>(score);
    return map;
  }

  TasteScoresTableCompanion toCompanion(bool nullToAbsent) {
    return TasteScoresTableCompanion(
      trackFingerprint: Value(trackFingerprint),
      score: Value(score),
    );
  }

  factory TasteScoresTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TasteScoresTableData(
      trackFingerprint: serializer.fromJson<String>(json['trackFingerprint']),
      score: serializer.fromJson<double>(json['score']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackFingerprint': serializer.toJson<String>(trackFingerprint),
      'score': serializer.toJson<double>(score),
    };
  }

  TasteScoresTableData copyWith({String? trackFingerprint, double? score}) =>
      TasteScoresTableData(
        trackFingerprint: trackFingerprint ?? this.trackFingerprint,
        score: score ?? this.score,
      );
  TasteScoresTableData copyWithCompanion(TasteScoresTableCompanion data) {
    return TasteScoresTableData(
      trackFingerprint: data.trackFingerprint.present
          ? data.trackFingerprint.value
          : this.trackFingerprint,
      score: data.score.present ? data.score.value : this.score,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TasteScoresTableData(')
          ..write('trackFingerprint: $trackFingerprint, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackFingerprint, score);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TasteScoresTableData &&
          other.trackFingerprint == this.trackFingerprint &&
          other.score == this.score);
}

class TasteScoresTableCompanion extends UpdateCompanion<TasteScoresTableData> {
  final Value<String> trackFingerprint;
  final Value<double> score;
  final Value<int> rowid;
  const TasteScoresTableCompanion({
    this.trackFingerprint = const Value.absent(),
    this.score = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasteScoresTableCompanion.insert({
    required String trackFingerprint,
    this.score = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : trackFingerprint = Value(trackFingerprint);
  static Insertable<TasteScoresTableData> custom({
    Expression<String>? trackFingerprint,
    Expression<double>? score,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackFingerprint != null) 'track_fingerprint': trackFingerprint,
      if (score != null) 'score': score,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasteScoresTableCompanion copyWith({
    Value<String>? trackFingerprint,
    Value<double>? score,
    Value<int>? rowid,
  }) {
    return TasteScoresTableCompanion(
      trackFingerprint: trackFingerprint ?? this.trackFingerprint,
      score: score ?? this.score,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackFingerprint.present) {
      map['track_fingerprint'] = Variable<String>(trackFingerprint.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasteScoresTableCompanion(')
          ..write('trackFingerprint: $trackFingerprint, ')
          ..write('score: $score, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivityQueueTableTable extends ActivityQueueTable
    with TableInfo<$ActivityQueueTableTable, ActivityQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _activityJsonMeta = const VerificationMeta(
    'activityJson',
  );
  @override
  late final GeneratedColumn<String> activityJson = GeneratedColumn<String>(
    'activity_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityTypeMeta = const VerificationMeta(
    'activityType',
  );
  @override
  late final GeneratedColumn<String> activityType = GeneratedColumn<String>(
    'activity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetActorUrlMeta = const VerificationMeta(
    'targetActorUrl',
  );
  @override
  late final GeneratedColumn<String> targetActorUrl = GeneratedColumn<String>(
    'target_actor_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activityJson,
    activityType,
    targetActorUrl,
    createdAt,
    attemptCount,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityQueueTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('activity_json')) {
      context.handle(
        _activityJsonMeta,
        activityJson.isAcceptableOrUnknown(
          data['activity_json']!,
          _activityJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityJsonMeta);
    }
    if (data.containsKey('activity_type')) {
      context.handle(
        _activityTypeMeta,
        activityType.isAcceptableOrUnknown(
          data['activity_type']!,
          _activityTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityTypeMeta);
    }
    if (data.containsKey('target_actor_url')) {
      context.handle(
        _targetActorUrlMeta,
        targetActorUrl.isAcceptableOrUnknown(
          data['target_actor_url']!,
          _targetActorUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetActorUrlMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityQueueTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activityJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_json'],
      )!,
      activityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_type'],
      )!,
      targetActorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_actor_url'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $ActivityQueueTableTable createAlias(String alias) {
    return $ActivityQueueTableTable(attachedDatabase, alias);
  }
}

class ActivityQueueTableData extends DataClass
    implements Insertable<ActivityQueueTableData> {
  final int id;
  final String activityJson;
  final String activityType;
  final String targetActorUrl;
  final DateTime createdAt;
  final int attemptCount;

  /// Values: 'pending' | 'delivering' | 'dead'
  final String status;
  const ActivityQueueTableData({
    required this.id,
    required this.activityJson,
    required this.activityType,
    required this.targetActorUrl,
    required this.createdAt,
    required this.attemptCount,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['activity_json'] = Variable<String>(activityJson);
    map['activity_type'] = Variable<String>(activityType);
    map['target_actor_url'] = Variable<String>(targetActorUrl);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempt_count'] = Variable<int>(attemptCount);
    map['status'] = Variable<String>(status);
    return map;
  }

  ActivityQueueTableCompanion toCompanion(bool nullToAbsent) {
    return ActivityQueueTableCompanion(
      id: Value(id),
      activityJson: Value(activityJson),
      activityType: Value(activityType),
      targetActorUrl: Value(targetActorUrl),
      createdAt: Value(createdAt),
      attemptCount: Value(attemptCount),
      status: Value(status),
    );
  }

  factory ActivityQueueTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      activityJson: serializer.fromJson<String>(json['activityJson']),
      activityType: serializer.fromJson<String>(json['activityType']),
      targetActorUrl: serializer.fromJson<String>(json['targetActorUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activityJson': serializer.toJson<String>(activityJson),
      'activityType': serializer.toJson<String>(activityType),
      'targetActorUrl': serializer.toJson<String>(targetActorUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'status': serializer.toJson<String>(status),
    };
  }

  ActivityQueueTableData copyWith({
    int? id,
    String? activityJson,
    String? activityType,
    String? targetActorUrl,
    DateTime? createdAt,
    int? attemptCount,
    String? status,
  }) => ActivityQueueTableData(
    id: id ?? this.id,
    activityJson: activityJson ?? this.activityJson,
    activityType: activityType ?? this.activityType,
    targetActorUrl: targetActorUrl ?? this.targetActorUrl,
    createdAt: createdAt ?? this.createdAt,
    attemptCount: attemptCount ?? this.attemptCount,
    status: status ?? this.status,
  );
  ActivityQueueTableData copyWithCompanion(ActivityQueueTableCompanion data) {
    return ActivityQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      activityJson: data.activityJson.present
          ? data.activityJson.value
          : this.activityJson,
      activityType: data.activityType.present
          ? data.activityType.value
          : this.activityType,
      targetActorUrl: data.targetActorUrl.present
          ? data.targetActorUrl.value
          : this.targetActorUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityQueueTableData(')
          ..write('id: $id, ')
          ..write('activityJson: $activityJson, ')
          ..write('activityType: $activityType, ')
          ..write('targetActorUrl: $targetActorUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activityJson,
    activityType,
    targetActorUrl,
    createdAt,
    attemptCount,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityQueueTableData &&
          other.id == this.id &&
          other.activityJson == this.activityJson &&
          other.activityType == this.activityType &&
          other.targetActorUrl == this.targetActorUrl &&
          other.createdAt == this.createdAt &&
          other.attemptCount == this.attemptCount &&
          other.status == this.status);
}

class ActivityQueueTableCompanion
    extends UpdateCompanion<ActivityQueueTableData> {
  final Value<int> id;
  final Value<String> activityJson;
  final Value<String> activityType;
  final Value<String> targetActorUrl;
  final Value<DateTime> createdAt;
  final Value<int> attemptCount;
  final Value<String> status;
  const ActivityQueueTableCompanion({
    this.id = const Value.absent(),
    this.activityJson = const Value.absent(),
    this.activityType = const Value.absent(),
    this.targetActorUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.status = const Value.absent(),
  });
  ActivityQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String activityJson,
    required String activityType,
    required String targetActorUrl,
    this.createdAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.status = const Value.absent(),
  }) : activityJson = Value(activityJson),
       activityType = Value(activityType),
       targetActorUrl = Value(targetActorUrl);
  static Insertable<ActivityQueueTableData> custom({
    Expression<int>? id,
    Expression<String>? activityJson,
    Expression<String>? activityType,
    Expression<String>? targetActorUrl,
    Expression<DateTime>? createdAt,
    Expression<int>? attemptCount,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityJson != null) 'activity_json': activityJson,
      if (activityType != null) 'activity_type': activityType,
      if (targetActorUrl != null) 'target_actor_url': targetActorUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (status != null) 'status': status,
    });
  }

  ActivityQueueTableCompanion copyWith({
    Value<int>? id,
    Value<String>? activityJson,
    Value<String>? activityType,
    Value<String>? targetActorUrl,
    Value<DateTime>? createdAt,
    Value<int>? attemptCount,
    Value<String>? status,
  }) {
    return ActivityQueueTableCompanion(
      id: id ?? this.id,
      activityJson: activityJson ?? this.activityJson,
      activityType: activityType ?? this.activityType,
      targetActorUrl: targetActorUrl ?? this.targetActorUrl,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activityJson.present) {
      map['activity_json'] = Variable<String>(activityJson.value);
    }
    if (activityType.present) {
      map['activity_type'] = Variable<String>(activityType.value);
    }
    if (targetActorUrl.present) {
      map['target_actor_url'] = Variable<String>(targetActorUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('activityJson: $activityJson, ')
          ..write('activityType: $activityType, ')
          ..write('targetActorUrl: $targetActorUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AlbumsTableTable albumsTable = $AlbumsTableTable(this);
  late final $TracksTableTable tracksTable = $TracksTableTable(this);
  late final $ArtistsTableTable artistsTable = $ArtistsTableTable(this);
  late final $NodeIdentityTableTable nodeIdentityTable =
      $NodeIdentityTableTable(this);
  late final $InboxActivitiesTableTable inboxActivitiesTable =
      $InboxActivitiesTableTable(this);
  late final $OutboxActivitiesTableTable outboxActivitiesTable =
      $OutboxActivitiesTableTable(this);
  late final $ActorCacheTableTable actorCacheTable = $ActorCacheTableTable(
    this,
  );
  late final $FollowersTableTable followersTable = $FollowersTableTable(this);
  late final $FollowingTableTable followingTable = $FollowingTableTable(this);
  late final $DefederatedNodesTableTable defederatedNodesTable =
      $DefederatedNodesTableTable(this);
  late final $NodeAllowDenyListTableTable nodeAllowDenyListTable =
      $NodeAllowDenyListTableTable(this);
  late final $MigrationTokensTableTable migrationTokensTable =
      $MigrationTokensTableTable(this);
  late final $RemoteLibrariesTableTable remoteLibrariesTable =
      $RemoteLibrariesTableTable(this);
  late final $AudioCacheTableTable audioCacheTable = $AudioCacheTableTable(
    this,
  );
  late final $ListenActivitiesTableTable listenActivitiesTable =
      $ListenActivitiesTableTable(this);
  late final $FingerprintsTableTable fingerprintsTable =
      $FingerprintsTableTable(this);
  late final $MergeProvenanceTableTable mergeProvenanceTable =
      $MergeProvenanceTableTable(this);
  late final $FollowsTableTable followsTable = $FollowsTableTable(this);
  late final $FollowRequestsTableTable followRequestsTable =
      $FollowRequestsTableTable(this);
  late final $BlocksTableTable blocksTable = $BlocksTableTable(this);
  late final $MutesTableTable mutesTable = $MutesTableTable(this);
  late final $SocialActivitiesTableTable socialActivitiesTable =
      $SocialActivitiesTableTable(this);
  late final $NotificationsTableTable notificationsTable =
      $NotificationsTableTable(this);
  late final $PlaylistsTableTable playlistsTable = $PlaylistsTableTable(this);
  late final $SignalEventsTableTable signalEventsTable =
      $SignalEventsTableTable(this);
  late final $TasteScoresTableTable tasteScoresTable = $TasteScoresTableTable(
    this,
  );
  late final $ActivityQueueTableTable activityQueueTable =
      $ActivityQueueTableTable(this);
  late final TrackDao trackDao = TrackDao(this as AppDatabase);
  late final AlbumDao albumDao = AlbumDao(this as AppDatabase);
  late final ArtistDao artistDao = ArtistDao(this as AppDatabase);
  late final SignalDao signalDao = SignalDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    albumsTable,
    tracksTable,
    artistsTable,
    nodeIdentityTable,
    inboxActivitiesTable,
    outboxActivitiesTable,
    actorCacheTable,
    followersTable,
    followingTable,
    defederatedNodesTable,
    nodeAllowDenyListTable,
    migrationTokensTable,
    remoteLibrariesTable,
    audioCacheTable,
    listenActivitiesTable,
    fingerprintsTable,
    mergeProvenanceTable,
    followsTable,
    followRequestsTable,
    blocksTable,
    mutesTable,
    socialActivitiesTable,
    notificationsTable,
    playlistsTable,
    signalEventsTable,
    tasteScoresTable,
    activityQueueTable,
  ];
}

typedef $$AlbumsTableTableCreateCompanionBuilder =
    AlbumsTableCompanion Function({
      Value<int> id,
      required String name,
      Value<String> artist,
      Value<String?> artworkPath,
      Value<int?> releaseYear,
      Value<int> trackCount,
    });
typedef $$AlbumsTableTableUpdateCompanionBuilder =
    AlbumsTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> artist,
      Value<String?> artworkPath,
      Value<int?> releaseYear,
      Value<int> trackCount,
    });

final class $$AlbumsTableTableReferences
    extends BaseReferences<_$AppDatabase, $AlbumsTableTable, AlbumsTableData> {
  $$AlbumsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TracksTableTable, List<TracksTableData>>
  _tracksTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.tracksTable,
    aliasName: $_aliasNameGenerator(db.albumsTable.id, db.tracksTable.albumId),
  );

  $$TracksTableTableProcessedTableManager get tracksTableRefs {
    final manager = $$TracksTableTableTableManager(
      $_db,
      $_db.tracksTable,
    ).filter((f) => f.albumId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tracksTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AlbumsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AlbumsTableTable> {
  $$AlbumsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkPath => $composableBuilder(
    column: $table.artworkPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tracksTableRefs(
    Expression<bool> Function($$TracksTableTableFilterComposer f) f,
  ) {
    final $$TracksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableFilterComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AlbumsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AlbumsTableTable> {
  $$AlbumsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkPath => $composableBuilder(
    column: $table.artworkPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlbumsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlbumsTableTable> {
  $$AlbumsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get artworkPath => $composableBuilder(
    column: $table.artworkPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => column,
  );

  Expression<T> tracksTableRefs<T extends Object>(
    Expression<T> Function($$TracksTableTableAnnotationComposer a) f,
  ) {
    final $$TracksTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableAnnotationComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AlbumsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlbumsTableTable,
          AlbumsTableData,
          $$AlbumsTableTableFilterComposer,
          $$AlbumsTableTableOrderingComposer,
          $$AlbumsTableTableAnnotationComposer,
          $$AlbumsTableTableCreateCompanionBuilder,
          $$AlbumsTableTableUpdateCompanionBuilder,
          (AlbumsTableData, $$AlbumsTableTableReferences),
          AlbumsTableData,
          PrefetchHooks Function({bool tracksTableRefs})
        > {
  $$AlbumsTableTableTableManager(_$AppDatabase db, $AlbumsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String?> artworkPath = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<int> trackCount = const Value.absent(),
              }) => AlbumsTableCompanion(
                id: id,
                name: name,
                artist: artist,
                artworkPath: artworkPath,
                releaseYear: releaseYear,
                trackCount: trackCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> artist = const Value.absent(),
                Value<String?> artworkPath = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<int> trackCount = const Value.absent(),
              }) => AlbumsTableCompanion.insert(
                id: id,
                name: name,
                artist: artist,
                artworkPath: artworkPath,
                releaseYear: releaseYear,
                trackCount: trackCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AlbumsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tracksTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tracksTableRefs) db.tracksTable],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tracksTableRefs)
                    await $_getPrefetchedData<
                      AlbumsTableData,
                      $AlbumsTableTable,
                      TracksTableData
                    >(
                      currentTable: table,
                      referencedTable: $$AlbumsTableTableReferences
                          ._tracksTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AlbumsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).tracksTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.albumId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AlbumsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlbumsTableTable,
      AlbumsTableData,
      $$AlbumsTableTableFilterComposer,
      $$AlbumsTableTableOrderingComposer,
      $$AlbumsTableTableAnnotationComposer,
      $$AlbumsTableTableCreateCompanionBuilder,
      $$AlbumsTableTableUpdateCompanionBuilder,
      (AlbumsTableData, $$AlbumsTableTableReferences),
      AlbumsTableData,
      PrefetchHooks Function({bool tracksTableRefs})
    >;
typedef $$TracksTableTableCreateCompanionBuilder =
    TracksTableCompanion Function({
      Value<int> id,
      required String filePath,
      required String title,
      Value<String> artist,
      Value<int?> albumId,
      Value<String?> albumArtist,
      Value<int?> trackNumber,
      Value<int?> discNumber,
      Value<String?> genre,
      Value<int?> releaseYear,
      Value<int> durationMs,
      Value<String?> artworkPath,
      Value<DateTime> dateAdded,
    });
typedef $$TracksTableTableUpdateCompanionBuilder =
    TracksTableCompanion Function({
      Value<int> id,
      Value<String> filePath,
      Value<String> title,
      Value<String> artist,
      Value<int?> albumId,
      Value<String?> albumArtist,
      Value<int?> trackNumber,
      Value<int?> discNumber,
      Value<String?> genre,
      Value<int?> releaseYear,
      Value<int> durationMs,
      Value<String?> artworkPath,
      Value<DateTime> dateAdded,
    });

final class $$TracksTableTableReferences
    extends BaseReferences<_$AppDatabase, $TracksTableTable, TracksTableData> {
  $$TracksTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AlbumsTableTable _albumIdTable(_$AppDatabase db) =>
      db.albumsTable.createAlias(
        $_aliasNameGenerator(db.tracksTable.albumId, db.albumsTable.id),
      );

  $$AlbumsTableTableProcessedTableManager? get albumId {
    final $_column = $_itemColumn<int>('album_id');
    if ($_column == null) return null;
    final manager = $$AlbumsTableTableTableManager(
      $_db,
      $_db.albumsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_albumIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TracksTableTableFilterComposer
    extends Composer<_$AppDatabase, $TracksTableTable> {
  $$TracksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkPath => $composableBuilder(
    column: $table.artworkPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  $$AlbumsTableTableFilterComposer get albumId {
    final $$AlbumsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albumsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableTableFilterComposer(
            $db: $db,
            $table: $db.albumsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TracksTableTable> {
  $$TracksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkPath => $composableBuilder(
    column: $table.artworkPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  $$AlbumsTableTableOrderingComposer get albumId {
    final $$AlbumsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albumsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableTableOrderingComposer(
            $db: $db,
            $table: $db.albumsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracksTableTable> {
  $$TracksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artworkPath => $composableBuilder(
    column: $table.artworkPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  $$AlbumsTableTableAnnotationComposer get albumId {
    final $$AlbumsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albumsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.albumsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TracksTableTable,
          TracksTableData,
          $$TracksTableTableFilterComposer,
          $$TracksTableTableOrderingComposer,
          $$TracksTableTableAnnotationComposer,
          $$TracksTableTableCreateCompanionBuilder,
          $$TracksTableTableUpdateCompanionBuilder,
          (TracksTableData, $$TracksTableTableReferences),
          TracksTableData,
          PrefetchHooks Function({bool albumId})
        > {
  $$TracksTableTableTableManager(_$AppDatabase db, $TracksTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<int?> albumId = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String?> artworkPath = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
              }) => TracksTableCompanion(
                id: id,
                filePath: filePath,
                title: title,
                artist: artist,
                albumId: albumId,
                albumArtist: albumArtist,
                trackNumber: trackNumber,
                discNumber: discNumber,
                genre: genre,
                releaseYear: releaseYear,
                durationMs: durationMs,
                artworkPath: artworkPath,
                dateAdded: dateAdded,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String filePath,
                required String title,
                Value<String> artist = const Value.absent(),
                Value<int?> albumId = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String?> artworkPath = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
              }) => TracksTableCompanion.insert(
                id: id,
                filePath: filePath,
                title: title,
                artist: artist,
                albumId: albumId,
                albumArtist: albumArtist,
                trackNumber: trackNumber,
                discNumber: discNumber,
                genre: genre,
                releaseYear: releaseYear,
                durationMs: durationMs,
                artworkPath: artworkPath,
                dateAdded: dateAdded,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TracksTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({albumId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (albumId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.albumId,
                                referencedTable: $$TracksTableTableReferences
                                    ._albumIdTable(db),
                                referencedColumn: $$TracksTableTableReferences
                                    ._albumIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TracksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TracksTableTable,
      TracksTableData,
      $$TracksTableTableFilterComposer,
      $$TracksTableTableOrderingComposer,
      $$TracksTableTableAnnotationComposer,
      $$TracksTableTableCreateCompanionBuilder,
      $$TracksTableTableUpdateCompanionBuilder,
      (TracksTableData, $$TracksTableTableReferences),
      TracksTableData,
      PrefetchHooks Function({bool albumId})
    >;
typedef $$ArtistsTableTableCreateCompanionBuilder =
    ArtistsTableCompanion Function({Value<int> id, required String name});
typedef $$ArtistsTableTableUpdateCompanionBuilder =
    ArtistsTableCompanion Function({Value<int> id, Value<String> name});

class $$ArtistsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ArtistsTableTable> {
  $$ArtistsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArtistsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtistsTableTable> {
  $$ArtistsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArtistsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtistsTableTable> {
  $$ArtistsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$ArtistsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArtistsTableTable,
          ArtistsTableData,
          $$ArtistsTableTableFilterComposer,
          $$ArtistsTableTableOrderingComposer,
          $$ArtistsTableTableAnnotationComposer,
          $$ArtistsTableTableCreateCompanionBuilder,
          $$ArtistsTableTableUpdateCompanionBuilder,
          (
            ArtistsTableData,
            BaseReferences<_$AppDatabase, $ArtistsTableTable, ArtistsTableData>,
          ),
          ArtistsTableData,
          PrefetchHooks Function()
        > {
  $$ArtistsTableTableTableManager(_$AppDatabase db, $ArtistsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtistsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtistsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtistsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => ArtistsTableCompanion(id: id, name: name),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String name}) =>
                  ArtistsTableCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArtistsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArtistsTableTable,
      ArtistsTableData,
      $$ArtistsTableTableFilterComposer,
      $$ArtistsTableTableOrderingComposer,
      $$ArtistsTableTableAnnotationComposer,
      $$ArtistsTableTableCreateCompanionBuilder,
      $$ArtistsTableTableUpdateCompanionBuilder,
      (
        ArtistsTableData,
        BaseReferences<_$AppDatabase, $ArtistsTableTable, ArtistsTableData>,
      ),
      ArtistsTableData,
      PrefetchHooks Function()
    >;
typedef $$NodeIdentityTableTableCreateCompanionBuilder =
    NodeIdentityTableCompanion Function({
      Value<int> id,
      required String actorUrl,
      required String publicKeyPem,
      required String preferredUsername,
      required String displayName,
      Value<DateTime> createdAt,
      Value<String?> nodePublicAddress,
    });
typedef $$NodeIdentityTableTableUpdateCompanionBuilder =
    NodeIdentityTableCompanion Function({
      Value<int> id,
      Value<String> actorUrl,
      Value<String> publicKeyPem,
      Value<String> preferredUsername,
      Value<String> displayName,
      Value<DateTime> createdAt,
      Value<String?> nodePublicAddress,
    });

class $$NodeIdentityTableTableFilterComposer
    extends Composer<_$AppDatabase, $NodeIdentityTableTable> {
  $$NodeIdentityTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKeyPem => $composableBuilder(
    column: $table.publicKeyPem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredUsername => $composableBuilder(
    column: $table.preferredUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodePublicAddress => $composableBuilder(
    column: $table.nodePublicAddress,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NodeIdentityTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NodeIdentityTableTable> {
  $$NodeIdentityTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKeyPem => $composableBuilder(
    column: $table.publicKeyPem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredUsername => $composableBuilder(
    column: $table.preferredUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodePublicAddress => $composableBuilder(
    column: $table.nodePublicAddress,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NodeIdentityTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodeIdentityTableTable> {
  $$NodeIdentityTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get actorUrl =>
      $composableBuilder(column: $table.actorUrl, builder: (column) => column);

  GeneratedColumn<String> get publicKeyPem => $composableBuilder(
    column: $table.publicKeyPem,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredUsername => $composableBuilder(
    column: $table.preferredUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get nodePublicAddress => $composableBuilder(
    column: $table.nodePublicAddress,
    builder: (column) => column,
  );
}

class $$NodeIdentityTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodeIdentityTableTable,
          NodeIdentityTableData,
          $$NodeIdentityTableTableFilterComposer,
          $$NodeIdentityTableTableOrderingComposer,
          $$NodeIdentityTableTableAnnotationComposer,
          $$NodeIdentityTableTableCreateCompanionBuilder,
          $$NodeIdentityTableTableUpdateCompanionBuilder,
          (
            NodeIdentityTableData,
            BaseReferences<
              _$AppDatabase,
              $NodeIdentityTableTable,
              NodeIdentityTableData
            >,
          ),
          NodeIdentityTableData,
          PrefetchHooks Function()
        > {
  $$NodeIdentityTableTableTableManager(
    _$AppDatabase db,
    $NodeIdentityTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodeIdentityTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodeIdentityTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodeIdentityTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> actorUrl = const Value.absent(),
                Value<String> publicKeyPem = const Value.absent(),
                Value<String> preferredUsername = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> nodePublicAddress = const Value.absent(),
              }) => NodeIdentityTableCompanion(
                id: id,
                actorUrl: actorUrl,
                publicKeyPem: publicKeyPem,
                preferredUsername: preferredUsername,
                displayName: displayName,
                createdAt: createdAt,
                nodePublicAddress: nodePublicAddress,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String actorUrl,
                required String publicKeyPem,
                required String preferredUsername,
                required String displayName,
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> nodePublicAddress = const Value.absent(),
              }) => NodeIdentityTableCompanion.insert(
                id: id,
                actorUrl: actorUrl,
                publicKeyPem: publicKeyPem,
                preferredUsername: preferredUsername,
                displayName: displayName,
                createdAt: createdAt,
                nodePublicAddress: nodePublicAddress,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NodeIdentityTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodeIdentityTableTable,
      NodeIdentityTableData,
      $$NodeIdentityTableTableFilterComposer,
      $$NodeIdentityTableTableOrderingComposer,
      $$NodeIdentityTableTableAnnotationComposer,
      $$NodeIdentityTableTableCreateCompanionBuilder,
      $$NodeIdentityTableTableUpdateCompanionBuilder,
      (
        NodeIdentityTableData,
        BaseReferences<
          _$AppDatabase,
          $NodeIdentityTableTable,
          NodeIdentityTableData
        >,
      ),
      NodeIdentityTableData,
      PrefetchHooks Function()
    >;
typedef $$InboxActivitiesTableTableCreateCompanionBuilder =
    InboxActivitiesTableCompanion Function({
      Value<int> rowId,
      required String activityId,
      required String type,
      required String actorUrl,
      Value<String?> objectJson,
      required String rawJson,
      Value<DateTime> receivedAt,
      Value<bool> processed,
    });
typedef $$InboxActivitiesTableTableUpdateCompanionBuilder =
    InboxActivitiesTableCompanion Function({
      Value<int> rowId,
      Value<String> activityId,
      Value<String> type,
      Value<String> actorUrl,
      Value<String?> objectJson,
      Value<String> rawJson,
      Value<DateTime> receivedAt,
      Value<bool> processed,
    });

class $$InboxActivitiesTableTableFilterComposer
    extends Composer<_$AppDatabase, $InboxActivitiesTableTable> {
  $$InboxActivitiesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objectJson => $composableBuilder(
    column: $table.objectJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get processed => $composableBuilder(
    column: $table.processed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InboxActivitiesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InboxActivitiesTableTable> {
  $$InboxActivitiesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objectJson => $composableBuilder(
    column: $table.objectJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get processed => $composableBuilder(
    column: $table.processed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InboxActivitiesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InboxActivitiesTableTable> {
  $$InboxActivitiesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get actorUrl =>
      $composableBuilder(column: $table.actorUrl, builder: (column) => column);

  GeneratedColumn<String> get objectJson => $composableBuilder(
    column: $table.objectJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get processed =>
      $composableBuilder(column: $table.processed, builder: (column) => column);
}

class $$InboxActivitiesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InboxActivitiesTableTable,
          InboxActivitiesTableData,
          $$InboxActivitiesTableTableFilterComposer,
          $$InboxActivitiesTableTableOrderingComposer,
          $$InboxActivitiesTableTableAnnotationComposer,
          $$InboxActivitiesTableTableCreateCompanionBuilder,
          $$InboxActivitiesTableTableUpdateCompanionBuilder,
          (
            InboxActivitiesTableData,
            BaseReferences<
              _$AppDatabase,
              $InboxActivitiesTableTable,
              InboxActivitiesTableData
            >,
          ),
          InboxActivitiesTableData,
          PrefetchHooks Function()
        > {
  $$InboxActivitiesTableTableTableManager(
    _$AppDatabase db,
    $InboxActivitiesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InboxActivitiesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InboxActivitiesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InboxActivitiesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> activityId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> actorUrl = const Value.absent(),
                Value<String?> objectJson = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<bool> processed = const Value.absent(),
              }) => InboxActivitiesTableCompanion(
                rowId: rowId,
                activityId: activityId,
                type: type,
                actorUrl: actorUrl,
                objectJson: objectJson,
                rawJson: rawJson,
                receivedAt: receivedAt,
                processed: processed,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String activityId,
                required String type,
                required String actorUrl,
                Value<String?> objectJson = const Value.absent(),
                required String rawJson,
                Value<DateTime> receivedAt = const Value.absent(),
                Value<bool> processed = const Value.absent(),
              }) => InboxActivitiesTableCompanion.insert(
                rowId: rowId,
                activityId: activityId,
                type: type,
                actorUrl: actorUrl,
                objectJson: objectJson,
                rawJson: rawJson,
                receivedAt: receivedAt,
                processed: processed,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InboxActivitiesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InboxActivitiesTableTable,
      InboxActivitiesTableData,
      $$InboxActivitiesTableTableFilterComposer,
      $$InboxActivitiesTableTableOrderingComposer,
      $$InboxActivitiesTableTableAnnotationComposer,
      $$InboxActivitiesTableTableCreateCompanionBuilder,
      $$InboxActivitiesTableTableUpdateCompanionBuilder,
      (
        InboxActivitiesTableData,
        BaseReferences<
          _$AppDatabase,
          $InboxActivitiesTableTable,
          InboxActivitiesTableData
        >,
      ),
      InboxActivitiesTableData,
      PrefetchHooks Function()
    >;
typedef $$OutboxActivitiesTableTableCreateCompanionBuilder =
    OutboxActivitiesTableCompanion Function({
      Value<int> rowId,
      required String activityId,
      required String type,
      required String targetInboxUrl,
      required String payloadJson,
      Value<String> status,
      Value<int> attemptCount,
      Value<String?> relayReferenceId,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptedAt,
    });
typedef $$OutboxActivitiesTableTableUpdateCompanionBuilder =
    OutboxActivitiesTableCompanion Function({
      Value<int> rowId,
      Value<String> activityId,
      Value<String> type,
      Value<String> targetInboxUrl,
      Value<String> payloadJson,
      Value<String> status,
      Value<int> attemptCount,
      Value<String?> relayReferenceId,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptedAt,
    });

class $$OutboxActivitiesTableTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxActivitiesTableTable> {
  $$OutboxActivitiesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetInboxUrl => $composableBuilder(
    column: $table.targetInboxUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relayReferenceId => $composableBuilder(
    column: $table.relayReferenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptedAt => $composableBuilder(
    column: $table.lastAttemptedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxActivitiesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxActivitiesTableTable> {
  $$OutboxActivitiesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetInboxUrl => $composableBuilder(
    column: $table.targetInboxUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relayReferenceId => $composableBuilder(
    column: $table.relayReferenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptedAt => $composableBuilder(
    column: $table.lastAttemptedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxActivitiesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxActivitiesTableTable> {
  $$OutboxActivitiesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get targetInboxUrl => $composableBuilder(
    column: $table.targetInboxUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relayReferenceId => $composableBuilder(
    column: $table.relayReferenceId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptedAt => $composableBuilder(
    column: $table.lastAttemptedAt,
    builder: (column) => column,
  );
}

class $$OutboxActivitiesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxActivitiesTableTable,
          OutboxActivitiesTableData,
          $$OutboxActivitiesTableTableFilterComposer,
          $$OutboxActivitiesTableTableOrderingComposer,
          $$OutboxActivitiesTableTableAnnotationComposer,
          $$OutboxActivitiesTableTableCreateCompanionBuilder,
          $$OutboxActivitiesTableTableUpdateCompanionBuilder,
          (
            OutboxActivitiesTableData,
            BaseReferences<
              _$AppDatabase,
              $OutboxActivitiesTableTable,
              OutboxActivitiesTableData
            >,
          ),
          OutboxActivitiesTableData,
          PrefetchHooks Function()
        > {
  $$OutboxActivitiesTableTableTableManager(
    _$AppDatabase db,
    $OutboxActivitiesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxActivitiesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$OutboxActivitiesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OutboxActivitiesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> activityId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> targetInboxUrl = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> relayReferenceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptedAt = const Value.absent(),
              }) => OutboxActivitiesTableCompanion(
                rowId: rowId,
                activityId: activityId,
                type: type,
                targetInboxUrl: targetInboxUrl,
                payloadJson: payloadJson,
                status: status,
                attemptCount: attemptCount,
                relayReferenceId: relayReferenceId,
                createdAt: createdAt,
                lastAttemptedAt: lastAttemptedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String activityId,
                required String type,
                required String targetInboxUrl,
                required String payloadJson,
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> relayReferenceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptedAt = const Value.absent(),
              }) => OutboxActivitiesTableCompanion.insert(
                rowId: rowId,
                activityId: activityId,
                type: type,
                targetInboxUrl: targetInboxUrl,
                payloadJson: payloadJson,
                status: status,
                attemptCount: attemptCount,
                relayReferenceId: relayReferenceId,
                createdAt: createdAt,
                lastAttemptedAt: lastAttemptedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxActivitiesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxActivitiesTableTable,
      OutboxActivitiesTableData,
      $$OutboxActivitiesTableTableFilterComposer,
      $$OutboxActivitiesTableTableOrderingComposer,
      $$OutboxActivitiesTableTableAnnotationComposer,
      $$OutboxActivitiesTableTableCreateCompanionBuilder,
      $$OutboxActivitiesTableTableUpdateCompanionBuilder,
      (
        OutboxActivitiesTableData,
        BaseReferences<
          _$AppDatabase,
          $OutboxActivitiesTableTable,
          OutboxActivitiesTableData
        >,
      ),
      OutboxActivitiesTableData,
      PrefetchHooks Function()
    >;
typedef $$ActorCacheTableTableCreateCompanionBuilder =
    ActorCacheTableCompanion Function({
      Value<int> rowId,
      required String actorUrl,
      required String actorJson,
      Value<DateTime> cachedAt,
      Value<int> ttlSeconds,
      Value<String> discoverySource,
    });
typedef $$ActorCacheTableTableUpdateCompanionBuilder =
    ActorCacheTableCompanion Function({
      Value<int> rowId,
      Value<String> actorUrl,
      Value<String> actorJson,
      Value<DateTime> cachedAt,
      Value<int> ttlSeconds,
      Value<String> discoverySource,
    });

class $$ActorCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $ActorCacheTableTable> {
  $$ActorCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorJson => $composableBuilder(
    column: $table.actorJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ttlSeconds => $composableBuilder(
    column: $table.ttlSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discoverySource => $composableBuilder(
    column: $table.discoverySource,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActorCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ActorCacheTableTable> {
  $$ActorCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorJson => $composableBuilder(
    column: $table.actorJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ttlSeconds => $composableBuilder(
    column: $table.ttlSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discoverySource => $composableBuilder(
    column: $table.discoverySource,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActorCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActorCacheTableTable> {
  $$ActorCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get actorUrl =>
      $composableBuilder(column: $table.actorUrl, builder: (column) => column);

  GeneratedColumn<String> get actorJson =>
      $composableBuilder(column: $table.actorJson, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<int> get ttlSeconds => $composableBuilder(
    column: $table.ttlSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discoverySource => $composableBuilder(
    column: $table.discoverySource,
    builder: (column) => column,
  );
}

class $$ActorCacheTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActorCacheTableTable,
          ActorCacheTableData,
          $$ActorCacheTableTableFilterComposer,
          $$ActorCacheTableTableOrderingComposer,
          $$ActorCacheTableTableAnnotationComposer,
          $$ActorCacheTableTableCreateCompanionBuilder,
          $$ActorCacheTableTableUpdateCompanionBuilder,
          (
            ActorCacheTableData,
            BaseReferences<
              _$AppDatabase,
              $ActorCacheTableTable,
              ActorCacheTableData
            >,
          ),
          ActorCacheTableData,
          PrefetchHooks Function()
        > {
  $$ActorCacheTableTableTableManager(
    _$AppDatabase db,
    $ActorCacheTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActorCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActorCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActorCacheTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> actorUrl = const Value.absent(),
                Value<String> actorJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> ttlSeconds = const Value.absent(),
                Value<String> discoverySource = const Value.absent(),
              }) => ActorCacheTableCompanion(
                rowId: rowId,
                actorUrl: actorUrl,
                actorJson: actorJson,
                cachedAt: cachedAt,
                ttlSeconds: ttlSeconds,
                discoverySource: discoverySource,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String actorUrl,
                required String actorJson,
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> ttlSeconds = const Value.absent(),
                Value<String> discoverySource = const Value.absent(),
              }) => ActorCacheTableCompanion.insert(
                rowId: rowId,
                actorUrl: actorUrl,
                actorJson: actorJson,
                cachedAt: cachedAt,
                ttlSeconds: ttlSeconds,
                discoverySource: discoverySource,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActorCacheTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActorCacheTableTable,
      ActorCacheTableData,
      $$ActorCacheTableTableFilterComposer,
      $$ActorCacheTableTableOrderingComposer,
      $$ActorCacheTableTableAnnotationComposer,
      $$ActorCacheTableTableCreateCompanionBuilder,
      $$ActorCacheTableTableUpdateCompanionBuilder,
      (
        ActorCacheTableData,
        BaseReferences<
          _$AppDatabase,
          $ActorCacheTableTable,
          ActorCacheTableData
        >,
      ),
      ActorCacheTableData,
      PrefetchHooks Function()
    >;
typedef $$FollowersTableTableCreateCompanionBuilder =
    FollowersTableCompanion Function({
      Value<int> rowId,
      required String actorUrl,
      Value<DateTime> followedAt,
    });
typedef $$FollowersTableTableUpdateCompanionBuilder =
    FollowersTableCompanion Function({
      Value<int> rowId,
      Value<String> actorUrl,
      Value<DateTime> followedAt,
    });

class $$FollowersTableTableFilterComposer
    extends Composer<_$AppDatabase, $FollowersTableTable> {
  $$FollowersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get followedAt => $composableBuilder(
    column: $table.followedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FollowersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FollowersTableTable> {
  $$FollowersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get followedAt => $composableBuilder(
    column: $table.followedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FollowersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FollowersTableTable> {
  $$FollowersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get actorUrl =>
      $composableBuilder(column: $table.actorUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get followedAt => $composableBuilder(
    column: $table.followedAt,
    builder: (column) => column,
  );
}

class $$FollowersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FollowersTableTable,
          FollowersTableData,
          $$FollowersTableTableFilterComposer,
          $$FollowersTableTableOrderingComposer,
          $$FollowersTableTableAnnotationComposer,
          $$FollowersTableTableCreateCompanionBuilder,
          $$FollowersTableTableUpdateCompanionBuilder,
          (
            FollowersTableData,
            BaseReferences<
              _$AppDatabase,
              $FollowersTableTable,
              FollowersTableData
            >,
          ),
          FollowersTableData,
          PrefetchHooks Function()
        > {
  $$FollowersTableTableTableManager(
    _$AppDatabase db,
    $FollowersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FollowersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FollowersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FollowersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> actorUrl = const Value.absent(),
                Value<DateTime> followedAt = const Value.absent(),
              }) => FollowersTableCompanion(
                rowId: rowId,
                actorUrl: actorUrl,
                followedAt: followedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String actorUrl,
                Value<DateTime> followedAt = const Value.absent(),
              }) => FollowersTableCompanion.insert(
                rowId: rowId,
                actorUrl: actorUrl,
                followedAt: followedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FollowersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FollowersTableTable,
      FollowersTableData,
      $$FollowersTableTableFilterComposer,
      $$FollowersTableTableOrderingComposer,
      $$FollowersTableTableAnnotationComposer,
      $$FollowersTableTableCreateCompanionBuilder,
      $$FollowersTableTableUpdateCompanionBuilder,
      (
        FollowersTableData,
        BaseReferences<_$AppDatabase, $FollowersTableTable, FollowersTableData>,
      ),
      FollowersTableData,
      PrefetchHooks Function()
    >;
typedef $$FollowingTableTableCreateCompanionBuilder =
    FollowingTableCompanion Function({
      Value<int> rowId,
      required String actorUrl,
      Value<DateTime> followedAt,
    });
typedef $$FollowingTableTableUpdateCompanionBuilder =
    FollowingTableCompanion Function({
      Value<int> rowId,
      Value<String> actorUrl,
      Value<DateTime> followedAt,
    });

class $$FollowingTableTableFilterComposer
    extends Composer<_$AppDatabase, $FollowingTableTable> {
  $$FollowingTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get followedAt => $composableBuilder(
    column: $table.followedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FollowingTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FollowingTableTable> {
  $$FollowingTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get followedAt => $composableBuilder(
    column: $table.followedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FollowingTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FollowingTableTable> {
  $$FollowingTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get actorUrl =>
      $composableBuilder(column: $table.actorUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get followedAt => $composableBuilder(
    column: $table.followedAt,
    builder: (column) => column,
  );
}

class $$FollowingTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FollowingTableTable,
          FollowingTableData,
          $$FollowingTableTableFilterComposer,
          $$FollowingTableTableOrderingComposer,
          $$FollowingTableTableAnnotationComposer,
          $$FollowingTableTableCreateCompanionBuilder,
          $$FollowingTableTableUpdateCompanionBuilder,
          (
            FollowingTableData,
            BaseReferences<
              _$AppDatabase,
              $FollowingTableTable,
              FollowingTableData
            >,
          ),
          FollowingTableData,
          PrefetchHooks Function()
        > {
  $$FollowingTableTableTableManager(
    _$AppDatabase db,
    $FollowingTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FollowingTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FollowingTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FollowingTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> actorUrl = const Value.absent(),
                Value<DateTime> followedAt = const Value.absent(),
              }) => FollowingTableCompanion(
                rowId: rowId,
                actorUrl: actorUrl,
                followedAt: followedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String actorUrl,
                Value<DateTime> followedAt = const Value.absent(),
              }) => FollowingTableCompanion.insert(
                rowId: rowId,
                actorUrl: actorUrl,
                followedAt: followedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FollowingTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FollowingTableTable,
      FollowingTableData,
      $$FollowingTableTableFilterComposer,
      $$FollowingTableTableOrderingComposer,
      $$FollowingTableTableAnnotationComposer,
      $$FollowingTableTableCreateCompanionBuilder,
      $$FollowingTableTableUpdateCompanionBuilder,
      (
        FollowingTableData,
        BaseReferences<_$AppDatabase, $FollowingTableTable, FollowingTableData>,
      ),
      FollowingTableData,
      PrefetchHooks Function()
    >;
typedef $$DefederatedNodesTableTableCreateCompanionBuilder =
    DefederatedNodesTableCompanion Function({
      Value<int> rowId,
      required String domain,
      Value<DateTime> blockedAt,
    });
typedef $$DefederatedNodesTableTableUpdateCompanionBuilder =
    DefederatedNodesTableCompanion Function({
      Value<int> rowId,
      Value<String> domain,
      Value<DateTime> blockedAt,
    });

class $$DefederatedNodesTableTableFilterComposer
    extends Composer<_$AppDatabase, $DefederatedNodesTableTable> {
  $$DefederatedNodesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get blockedAt => $composableBuilder(
    column: $table.blockedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DefederatedNodesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DefederatedNodesTableTable> {
  $$DefederatedNodesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get blockedAt => $composableBuilder(
    column: $table.blockedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DefederatedNodesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DefederatedNodesTableTable> {
  $$DefederatedNodesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<DateTime> get blockedAt =>
      $composableBuilder(column: $table.blockedAt, builder: (column) => column);
}

class $$DefederatedNodesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DefederatedNodesTableTable,
          DefederatedNodesTableData,
          $$DefederatedNodesTableTableFilterComposer,
          $$DefederatedNodesTableTableOrderingComposer,
          $$DefederatedNodesTableTableAnnotationComposer,
          $$DefederatedNodesTableTableCreateCompanionBuilder,
          $$DefederatedNodesTableTableUpdateCompanionBuilder,
          (
            DefederatedNodesTableData,
            BaseReferences<
              _$AppDatabase,
              $DefederatedNodesTableTable,
              DefederatedNodesTableData
            >,
          ),
          DefederatedNodesTableData,
          PrefetchHooks Function()
        > {
  $$DefederatedNodesTableTableTableManager(
    _$AppDatabase db,
    $DefederatedNodesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DefederatedNodesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DefederatedNodesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DefederatedNodesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<DateTime> blockedAt = const Value.absent(),
              }) => DefederatedNodesTableCompanion(
                rowId: rowId,
                domain: domain,
                blockedAt: blockedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String domain,
                Value<DateTime> blockedAt = const Value.absent(),
              }) => DefederatedNodesTableCompanion.insert(
                rowId: rowId,
                domain: domain,
                blockedAt: blockedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DefederatedNodesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DefederatedNodesTableTable,
      DefederatedNodesTableData,
      $$DefederatedNodesTableTableFilterComposer,
      $$DefederatedNodesTableTableOrderingComposer,
      $$DefederatedNodesTableTableAnnotationComposer,
      $$DefederatedNodesTableTableCreateCompanionBuilder,
      $$DefederatedNodesTableTableUpdateCompanionBuilder,
      (
        DefederatedNodesTableData,
        BaseReferences<
          _$AppDatabase,
          $DefederatedNodesTableTable,
          DefederatedNodesTableData
        >,
      ),
      DefederatedNodesTableData,
      PrefetchHooks Function()
    >;
typedef $$NodeAllowDenyListTableTableCreateCompanionBuilder =
    NodeAllowDenyListTableCompanion Function({
      Value<int> rowId,
      required String domain,
      required String policy,
      Value<DateTime> createdAt,
    });
typedef $$NodeAllowDenyListTableTableUpdateCompanionBuilder =
    NodeAllowDenyListTableCompanion Function({
      Value<int> rowId,
      Value<String> domain,
      Value<String> policy,
      Value<DateTime> createdAt,
    });

class $$NodeAllowDenyListTableTableFilterComposer
    extends Composer<_$AppDatabase, $NodeAllowDenyListTableTable> {
  $$NodeAllowDenyListTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get policy => $composableBuilder(
    column: $table.policy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NodeAllowDenyListTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NodeAllowDenyListTableTable> {
  $$NodeAllowDenyListTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get policy => $composableBuilder(
    column: $table.policy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NodeAllowDenyListTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodeAllowDenyListTableTable> {
  $$NodeAllowDenyListTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get policy =>
      $composableBuilder(column: $table.policy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NodeAllowDenyListTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodeAllowDenyListTableTable,
          NodeAllowDenyListTableData,
          $$NodeAllowDenyListTableTableFilterComposer,
          $$NodeAllowDenyListTableTableOrderingComposer,
          $$NodeAllowDenyListTableTableAnnotationComposer,
          $$NodeAllowDenyListTableTableCreateCompanionBuilder,
          $$NodeAllowDenyListTableTableUpdateCompanionBuilder,
          (
            NodeAllowDenyListTableData,
            BaseReferences<
              _$AppDatabase,
              $NodeAllowDenyListTableTable,
              NodeAllowDenyListTableData
            >,
          ),
          NodeAllowDenyListTableData,
          PrefetchHooks Function()
        > {
  $$NodeAllowDenyListTableTableTableManager(
    _$AppDatabase db,
    $NodeAllowDenyListTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodeAllowDenyListTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$NodeAllowDenyListTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NodeAllowDenyListTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<String> policy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => NodeAllowDenyListTableCompanion(
                rowId: rowId,
                domain: domain,
                policy: policy,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String domain,
                required String policy,
                Value<DateTime> createdAt = const Value.absent(),
              }) => NodeAllowDenyListTableCompanion.insert(
                rowId: rowId,
                domain: domain,
                policy: policy,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NodeAllowDenyListTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodeAllowDenyListTableTable,
      NodeAllowDenyListTableData,
      $$NodeAllowDenyListTableTableFilterComposer,
      $$NodeAllowDenyListTableTableOrderingComposer,
      $$NodeAllowDenyListTableTableAnnotationComposer,
      $$NodeAllowDenyListTableTableCreateCompanionBuilder,
      $$NodeAllowDenyListTableTableUpdateCompanionBuilder,
      (
        NodeAllowDenyListTableData,
        BaseReferences<
          _$AppDatabase,
          $NodeAllowDenyListTableTable,
          NodeAllowDenyListTableData
        >,
      ),
      NodeAllowDenyListTableData,
      PrefetchHooks Function()
    >;
typedef $$MigrationTokensTableTableCreateCompanionBuilder =
    MigrationTokensTableCompanion Function({
      Value<int> rowId,
      required String tokenHash,
      Value<String?> newActorUrl,
      Value<DateTime?> usedAt,
      Value<DateTime> createdAt,
    });
typedef $$MigrationTokensTableTableUpdateCompanionBuilder =
    MigrationTokensTableCompanion Function({
      Value<int> rowId,
      Value<String> tokenHash,
      Value<String?> newActorUrl,
      Value<DateTime?> usedAt,
      Value<DateTime> createdAt,
    });

class $$MigrationTokensTableTableFilterComposer
    extends Composer<_$AppDatabase, $MigrationTokensTableTable> {
  $$MigrationTokensTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tokenHash => $composableBuilder(
    column: $table.tokenHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newActorUrl => $composableBuilder(
    column: $table.newActorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get usedAt => $composableBuilder(
    column: $table.usedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MigrationTokensTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MigrationTokensTableTable> {
  $$MigrationTokensTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tokenHash => $composableBuilder(
    column: $table.tokenHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newActorUrl => $composableBuilder(
    column: $table.newActorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get usedAt => $composableBuilder(
    column: $table.usedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MigrationTokensTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MigrationTokensTableTable> {
  $$MigrationTokensTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get tokenHash =>
      $composableBuilder(column: $table.tokenHash, builder: (column) => column);

  GeneratedColumn<String> get newActorUrl => $composableBuilder(
    column: $table.newActorUrl,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get usedAt =>
      $composableBuilder(column: $table.usedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MigrationTokensTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MigrationTokensTableTable,
          MigrationTokensTableData,
          $$MigrationTokensTableTableFilterComposer,
          $$MigrationTokensTableTableOrderingComposer,
          $$MigrationTokensTableTableAnnotationComposer,
          $$MigrationTokensTableTableCreateCompanionBuilder,
          $$MigrationTokensTableTableUpdateCompanionBuilder,
          (
            MigrationTokensTableData,
            BaseReferences<
              _$AppDatabase,
              $MigrationTokensTableTable,
              MigrationTokensTableData
            >,
          ),
          MigrationTokensTableData,
          PrefetchHooks Function()
        > {
  $$MigrationTokensTableTableTableManager(
    _$AppDatabase db,
    $MigrationTokensTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MigrationTokensTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MigrationTokensTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MigrationTokensTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> tokenHash = const Value.absent(),
                Value<String?> newActorUrl = const Value.absent(),
                Value<DateTime?> usedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MigrationTokensTableCompanion(
                rowId: rowId,
                tokenHash: tokenHash,
                newActorUrl: newActorUrl,
                usedAt: usedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String tokenHash,
                Value<String?> newActorUrl = const Value.absent(),
                Value<DateTime?> usedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MigrationTokensTableCompanion.insert(
                rowId: rowId,
                tokenHash: tokenHash,
                newActorUrl: newActorUrl,
                usedAt: usedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MigrationTokensTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MigrationTokensTableTable,
      MigrationTokensTableData,
      $$MigrationTokensTableTableFilterComposer,
      $$MigrationTokensTableTableOrderingComposer,
      $$MigrationTokensTableTableAnnotationComposer,
      $$MigrationTokensTableTableCreateCompanionBuilder,
      $$MigrationTokensTableTableUpdateCompanionBuilder,
      (
        MigrationTokensTableData,
        BaseReferences<
          _$AppDatabase,
          $MigrationTokensTableTable,
          MigrationTokensTableData
        >,
      ),
      MigrationTokensTableData,
      PrefetchHooks Function()
    >;
typedef $$RemoteLibrariesTableTableCreateCompanionBuilder =
    RemoteLibrariesTableCompanion Function({
      required String actorUrl,
      required String collectionJson,
      Value<DateTime> fetchedAt,
      Value<String?> etag,
      Value<int> rowid,
    });
typedef $$RemoteLibrariesTableTableUpdateCompanionBuilder =
    RemoteLibrariesTableCompanion Function({
      Value<String> actorUrl,
      Value<String> collectionJson,
      Value<DateTime> fetchedAt,
      Value<String?> etag,
      Value<int> rowid,
    });

class $$RemoteLibrariesTableTableFilterComposer
    extends Composer<_$AppDatabase, $RemoteLibrariesTableTable> {
  $$RemoteLibrariesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectionJson => $composableBuilder(
    column: $table.collectionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemoteLibrariesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RemoteLibrariesTableTable> {
  $$RemoteLibrariesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectionJson => $composableBuilder(
    column: $table.collectionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemoteLibrariesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemoteLibrariesTableTable> {
  $$RemoteLibrariesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get actorUrl =>
      $composableBuilder(column: $table.actorUrl, builder: (column) => column);

  GeneratedColumn<String> get collectionJson => $composableBuilder(
    column: $table.collectionJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);
}

class $$RemoteLibrariesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemoteLibrariesTableTable,
          RemoteLibrariesTableData,
          $$RemoteLibrariesTableTableFilterComposer,
          $$RemoteLibrariesTableTableOrderingComposer,
          $$RemoteLibrariesTableTableAnnotationComposer,
          $$RemoteLibrariesTableTableCreateCompanionBuilder,
          $$RemoteLibrariesTableTableUpdateCompanionBuilder,
          (
            RemoteLibrariesTableData,
            BaseReferences<
              _$AppDatabase,
              $RemoteLibrariesTableTable,
              RemoteLibrariesTableData
            >,
          ),
          RemoteLibrariesTableData,
          PrefetchHooks Function()
        > {
  $$RemoteLibrariesTableTableTableManager(
    _$AppDatabase db,
    $RemoteLibrariesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteLibrariesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemoteLibrariesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RemoteLibrariesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> actorUrl = const Value.absent(),
                Value<String> collectionJson = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteLibrariesTableCompanion(
                actorUrl: actorUrl,
                collectionJson: collectionJson,
                fetchedAt: fetchedAt,
                etag: etag,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String actorUrl,
                required String collectionJson,
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteLibrariesTableCompanion.insert(
                actorUrl: actorUrl,
                collectionJson: collectionJson,
                fetchedAt: fetchedAt,
                etag: etag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemoteLibrariesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemoteLibrariesTableTable,
      RemoteLibrariesTableData,
      $$RemoteLibrariesTableTableFilterComposer,
      $$RemoteLibrariesTableTableOrderingComposer,
      $$RemoteLibrariesTableTableAnnotationComposer,
      $$RemoteLibrariesTableTableCreateCompanionBuilder,
      $$RemoteLibrariesTableTableUpdateCompanionBuilder,
      (
        RemoteLibrariesTableData,
        BaseReferences<
          _$AppDatabase,
          $RemoteLibrariesTableTable,
          RemoteLibrariesTableData
        >,
      ),
      RemoteLibrariesTableData,
      PrefetchHooks Function()
    >;
typedef $$AudioCacheTableTableCreateCompanionBuilder =
    AudioCacheTableCompanion Function({
      required String trackId,
      required String sourceActorUrl,
      required String localPath,
      Value<DateTime> fetchedAt,
      Value<DateTime> lastAccessed,
      required int sizeBytes,
      Value<bool> isPinned,
      Value<int> rowid,
    });
typedef $$AudioCacheTableTableUpdateCompanionBuilder =
    AudioCacheTableCompanion Function({
      Value<String> trackId,
      Value<String> sourceActorUrl,
      Value<String> localPath,
      Value<DateTime> fetchedAt,
      Value<DateTime> lastAccessed,
      Value<int> sizeBytes,
      Value<bool> isPinned,
      Value<int> rowid,
    });

class $$AudioCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $AudioCacheTableTable> {
  $$AudioCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceActorUrl => $composableBuilder(
    column: $table.sourceActorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAccessed => $composableBuilder(
    column: $table.lastAccessed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AudioCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AudioCacheTableTable> {
  $$AudioCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceActorUrl => $composableBuilder(
    column: $table.sourceActorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAccessed => $composableBuilder(
    column: $table.lastAccessed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AudioCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AudioCacheTableTable> {
  $$AudioCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get sourceActorUrl => $composableBuilder(
    column: $table.sourceActorUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessed => $composableBuilder(
    column: $table.lastAccessed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);
}

class $$AudioCacheTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AudioCacheTableTable,
          AudioCacheTableData,
          $$AudioCacheTableTableFilterComposer,
          $$AudioCacheTableTableOrderingComposer,
          $$AudioCacheTableTableAnnotationComposer,
          $$AudioCacheTableTableCreateCompanionBuilder,
          $$AudioCacheTableTableUpdateCompanionBuilder,
          (
            AudioCacheTableData,
            BaseReferences<
              _$AppDatabase,
              $AudioCacheTableTable,
              AudioCacheTableData
            >,
          ),
          AudioCacheTableData,
          PrefetchHooks Function()
        > {
  $$AudioCacheTableTableTableManager(
    _$AppDatabase db,
    $AudioCacheTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioCacheTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> trackId = const Value.absent(),
                Value<String> sourceActorUrl = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<DateTime> lastAccessed = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AudioCacheTableCompanion(
                trackId: trackId,
                sourceActorUrl: sourceActorUrl,
                localPath: localPath,
                fetchedAt: fetchedAt,
                lastAccessed: lastAccessed,
                sizeBytes: sizeBytes,
                isPinned: isPinned,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trackId,
                required String sourceActorUrl,
                required String localPath,
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<DateTime> lastAccessed = const Value.absent(),
                required int sizeBytes,
                Value<bool> isPinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AudioCacheTableCompanion.insert(
                trackId: trackId,
                sourceActorUrl: sourceActorUrl,
                localPath: localPath,
                fetchedAt: fetchedAt,
                lastAccessed: lastAccessed,
                sizeBytes: sizeBytes,
                isPinned: isPinned,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AudioCacheTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AudioCacheTableTable,
      AudioCacheTableData,
      $$AudioCacheTableTableFilterComposer,
      $$AudioCacheTableTableOrderingComposer,
      $$AudioCacheTableTableAnnotationComposer,
      $$AudioCacheTableTableCreateCompanionBuilder,
      $$AudioCacheTableTableUpdateCompanionBuilder,
      (
        AudioCacheTableData,
        BaseReferences<
          _$AppDatabase,
          $AudioCacheTableTable,
          AudioCacheTableData
        >,
      ),
      AudioCacheTableData,
      PrefetchHooks Function()
    >;
typedef $$ListenActivitiesTableTableCreateCompanionBuilder =
    ListenActivitiesTableCompanion Function({
      Value<int> rowId,
      required String actorUrl,
      required String trackId,
      required String trackTitle,
      required String trackArtist,
      Value<DateTime> listenedAt,
      Value<int> durationMs,
    });
typedef $$ListenActivitiesTableTableUpdateCompanionBuilder =
    ListenActivitiesTableCompanion Function({
      Value<int> rowId,
      Value<String> actorUrl,
      Value<String> trackId,
      Value<String> trackTitle,
      Value<String> trackArtist,
      Value<DateTime> listenedAt,
      Value<int> durationMs,
    });

class $$ListenActivitiesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ListenActivitiesTableTable> {
  $$ListenActivitiesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackTitle => $composableBuilder(
    column: $table.trackTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackArtist => $composableBuilder(
    column: $table.trackArtist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get listenedAt => $composableBuilder(
    column: $table.listenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ListenActivitiesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ListenActivitiesTableTable> {
  $$ListenActivitiesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackTitle => $composableBuilder(
    column: $table.trackTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackArtist => $composableBuilder(
    column: $table.trackArtist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get listenedAt => $composableBuilder(
    column: $table.listenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListenActivitiesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListenActivitiesTableTable> {
  $$ListenActivitiesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get actorUrl =>
      $composableBuilder(column: $table.actorUrl, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get trackTitle => $composableBuilder(
    column: $table.trackTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackArtist => $composableBuilder(
    column: $table.trackArtist,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get listenedAt => $composableBuilder(
    column: $table.listenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );
}

class $$ListenActivitiesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListenActivitiesTableTable,
          ListenActivitiesTableData,
          $$ListenActivitiesTableTableFilterComposer,
          $$ListenActivitiesTableTableOrderingComposer,
          $$ListenActivitiesTableTableAnnotationComposer,
          $$ListenActivitiesTableTableCreateCompanionBuilder,
          $$ListenActivitiesTableTableUpdateCompanionBuilder,
          (
            ListenActivitiesTableData,
            BaseReferences<
              _$AppDatabase,
              $ListenActivitiesTableTable,
              ListenActivitiesTableData
            >,
          ),
          ListenActivitiesTableData,
          PrefetchHooks Function()
        > {
  $$ListenActivitiesTableTableTableManager(
    _$AppDatabase db,
    $ListenActivitiesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListenActivitiesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ListenActivitiesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ListenActivitiesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> actorUrl = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<String> trackTitle = const Value.absent(),
                Value<String> trackArtist = const Value.absent(),
                Value<DateTime> listenedAt = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
              }) => ListenActivitiesTableCompanion(
                rowId: rowId,
                actorUrl: actorUrl,
                trackId: trackId,
                trackTitle: trackTitle,
                trackArtist: trackArtist,
                listenedAt: listenedAt,
                durationMs: durationMs,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String actorUrl,
                required String trackId,
                required String trackTitle,
                required String trackArtist,
                Value<DateTime> listenedAt = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
              }) => ListenActivitiesTableCompanion.insert(
                rowId: rowId,
                actorUrl: actorUrl,
                trackId: trackId,
                trackTitle: trackTitle,
                trackArtist: trackArtist,
                listenedAt: listenedAt,
                durationMs: durationMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ListenActivitiesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListenActivitiesTableTable,
      ListenActivitiesTableData,
      $$ListenActivitiesTableTableFilterComposer,
      $$ListenActivitiesTableTableOrderingComposer,
      $$ListenActivitiesTableTableAnnotationComposer,
      $$ListenActivitiesTableTableCreateCompanionBuilder,
      $$ListenActivitiesTableTableUpdateCompanionBuilder,
      (
        ListenActivitiesTableData,
        BaseReferences<
          _$AppDatabase,
          $ListenActivitiesTableTable,
          ListenActivitiesTableData
        >,
      ),
      ListenActivitiesTableData,
      PrefetchHooks Function()
    >;
typedef $$FingerprintsTableTableCreateCompanionBuilder =
    FingerprintsTableCompanion Function({
      Value<int> trackId,
      required String chromaprintHash,
      required int durationMs,
      Value<DateTime> computedAt,
    });
typedef $$FingerprintsTableTableUpdateCompanionBuilder =
    FingerprintsTableCompanion Function({
      Value<int> trackId,
      Value<String> chromaprintHash,
      Value<int> durationMs,
      Value<DateTime> computedAt,
    });

class $$FingerprintsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FingerprintsTableTable> {
  $$FingerprintsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chromaprintHash => $composableBuilder(
    column: $table.chromaprintHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FingerprintsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FingerprintsTableTable> {
  $$FingerprintsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chromaprintHash => $composableBuilder(
    column: $table.chromaprintHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FingerprintsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FingerprintsTableTable> {
  $$FingerprintsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get chromaprintHash => $composableBuilder(
    column: $table.chromaprintHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => column,
  );
}

class $$FingerprintsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FingerprintsTableTable,
          FingerprintsTableData,
          $$FingerprintsTableTableFilterComposer,
          $$FingerprintsTableTableOrderingComposer,
          $$FingerprintsTableTableAnnotationComposer,
          $$FingerprintsTableTableCreateCompanionBuilder,
          $$FingerprintsTableTableUpdateCompanionBuilder,
          (
            FingerprintsTableData,
            BaseReferences<
              _$AppDatabase,
              $FingerprintsTableTable,
              FingerprintsTableData
            >,
          ),
          FingerprintsTableData,
          PrefetchHooks Function()
        > {
  $$FingerprintsTableTableTableManager(
    _$AppDatabase db,
    $FingerprintsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FingerprintsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FingerprintsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FingerprintsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> trackId = const Value.absent(),
                Value<String> chromaprintHash = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> computedAt = const Value.absent(),
              }) => FingerprintsTableCompanion(
                trackId: trackId,
                chromaprintHash: chromaprintHash,
                durationMs: durationMs,
                computedAt: computedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> trackId = const Value.absent(),
                required String chromaprintHash,
                required int durationMs,
                Value<DateTime> computedAt = const Value.absent(),
              }) => FingerprintsTableCompanion.insert(
                trackId: trackId,
                chromaprintHash: chromaprintHash,
                durationMs: durationMs,
                computedAt: computedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FingerprintsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FingerprintsTableTable,
      FingerprintsTableData,
      $$FingerprintsTableTableFilterComposer,
      $$FingerprintsTableTableOrderingComposer,
      $$FingerprintsTableTableAnnotationComposer,
      $$FingerprintsTableTableCreateCompanionBuilder,
      $$FingerprintsTableTableUpdateCompanionBuilder,
      (
        FingerprintsTableData,
        BaseReferences<
          _$AppDatabase,
          $FingerprintsTableTable,
          FingerprintsTableData
        >,
      ),
      FingerprintsTableData,
      PrefetchHooks Function()
    >;
typedef $$MergeProvenanceTableTableCreateCompanionBuilder =
    MergeProvenanceTableCompanion Function({
      Value<int> rowId,
      required String fingerprintA,
      required String fingerprintB,
      required double similarityScore,
      Value<DateTime> mergedAt,
      Value<DateTime?> undoneAt,
      required String reason,
    });
typedef $$MergeProvenanceTableTableUpdateCompanionBuilder =
    MergeProvenanceTableCompanion Function({
      Value<int> rowId,
      Value<String> fingerprintA,
      Value<String> fingerprintB,
      Value<double> similarityScore,
      Value<DateTime> mergedAt,
      Value<DateTime?> undoneAt,
      Value<String> reason,
    });

class $$MergeProvenanceTableTableFilterComposer
    extends Composer<_$AppDatabase, $MergeProvenanceTableTable> {
  $$MergeProvenanceTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprintA => $composableBuilder(
    column: $table.fingerprintA,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprintB => $composableBuilder(
    column: $table.fingerprintB,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get similarityScore => $composableBuilder(
    column: $table.similarityScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get mergedAt => $composableBuilder(
    column: $table.mergedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get undoneAt => $composableBuilder(
    column: $table.undoneAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MergeProvenanceTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MergeProvenanceTableTable> {
  $$MergeProvenanceTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprintA => $composableBuilder(
    column: $table.fingerprintA,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprintB => $composableBuilder(
    column: $table.fingerprintB,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get similarityScore => $composableBuilder(
    column: $table.similarityScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get mergedAt => $composableBuilder(
    column: $table.mergedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get undoneAt => $composableBuilder(
    column: $table.undoneAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MergeProvenanceTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MergeProvenanceTableTable> {
  $$MergeProvenanceTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get fingerprintA => $composableBuilder(
    column: $table.fingerprintA,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fingerprintB => $composableBuilder(
    column: $table.fingerprintB,
    builder: (column) => column,
  );

  GeneratedColumn<double> get similarityScore => $composableBuilder(
    column: $table.similarityScore,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get mergedAt =>
      $composableBuilder(column: $table.mergedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get undoneAt =>
      $composableBuilder(column: $table.undoneAt, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);
}

class $$MergeProvenanceTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MergeProvenanceTableTable,
          MergeProvenanceTableData,
          $$MergeProvenanceTableTableFilterComposer,
          $$MergeProvenanceTableTableOrderingComposer,
          $$MergeProvenanceTableTableAnnotationComposer,
          $$MergeProvenanceTableTableCreateCompanionBuilder,
          $$MergeProvenanceTableTableUpdateCompanionBuilder,
          (
            MergeProvenanceTableData,
            BaseReferences<
              _$AppDatabase,
              $MergeProvenanceTableTable,
              MergeProvenanceTableData
            >,
          ),
          MergeProvenanceTableData,
          PrefetchHooks Function()
        > {
  $$MergeProvenanceTableTableTableManager(
    _$AppDatabase db,
    $MergeProvenanceTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MergeProvenanceTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MergeProvenanceTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MergeProvenanceTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> fingerprintA = const Value.absent(),
                Value<String> fingerprintB = const Value.absent(),
                Value<double> similarityScore = const Value.absent(),
                Value<DateTime> mergedAt = const Value.absent(),
                Value<DateTime?> undoneAt = const Value.absent(),
                Value<String> reason = const Value.absent(),
              }) => MergeProvenanceTableCompanion(
                rowId: rowId,
                fingerprintA: fingerprintA,
                fingerprintB: fingerprintB,
                similarityScore: similarityScore,
                mergedAt: mergedAt,
                undoneAt: undoneAt,
                reason: reason,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String fingerprintA,
                required String fingerprintB,
                required double similarityScore,
                Value<DateTime> mergedAt = const Value.absent(),
                Value<DateTime?> undoneAt = const Value.absent(),
                required String reason,
              }) => MergeProvenanceTableCompanion.insert(
                rowId: rowId,
                fingerprintA: fingerprintA,
                fingerprintB: fingerprintB,
                similarityScore: similarityScore,
                mergedAt: mergedAt,
                undoneAt: undoneAt,
                reason: reason,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MergeProvenanceTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MergeProvenanceTableTable,
      MergeProvenanceTableData,
      $$MergeProvenanceTableTableFilterComposer,
      $$MergeProvenanceTableTableOrderingComposer,
      $$MergeProvenanceTableTableAnnotationComposer,
      $$MergeProvenanceTableTableCreateCompanionBuilder,
      $$MergeProvenanceTableTableUpdateCompanionBuilder,
      (
        MergeProvenanceTableData,
        BaseReferences<
          _$AppDatabase,
          $MergeProvenanceTableTable,
          MergeProvenanceTableData
        >,
      ),
      MergeProvenanceTableData,
      PrefetchHooks Function()
    >;
typedef $$FollowsTableTableCreateCompanionBuilder =
    FollowsTableCompanion Function({
      Value<int> rowId,
      required String localActorId,
      required String remoteActorUrl,
      Value<String> state,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$FollowsTableTableUpdateCompanionBuilder =
    FollowsTableCompanion Function({
      Value<int> rowId,
      Value<String> localActorId,
      Value<String> remoteActorUrl,
      Value<String> state,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$FollowsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FollowsTableTable> {
  $$FollowsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localActorId => $composableBuilder(
    column: $table.localActorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteActorUrl => $composableBuilder(
    column: $table.remoteActorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FollowsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FollowsTableTable> {
  $$FollowsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localActorId => $composableBuilder(
    column: $table.localActorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteActorUrl => $composableBuilder(
    column: $table.remoteActorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FollowsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FollowsTableTable> {
  $$FollowsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get localActorId => $composableBuilder(
    column: $table.localActorId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteActorUrl => $composableBuilder(
    column: $table.remoteActorUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FollowsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FollowsTableTable,
          FollowsTableData,
          $$FollowsTableTableFilterComposer,
          $$FollowsTableTableOrderingComposer,
          $$FollowsTableTableAnnotationComposer,
          $$FollowsTableTableCreateCompanionBuilder,
          $$FollowsTableTableUpdateCompanionBuilder,
          (
            FollowsTableData,
            BaseReferences<_$AppDatabase, $FollowsTableTable, FollowsTableData>,
          ),
          FollowsTableData,
          PrefetchHooks Function()
        > {
  $$FollowsTableTableTableManager(_$AppDatabase db, $FollowsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FollowsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FollowsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FollowsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> localActorId = const Value.absent(),
                Value<String> remoteActorUrl = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FollowsTableCompanion(
                rowId: rowId,
                localActorId: localActorId,
                remoteActorUrl: remoteActorUrl,
                state: state,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String localActorId,
                required String remoteActorUrl,
                Value<String> state = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FollowsTableCompanion.insert(
                rowId: rowId,
                localActorId: localActorId,
                remoteActorUrl: remoteActorUrl,
                state: state,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FollowsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FollowsTableTable,
      FollowsTableData,
      $$FollowsTableTableFilterComposer,
      $$FollowsTableTableOrderingComposer,
      $$FollowsTableTableAnnotationComposer,
      $$FollowsTableTableCreateCompanionBuilder,
      $$FollowsTableTableUpdateCompanionBuilder,
      (
        FollowsTableData,
        BaseReferences<_$AppDatabase, $FollowsTableTable, FollowsTableData>,
      ),
      FollowsTableData,
      PrefetchHooks Function()
    >;
typedef $$FollowRequestsTableTableCreateCompanionBuilder =
    FollowRequestsTableCompanion Function({
      Value<int> rowId,
      required String direction,
      required String actorUrl,
      Value<String> state,
      Value<String?> activityId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$FollowRequestsTableTableUpdateCompanionBuilder =
    FollowRequestsTableCompanion Function({
      Value<int> rowId,
      Value<String> direction,
      Value<String> actorUrl,
      Value<String> state,
      Value<String?> activityId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$FollowRequestsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FollowRequestsTableTable> {
  $$FollowRequestsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FollowRequestsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FollowRequestsTableTable> {
  $$FollowRequestsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FollowRequestsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FollowRequestsTableTable> {
  $$FollowRequestsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get actorUrl =>
      $composableBuilder(column: $table.actorUrl, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FollowRequestsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FollowRequestsTableTable,
          FollowRequestsTableData,
          $$FollowRequestsTableTableFilterComposer,
          $$FollowRequestsTableTableOrderingComposer,
          $$FollowRequestsTableTableAnnotationComposer,
          $$FollowRequestsTableTableCreateCompanionBuilder,
          $$FollowRequestsTableTableUpdateCompanionBuilder,
          (
            FollowRequestsTableData,
            BaseReferences<
              _$AppDatabase,
              $FollowRequestsTableTable,
              FollowRequestsTableData
            >,
          ),
          FollowRequestsTableData,
          PrefetchHooks Function()
        > {
  $$FollowRequestsTableTableTableManager(
    _$AppDatabase db,
    $FollowRequestsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FollowRequestsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FollowRequestsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FollowRequestsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> actorUrl = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> activityId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FollowRequestsTableCompanion(
                rowId: rowId,
                direction: direction,
                actorUrl: actorUrl,
                state: state,
                activityId: activityId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String direction,
                required String actorUrl,
                Value<String> state = const Value.absent(),
                Value<String?> activityId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FollowRequestsTableCompanion.insert(
                rowId: rowId,
                direction: direction,
                actorUrl: actorUrl,
                state: state,
                activityId: activityId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FollowRequestsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FollowRequestsTableTable,
      FollowRequestsTableData,
      $$FollowRequestsTableTableFilterComposer,
      $$FollowRequestsTableTableOrderingComposer,
      $$FollowRequestsTableTableAnnotationComposer,
      $$FollowRequestsTableTableCreateCompanionBuilder,
      $$FollowRequestsTableTableUpdateCompanionBuilder,
      (
        FollowRequestsTableData,
        BaseReferences<
          _$AppDatabase,
          $FollowRequestsTableTable,
          FollowRequestsTableData
        >,
      ),
      FollowRequestsTableData,
      PrefetchHooks Function()
    >;
typedef $$BlocksTableTableCreateCompanionBuilder =
    BlocksTableCompanion Function({
      Value<int> rowId,
      required String actorUrl,
      Value<DateTime> createdAt,
    });
typedef $$BlocksTableTableUpdateCompanionBuilder =
    BlocksTableCompanion Function({
      Value<int> rowId,
      Value<String> actorUrl,
      Value<DateTime> createdAt,
    });

class $$BlocksTableTableFilterComposer
    extends Composer<_$AppDatabase, $BlocksTableTable> {
  $$BlocksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BlocksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BlocksTableTable> {
  $$BlocksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BlocksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlocksTableTable> {
  $$BlocksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get actorUrl =>
      $composableBuilder(column: $table.actorUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BlocksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BlocksTableTable,
          BlocksTableData,
          $$BlocksTableTableFilterComposer,
          $$BlocksTableTableOrderingComposer,
          $$BlocksTableTableAnnotationComposer,
          $$BlocksTableTableCreateCompanionBuilder,
          $$BlocksTableTableUpdateCompanionBuilder,
          (
            BlocksTableData,
            BaseReferences<_$AppDatabase, $BlocksTableTable, BlocksTableData>,
          ),
          BlocksTableData,
          PrefetchHooks Function()
        > {
  $$BlocksTableTableTableManager(_$AppDatabase db, $BlocksTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlocksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlocksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlocksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> actorUrl = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BlocksTableCompanion(
                rowId: rowId,
                actorUrl: actorUrl,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String actorUrl,
                Value<DateTime> createdAt = const Value.absent(),
              }) => BlocksTableCompanion.insert(
                rowId: rowId,
                actorUrl: actorUrl,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BlocksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BlocksTableTable,
      BlocksTableData,
      $$BlocksTableTableFilterComposer,
      $$BlocksTableTableOrderingComposer,
      $$BlocksTableTableAnnotationComposer,
      $$BlocksTableTableCreateCompanionBuilder,
      $$BlocksTableTableUpdateCompanionBuilder,
      (
        BlocksTableData,
        BaseReferences<_$AppDatabase, $BlocksTableTable, BlocksTableData>,
      ),
      BlocksTableData,
      PrefetchHooks Function()
    >;
typedef $$MutesTableTableCreateCompanionBuilder =
    MutesTableCompanion Function({
      Value<int> rowId,
      required String actorUrl,
      Value<DateTime> createdAt,
    });
typedef $$MutesTableTableUpdateCompanionBuilder =
    MutesTableCompanion Function({
      Value<int> rowId,
      Value<String> actorUrl,
      Value<DateTime> createdAt,
    });

class $$MutesTableTableFilterComposer
    extends Composer<_$AppDatabase, $MutesTableTable> {
  $$MutesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MutesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MutesTableTable> {
  $$MutesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MutesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MutesTableTable> {
  $$MutesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get actorUrl =>
      $composableBuilder(column: $table.actorUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MutesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MutesTableTable,
          MutesTableData,
          $$MutesTableTableFilterComposer,
          $$MutesTableTableOrderingComposer,
          $$MutesTableTableAnnotationComposer,
          $$MutesTableTableCreateCompanionBuilder,
          $$MutesTableTableUpdateCompanionBuilder,
          (
            MutesTableData,
            BaseReferences<_$AppDatabase, $MutesTableTable, MutesTableData>,
          ),
          MutesTableData,
          PrefetchHooks Function()
        > {
  $$MutesTableTableTableManager(_$AppDatabase db, $MutesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MutesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MutesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MutesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> actorUrl = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MutesTableCompanion(
                rowId: rowId,
                actorUrl: actorUrl,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String actorUrl,
                Value<DateTime> createdAt = const Value.absent(),
              }) => MutesTableCompanion.insert(
                rowId: rowId,
                actorUrl: actorUrl,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MutesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MutesTableTable,
      MutesTableData,
      $$MutesTableTableFilterComposer,
      $$MutesTableTableOrderingComposer,
      $$MutesTableTableAnnotationComposer,
      $$MutesTableTableCreateCompanionBuilder,
      $$MutesTableTableUpdateCompanionBuilder,
      (
        MutesTableData,
        BaseReferences<_$AppDatabase, $MutesTableTable, MutesTableData>,
      ),
      MutesTableData,
      PrefetchHooks Function()
    >;
typedef $$SocialActivitiesTableTableCreateCompanionBuilder =
    SocialActivitiesTableCompanion Function({
      Value<int> rowId,
      required String activityId,
      required String type,
      required String actorUrl,
      Value<String?> objectJson,
      required String rawJson,
      required DateTime publishedAt,
      Value<DateTime> storedAt,
    });
typedef $$SocialActivitiesTableTableUpdateCompanionBuilder =
    SocialActivitiesTableCompanion Function({
      Value<int> rowId,
      Value<String> activityId,
      Value<String> type,
      Value<String> actorUrl,
      Value<String?> objectJson,
      Value<String> rawJson,
      Value<DateTime> publishedAt,
      Value<DateTime> storedAt,
    });

class $$SocialActivitiesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SocialActivitiesTableTable> {
  $$SocialActivitiesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objectJson => $composableBuilder(
    column: $table.objectJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get storedAt => $composableBuilder(
    column: $table.storedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SocialActivitiesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SocialActivitiesTableTable> {
  $$SocialActivitiesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUrl => $composableBuilder(
    column: $table.actorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objectJson => $composableBuilder(
    column: $table.objectJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get storedAt => $composableBuilder(
    column: $table.storedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SocialActivitiesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SocialActivitiesTableTable> {
  $$SocialActivitiesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get actorUrl =>
      $composableBuilder(column: $table.actorUrl, builder: (column) => column);

  GeneratedColumn<String> get objectJson => $composableBuilder(
    column: $table.objectJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get storedAt =>
      $composableBuilder(column: $table.storedAt, builder: (column) => column);
}

class $$SocialActivitiesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SocialActivitiesTableTable,
          SocialActivitiesTableData,
          $$SocialActivitiesTableTableFilterComposer,
          $$SocialActivitiesTableTableOrderingComposer,
          $$SocialActivitiesTableTableAnnotationComposer,
          $$SocialActivitiesTableTableCreateCompanionBuilder,
          $$SocialActivitiesTableTableUpdateCompanionBuilder,
          (
            SocialActivitiesTableData,
            BaseReferences<
              _$AppDatabase,
              $SocialActivitiesTableTable,
              SocialActivitiesTableData
            >,
          ),
          SocialActivitiesTableData,
          PrefetchHooks Function()
        > {
  $$SocialActivitiesTableTableTableManager(
    _$AppDatabase db,
    $SocialActivitiesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SocialActivitiesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SocialActivitiesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SocialActivitiesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> activityId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> actorUrl = const Value.absent(),
                Value<String?> objectJson = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<DateTime> publishedAt = const Value.absent(),
                Value<DateTime> storedAt = const Value.absent(),
              }) => SocialActivitiesTableCompanion(
                rowId: rowId,
                activityId: activityId,
                type: type,
                actorUrl: actorUrl,
                objectJson: objectJson,
                rawJson: rawJson,
                publishedAt: publishedAt,
                storedAt: storedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String activityId,
                required String type,
                required String actorUrl,
                Value<String?> objectJson = const Value.absent(),
                required String rawJson,
                required DateTime publishedAt,
                Value<DateTime> storedAt = const Value.absent(),
              }) => SocialActivitiesTableCompanion.insert(
                rowId: rowId,
                activityId: activityId,
                type: type,
                actorUrl: actorUrl,
                objectJson: objectJson,
                rawJson: rawJson,
                publishedAt: publishedAt,
                storedAt: storedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SocialActivitiesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SocialActivitiesTableTable,
      SocialActivitiesTableData,
      $$SocialActivitiesTableTableFilterComposer,
      $$SocialActivitiesTableTableOrderingComposer,
      $$SocialActivitiesTableTableAnnotationComposer,
      $$SocialActivitiesTableTableCreateCompanionBuilder,
      $$SocialActivitiesTableTableUpdateCompanionBuilder,
      (
        SocialActivitiesTableData,
        BaseReferences<
          _$AppDatabase,
          $SocialActivitiesTableTable,
          SocialActivitiesTableData
        >,
      ),
      SocialActivitiesTableData,
      PrefetchHooks Function()
    >;
typedef $$NotificationsTableTableCreateCompanionBuilder =
    NotificationsTableCompanion Function({
      Value<int> rowId,
      required String type,
      required String fromActorUrl,
      Value<String?> objectRef,
      Value<bool> isRead,
      Value<DateTime> createdAt,
    });
typedef $$NotificationsTableTableUpdateCompanionBuilder =
    NotificationsTableCompanion Function({
      Value<int> rowId,
      Value<String> type,
      Value<String> fromActorUrl,
      Value<String?> objectRef,
      Value<bool> isRead,
      Value<DateTime> createdAt,
    });

class $$NotificationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationsTableTable> {
  $$NotificationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromActorUrl => $composableBuilder(
    column: $table.fromActorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objectRef => $composableBuilder(
    column: $table.objectRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationsTableTable> {
  $$NotificationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromActorUrl => $composableBuilder(
    column: $table.fromActorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objectRef => $composableBuilder(
    column: $table.objectRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationsTableTable> {
  $$NotificationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get fromActorUrl => $composableBuilder(
    column: $table.fromActorUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get objectRef =>
      $composableBuilder(column: $table.objectRef, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NotificationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationsTableTable,
          NotificationsTableData,
          $$NotificationsTableTableFilterComposer,
          $$NotificationsTableTableOrderingComposer,
          $$NotificationsTableTableAnnotationComposer,
          $$NotificationsTableTableCreateCompanionBuilder,
          $$NotificationsTableTableUpdateCompanionBuilder,
          (
            NotificationsTableData,
            BaseReferences<
              _$AppDatabase,
              $NotificationsTableTable,
              NotificationsTableData
            >,
          ),
          NotificationsTableData,
          PrefetchHooks Function()
        > {
  $$NotificationsTableTableTableManager(
    _$AppDatabase db,
    $NotificationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> fromActorUrl = const Value.absent(),
                Value<String?> objectRef = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => NotificationsTableCompanion(
                rowId: rowId,
                type: type,
                fromActorUrl: fromActorUrl,
                objectRef: objectRef,
                isRead: isRead,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String type,
                required String fromActorUrl,
                Value<String?> objectRef = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => NotificationsTableCompanion.insert(
                rowId: rowId,
                type: type,
                fromActorUrl: fromActorUrl,
                objectRef: objectRef,
                isRead: isRead,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationsTableTable,
      NotificationsTableData,
      $$NotificationsTableTableFilterComposer,
      $$NotificationsTableTableOrderingComposer,
      $$NotificationsTableTableAnnotationComposer,
      $$NotificationsTableTableCreateCompanionBuilder,
      $$NotificationsTableTableUpdateCompanionBuilder,
      (
        NotificationsTableData,
        BaseReferences<
          _$AppDatabase,
          $NotificationsTableTable,
          NotificationsTableData
        >,
      ),
      NotificationsTableData,
      PrefetchHooks Function()
    >;
typedef $$PlaylistsTableTableCreateCompanionBuilder =
    PlaylistsTableCompanion Function({
      Value<int> rowId,
      required String title,
      Value<String> visibility,
      Value<String?> collectionUrl,
      Value<String> trackIdsJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PlaylistsTableTableUpdateCompanionBuilder =
    PlaylistsTableCompanion Function({
      Value<int> rowId,
      Value<String> title,
      Value<String> visibility,
      Value<String?> collectionUrl,
      Value<String> trackIdsJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$PlaylistsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTableTable> {
  $$PlaylistsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectionUrl => $composableBuilder(
    column: $table.collectionUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackIdsJson => $composableBuilder(
    column: $table.trackIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaylistsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTableTable> {
  $$PlaylistsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectionUrl => $composableBuilder(
    column: $table.collectionUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackIdsJson => $composableBuilder(
    column: $table.trackIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTableTable> {
  $$PlaylistsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumn<String> get collectionUrl => $composableBuilder(
    column: $table.collectionUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackIdsJson => $composableBuilder(
    column: $table.trackIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlaylistsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistsTableTable,
          PlaylistsTableData,
          $$PlaylistsTableTableFilterComposer,
          $$PlaylistsTableTableOrderingComposer,
          $$PlaylistsTableTableAnnotationComposer,
          $$PlaylistsTableTableCreateCompanionBuilder,
          $$PlaylistsTableTableUpdateCompanionBuilder,
          (
            PlaylistsTableData,
            BaseReferences<
              _$AppDatabase,
              $PlaylistsTableTable,
              PlaylistsTableData
            >,
          ),
          PlaylistsTableData,
          PrefetchHooks Function()
        > {
  $$PlaylistsTableTableTableManager(
    _$AppDatabase db,
    $PlaylistsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<String?> collectionUrl = const Value.absent(),
                Value<String> trackIdsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlaylistsTableCompanion(
                rowId: rowId,
                title: title,
                visibility: visibility,
                collectionUrl: collectionUrl,
                trackIdsJson: trackIdsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String title,
                Value<String> visibility = const Value.absent(),
                Value<String?> collectionUrl = const Value.absent(),
                Value<String> trackIdsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlaylistsTableCompanion.insert(
                rowId: rowId,
                title: title,
                visibility: visibility,
                collectionUrl: collectionUrl,
                trackIdsJson: trackIdsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaylistsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistsTableTable,
      PlaylistsTableData,
      $$PlaylistsTableTableFilterComposer,
      $$PlaylistsTableTableOrderingComposer,
      $$PlaylistsTableTableAnnotationComposer,
      $$PlaylistsTableTableCreateCompanionBuilder,
      $$PlaylistsTableTableUpdateCompanionBuilder,
      (
        PlaylistsTableData,
        BaseReferences<_$AppDatabase, $PlaylistsTableTable, PlaylistsTableData>,
      ),
      PlaylistsTableData,
      PrefetchHooks Function()
    >;
typedef $$SignalEventsTableTableCreateCompanionBuilder =
    SignalEventsTableCompanion Function({
      Value<int> id,
      required String trackFingerprint,
      required String eventType,
      Value<String?> sourceActorId,
      required int timestampUtcMs,
      required double weight,
    });
typedef $$SignalEventsTableTableUpdateCompanionBuilder =
    SignalEventsTableCompanion Function({
      Value<int> id,
      Value<String> trackFingerprint,
      Value<String> eventType,
      Value<String?> sourceActorId,
      Value<int> timestampUtcMs,
      Value<double> weight,
    });

class $$SignalEventsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SignalEventsTableTable> {
  $$SignalEventsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackFingerprint => $composableBuilder(
    column: $table.trackFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceActorId => $composableBuilder(
    column: $table.sourceActorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestampUtcMs => $composableBuilder(
    column: $table.timestampUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalEventsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SignalEventsTableTable> {
  $$SignalEventsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackFingerprint => $composableBuilder(
    column: $table.trackFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceActorId => $composableBuilder(
    column: $table.sourceActorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestampUtcMs => $composableBuilder(
    column: $table.timestampUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalEventsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SignalEventsTableTable> {
  $$SignalEventsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackFingerprint => $composableBuilder(
    column: $table.trackFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get sourceActorId => $composableBuilder(
    column: $table.sourceActorId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timestampUtcMs => $composableBuilder(
    column: $table.timestampUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);
}

class $$SignalEventsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SignalEventsTableTable,
          SignalEventsTableData,
          $$SignalEventsTableTableFilterComposer,
          $$SignalEventsTableTableOrderingComposer,
          $$SignalEventsTableTableAnnotationComposer,
          $$SignalEventsTableTableCreateCompanionBuilder,
          $$SignalEventsTableTableUpdateCompanionBuilder,
          (
            SignalEventsTableData,
            BaseReferences<
              _$AppDatabase,
              $SignalEventsTableTable,
              SignalEventsTableData
            >,
          ),
          SignalEventsTableData,
          PrefetchHooks Function()
        > {
  $$SignalEventsTableTableTableManager(
    _$AppDatabase db,
    $SignalEventsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalEventsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalEventsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignalEventsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trackFingerprint = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String?> sourceActorId = const Value.absent(),
                Value<int> timestampUtcMs = const Value.absent(),
                Value<double> weight = const Value.absent(),
              }) => SignalEventsTableCompanion(
                id: id,
                trackFingerprint: trackFingerprint,
                eventType: eventType,
                sourceActorId: sourceActorId,
                timestampUtcMs: timestampUtcMs,
                weight: weight,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trackFingerprint,
                required String eventType,
                Value<String?> sourceActorId = const Value.absent(),
                required int timestampUtcMs,
                required double weight,
              }) => SignalEventsTableCompanion.insert(
                id: id,
                trackFingerprint: trackFingerprint,
                eventType: eventType,
                sourceActorId: sourceActorId,
                timestampUtcMs: timestampUtcMs,
                weight: weight,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalEventsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SignalEventsTableTable,
      SignalEventsTableData,
      $$SignalEventsTableTableFilterComposer,
      $$SignalEventsTableTableOrderingComposer,
      $$SignalEventsTableTableAnnotationComposer,
      $$SignalEventsTableTableCreateCompanionBuilder,
      $$SignalEventsTableTableUpdateCompanionBuilder,
      (
        SignalEventsTableData,
        BaseReferences<
          _$AppDatabase,
          $SignalEventsTableTable,
          SignalEventsTableData
        >,
      ),
      SignalEventsTableData,
      PrefetchHooks Function()
    >;
typedef $$TasteScoresTableTableCreateCompanionBuilder =
    TasteScoresTableCompanion Function({
      required String trackFingerprint,
      Value<double> score,
      Value<int> rowid,
    });
typedef $$TasteScoresTableTableUpdateCompanionBuilder =
    TasteScoresTableCompanion Function({
      Value<String> trackFingerprint,
      Value<double> score,
      Value<int> rowid,
    });

class $$TasteScoresTableTableFilterComposer
    extends Composer<_$AppDatabase, $TasteScoresTableTable> {
  $$TasteScoresTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trackFingerprint => $composableBuilder(
    column: $table.trackFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasteScoresTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TasteScoresTableTable> {
  $$TasteScoresTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trackFingerprint => $composableBuilder(
    column: $table.trackFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasteScoresTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasteScoresTableTable> {
  $$TasteScoresTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trackFingerprint => $composableBuilder(
    column: $table.trackFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);
}

class $$TasteScoresTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasteScoresTableTable,
          TasteScoresTableData,
          $$TasteScoresTableTableFilterComposer,
          $$TasteScoresTableTableOrderingComposer,
          $$TasteScoresTableTableAnnotationComposer,
          $$TasteScoresTableTableCreateCompanionBuilder,
          $$TasteScoresTableTableUpdateCompanionBuilder,
          (
            TasteScoresTableData,
            BaseReferences<
              _$AppDatabase,
              $TasteScoresTableTable,
              TasteScoresTableData
            >,
          ),
          TasteScoresTableData,
          PrefetchHooks Function()
        > {
  $$TasteScoresTableTableTableManager(
    _$AppDatabase db,
    $TasteScoresTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasteScoresTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasteScoresTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasteScoresTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> trackFingerprint = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasteScoresTableCompanion(
                trackFingerprint: trackFingerprint,
                score: score,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trackFingerprint,
                Value<double> score = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasteScoresTableCompanion.insert(
                trackFingerprint: trackFingerprint,
                score: score,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasteScoresTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasteScoresTableTable,
      TasteScoresTableData,
      $$TasteScoresTableTableFilterComposer,
      $$TasteScoresTableTableOrderingComposer,
      $$TasteScoresTableTableAnnotationComposer,
      $$TasteScoresTableTableCreateCompanionBuilder,
      $$TasteScoresTableTableUpdateCompanionBuilder,
      (
        TasteScoresTableData,
        BaseReferences<
          _$AppDatabase,
          $TasteScoresTableTable,
          TasteScoresTableData
        >,
      ),
      TasteScoresTableData,
      PrefetchHooks Function()
    >;
typedef $$ActivityQueueTableTableCreateCompanionBuilder =
    ActivityQueueTableCompanion Function({
      Value<int> id,
      required String activityJson,
      required String activityType,
      required String targetActorUrl,
      Value<DateTime> createdAt,
      Value<int> attemptCount,
      Value<String> status,
    });
typedef $$ActivityQueueTableTableUpdateCompanionBuilder =
    ActivityQueueTableCompanion Function({
      Value<int> id,
      Value<String> activityJson,
      Value<String> activityType,
      Value<String> targetActorUrl,
      Value<DateTime> createdAt,
      Value<int> attemptCount,
      Value<String> status,
    });

class $$ActivityQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityQueueTableTable> {
  $$ActivityQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityJson => $composableBuilder(
    column: $table.activityJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetActorUrl => $composableBuilder(
    column: $table.targetActorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivityQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityQueueTableTable> {
  $$ActivityQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityJson => $composableBuilder(
    column: $table.activityJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetActorUrl => $composableBuilder(
    column: $table.targetActorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivityQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityQueueTableTable> {
  $$ActivityQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activityJson => $composableBuilder(
    column: $table.activityJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetActorUrl => $composableBuilder(
    column: $table.targetActorUrl,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$ActivityQueueTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivityQueueTableTable,
          ActivityQueueTableData,
          $$ActivityQueueTableTableFilterComposer,
          $$ActivityQueueTableTableOrderingComposer,
          $$ActivityQueueTableTableAnnotationComposer,
          $$ActivityQueueTableTableCreateCompanionBuilder,
          $$ActivityQueueTableTableUpdateCompanionBuilder,
          (
            ActivityQueueTableData,
            BaseReferences<
              _$AppDatabase,
              $ActivityQueueTableTable,
              ActivityQueueTableData
            >,
          ),
          ActivityQueueTableData,
          PrefetchHooks Function()
        > {
  $$ActivityQueueTableTableTableManager(
    _$AppDatabase db,
    $ActivityQueueTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityQueueTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> activityJson = const Value.absent(),
                Value<String> activityType = const Value.absent(),
                Value<String> targetActorUrl = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => ActivityQueueTableCompanion(
                id: id,
                activityJson: activityJson,
                activityType: activityType,
                targetActorUrl: targetActorUrl,
                createdAt: createdAt,
                attemptCount: attemptCount,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String activityJson,
                required String activityType,
                required String targetActorUrl,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => ActivityQueueTableCompanion.insert(
                id: id,
                activityJson: activityJson,
                activityType: activityType,
                targetActorUrl: targetActorUrl,
                createdAt: createdAt,
                attemptCount: attemptCount,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivityQueueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivityQueueTableTable,
      ActivityQueueTableData,
      $$ActivityQueueTableTableFilterComposer,
      $$ActivityQueueTableTableOrderingComposer,
      $$ActivityQueueTableTableAnnotationComposer,
      $$ActivityQueueTableTableCreateCompanionBuilder,
      $$ActivityQueueTableTableUpdateCompanionBuilder,
      (
        ActivityQueueTableData,
        BaseReferences<
          _$AppDatabase,
          $ActivityQueueTableTable,
          ActivityQueueTableData
        >,
      ),
      ActivityQueueTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AlbumsTableTableTableManager get albumsTable =>
      $$AlbumsTableTableTableManager(_db, _db.albumsTable);
  $$TracksTableTableTableManager get tracksTable =>
      $$TracksTableTableTableManager(_db, _db.tracksTable);
  $$ArtistsTableTableTableManager get artistsTable =>
      $$ArtistsTableTableTableManager(_db, _db.artistsTable);
  $$NodeIdentityTableTableTableManager get nodeIdentityTable =>
      $$NodeIdentityTableTableTableManager(_db, _db.nodeIdentityTable);
  $$InboxActivitiesTableTableTableManager get inboxActivitiesTable =>
      $$InboxActivitiesTableTableTableManager(_db, _db.inboxActivitiesTable);
  $$OutboxActivitiesTableTableTableManager get outboxActivitiesTable =>
      $$OutboxActivitiesTableTableTableManager(_db, _db.outboxActivitiesTable);
  $$ActorCacheTableTableTableManager get actorCacheTable =>
      $$ActorCacheTableTableTableManager(_db, _db.actorCacheTable);
  $$FollowersTableTableTableManager get followersTable =>
      $$FollowersTableTableTableManager(_db, _db.followersTable);
  $$FollowingTableTableTableManager get followingTable =>
      $$FollowingTableTableTableManager(_db, _db.followingTable);
  $$DefederatedNodesTableTableTableManager get defederatedNodesTable =>
      $$DefederatedNodesTableTableTableManager(_db, _db.defederatedNodesTable);
  $$NodeAllowDenyListTableTableTableManager get nodeAllowDenyListTable =>
      $$NodeAllowDenyListTableTableTableManager(
        _db,
        _db.nodeAllowDenyListTable,
      );
  $$MigrationTokensTableTableTableManager get migrationTokensTable =>
      $$MigrationTokensTableTableTableManager(_db, _db.migrationTokensTable);
  $$RemoteLibrariesTableTableTableManager get remoteLibrariesTable =>
      $$RemoteLibrariesTableTableTableManager(_db, _db.remoteLibrariesTable);
  $$AudioCacheTableTableTableManager get audioCacheTable =>
      $$AudioCacheTableTableTableManager(_db, _db.audioCacheTable);
  $$ListenActivitiesTableTableTableManager get listenActivitiesTable =>
      $$ListenActivitiesTableTableTableManager(_db, _db.listenActivitiesTable);
  $$FingerprintsTableTableTableManager get fingerprintsTable =>
      $$FingerprintsTableTableTableManager(_db, _db.fingerprintsTable);
  $$MergeProvenanceTableTableTableManager get mergeProvenanceTable =>
      $$MergeProvenanceTableTableTableManager(_db, _db.mergeProvenanceTable);
  $$FollowsTableTableTableManager get followsTable =>
      $$FollowsTableTableTableManager(_db, _db.followsTable);
  $$FollowRequestsTableTableTableManager get followRequestsTable =>
      $$FollowRequestsTableTableTableManager(_db, _db.followRequestsTable);
  $$BlocksTableTableTableManager get blocksTable =>
      $$BlocksTableTableTableManager(_db, _db.blocksTable);
  $$MutesTableTableTableManager get mutesTable =>
      $$MutesTableTableTableManager(_db, _db.mutesTable);
  $$SocialActivitiesTableTableTableManager get socialActivitiesTable =>
      $$SocialActivitiesTableTableTableManager(_db, _db.socialActivitiesTable);
  $$NotificationsTableTableTableManager get notificationsTable =>
      $$NotificationsTableTableTableManager(_db, _db.notificationsTable);
  $$PlaylistsTableTableTableManager get playlistsTable =>
      $$PlaylistsTableTableTableManager(_db, _db.playlistsTable);
  $$SignalEventsTableTableTableManager get signalEventsTable =>
      $$SignalEventsTableTableTableManager(_db, _db.signalEventsTable);
  $$TasteScoresTableTableTableManager get tasteScoresTable =>
      $$TasteScoresTableTableTableManager(_db, _db.tasteScoresTable);
  $$ActivityQueueTableTableTableManager get activityQueueTable =>
      $$ActivityQueueTableTableTableManager(_db, _db.activityQueueTable);
}
