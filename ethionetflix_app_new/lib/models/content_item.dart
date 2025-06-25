// lib/models/content_item.dart
import 'package:json_annotation/json_annotation.dart';

part 'content_item.g.dart';

@JsonSerializable()
class ContentItem {
  final String? id;
  final String? title;
  final String? description;
  
  @JsonKey(name: 'poster_url')
  final String? posterUrl;
  
  final String? type; // 'movie' or 'series'
  final String? quality;
  final List<String>? genres;
  final List<String>? countries;
  
  // Series-specific fields
  @JsonKey(name: 'series_id')
  final String? seriesId;
  @JsonKey(name: 'series_name')
  final String? seriesName;
  @JsonKey(name: 'episode_number')
  final int? episodeNumber;
  @JsonKey(name: 'season_number')
  final int? seasonNumber;
  final int? episode;
  
  // Make releaseYear dynamic to handle both string and int types
  @JsonKey(name: 'release_year')
  final dynamic releaseYear;
  
  @JsonKey(name: 'imdb_rating')
  final double? imdbRating;
  
  final int? duration; // in minutes
  
  // Fields for collections and related content
  @JsonKey(name: 'collection_id')
  final String? collectionId;
  
  @JsonKey(name: 'trailer_url')
  final String? trailerUrl;
  
  ContentItem({
    this.id,
    this.title,
    this.description,
    this.posterUrl,
    this.type,
    this.quality,
    this.genres,
    this.countries,
    this.seriesId,
    this.seriesName,
    this.episodeNumber,
    this.seasonNumber,
    this.episode,
    this.releaseYear,
    this.imdbRating,
    this.duration,
    this.collectionId,
    this.trailerUrl,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) => _$ContentItemFromJson(json);
  Map<String, dynamic> toJson() => _$ContentItemToJson(this);
}
