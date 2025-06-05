// lib/models/cast.dart
import 'package:json_annotation/json_annotation.dart';

part 'cast.g.dart';

@JsonSerializable()
class Cast {
  final String? id;
  final String? name;
  final String? character;
  final String? role; // actor, director, producer, etc.
  
  @JsonKey(name: 'profile_image')
  final String? profileImage;

  Cast({
    this.id,
    this.name,
    this.character,
    this.role,
    this.profileImage,
  });

  factory Cast.fromJson(Map<String, dynamic> json) => _$CastFromJson(json);
  Map<String, dynamic> toJson() => _$CastToJson(this);
}
