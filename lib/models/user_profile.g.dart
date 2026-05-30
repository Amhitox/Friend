// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 2;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      name: fields[0] as String,
      preferredLanguage: fields[1] as PreferredLanguage,
      humorLevel: fields[2] as int,
      empathyLevel: fields[3] as int,
      formalityLevel: fields[4] as int,
      relationshipLevel: fields[5] as int,
      totalMessages: fields[6] as int,
      daysActive: fields[7] as int,
      firstInteractionDate: fields[8] as DateTime,
      avatarPath: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.preferredLanguage)
      ..writeByte(2)
      ..write(obj.humorLevel)
      ..writeByte(3)
      ..write(obj.empathyLevel)
      ..writeByte(4)
      ..write(obj.formalityLevel)
      ..writeByte(5)
      ..write(obj.relationshipLevel)
      ..writeByte(6)
      ..write(obj.totalMessages)
      ..writeByte(7)
      ..write(obj.daysActive)
      ..writeByte(8)
      ..write(obj.firstInteractionDate)
      ..writeByte(9)
      ..write(obj.avatarPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PreferredLanguageAdapter extends TypeAdapter<PreferredLanguage> {
  @override
  final int typeId = 5;

  @override
  PreferredLanguage read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PreferredLanguage.darija;
      case 1:
        return PreferredLanguage.arabic;
      case 2:
        return PreferredLanguage.french;
      case 3:
        return PreferredLanguage.mixed;
      default:
        return PreferredLanguage.darija;
    }
  }

  @override
  void write(BinaryWriter writer, PreferredLanguage obj) {
    switch (obj) {
      case PreferredLanguage.darija:
        writer.writeByte(0);
        break;
      case PreferredLanguage.arabic:
        writer.writeByte(1);
        break;
      case PreferredLanguage.french:
        writer.writeByte(2);
        break;
      case PreferredLanguage.mixed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreferredLanguageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
