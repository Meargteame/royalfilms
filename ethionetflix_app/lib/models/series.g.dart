// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Series _$SeriesFromJson(Map<String, dynamic> json) => Series(
      id: json['id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      posterUrl: json['poster_url'] as String?,
      type: json['type'] as String?,
      quality: json['quality'] as String?,
      genres:
          (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList(),
      countries: (json['countries'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      releaseYear: json['release_year'],
      imdbRating: (json['imdb_rating'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toInt(),
      collectionId: json['collection_id'] as String?,
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList(),
      seasons: (json['seasons'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SeriesToJson(Series instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'poster_url': instance.posterUrl,
      'type': instance.type,
      'quality': instance.quality,
      'genres': instance.genres,
      'countries': instance.countries,
      'release_year': instance.releaseYear,
      'imdb_rating': instance.imdbRating,
      'duration': instance.duration,
      'collection_id': instance.collectionId,
      'episodes': instance.episodes,
      'seasons': instance.seasons,
    };

Episode _$EpisodeFromJson(Map<String, dynamic> json) => Episode(
      id: json['id'] as String?,
      title: json['title'] as String?,
      episodeNumber: (json['episodeNumber'] as num?)?.toInt(),
      seasonNumber: (json['seasonNumber'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );

Map<String, dynamic> _$EpisodeToJson(Episode instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'episodeNumber': instance.episodeNumber,
      'seasonNumber': instance.seasonNumber,
      'duration': instance.duration,
      'description': instance.description,
      'thumbnail_url': instance.thumbnailUrl,
    };
