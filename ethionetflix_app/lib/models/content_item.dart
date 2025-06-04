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
    this.releaseYear,
    this.imdbRating,
    this.duration,
    this.collectionId,
    this.trailerUrl,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) => _$ContentItemFromJson(json);
  Map<String, dynamic> toJson() => _$ContentItemToJson(this);
}
