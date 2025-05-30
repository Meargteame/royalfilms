// lib/models/series.dart
import 'package:json_annotation/json_annotation.dart';
import 'content_item.dart';

part 'series.g.dart';

@JsonSerializable()
class Series extends ContentItem {
  final List<Episode>? episodes;
  final int? seasons;
  
  Series({
    super.id,
    super.title,
    super.description,
    super.posterUrl,
    super.type,
    super.quality,
    super.genres,
    super.countries,
    super.releaseYear,
    super.imdbRating,
    super.duration,
    super.collectionId,
    this.episodes,
    this.seasons,
  });

  factory Series.fromJson(Map<String, dynamic> json) => _$SeriesFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$SeriesToJson(this);
}

@JsonSerializable()
class Episode {
  final String? id;
  final String? title;
  final int? episodeNumber;
  final int? seasonNumber;
  final int? duration;
  final String? description;
  
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;

  Episode({
    this.id,
    this.title,
    this.episodeNumber,
    this.seasonNumber,
    this.duration,
    this.description,
    this.thumbnailUrl,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);
  Map<String, dynamic> toJson() => _$EpisodeToJson(this);
}
