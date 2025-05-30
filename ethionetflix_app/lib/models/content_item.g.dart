// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentItem _$ContentItemFromJson(Map<String, dynamic> json) => ContentItem(
  id: json['id'] as String?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  posterUrl: json['poster_url'] as String?,
  type: json['type'] as String?,
  quality: json['quality'] as String?,
  genres: (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList(),
  countries:
      (json['countries'] as List<dynamic>?)?.map((e) => e as String).toList(),
  releaseYear: (json['release_year'] as num?)?.toInt(),
  imdbRating: (json['imdb_rating'] as num?)?.toDouble(),
  duration: (json['duration'] as num?)?.toInt(),
  collectionId: json['collection_id'] as String?,
);

Map<String, dynamic> _$ContentItemToJson(ContentItem instance) =>
    <String, dynamic>{
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
    };
