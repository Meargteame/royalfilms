// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Cast _$CastFromJson(Map<String, dynamic> json) => Cast(
  id: json['id'] as String?,
  name: json['name'] as String?,
  character: json['character'] as String?,
  role: json['role'] as String?,
  profileImage: json['profile_image'] as String?,
);

Map<String, dynamic> _$CastToJson(Cast instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'character': instance.character,
  'role': instance.role,
  'profile_image': instance.profileImage,
};
