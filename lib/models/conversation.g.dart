// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversationAdapter extends TypeAdapter<Conversation> {
  @override
  final int typeId = 3;

  @override
  Conversation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Conversation(
      id: fields[0] as String,
      title: fields[1] as String,
      messageIds: (fields[2] as List).cast<String>(),
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      mood: fields[5] as ConversationMood,
      summary: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Conversation obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.messageIds)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.mood)
      ..writeByte(6)
      ..write(obj.summary);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConversationMoodAdapter extends TypeAdapter<ConversationMood> {
  @override
  final int typeId = 6;

  @override
  ConversationMood read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ConversationMood.happy;
      case 1:
        return ConversationMood.sad;
      case 2:
        return ConversationMood.neutral;
      case 3:
        return ConversationMood.excited;
      default:
        return ConversationMood.happy;
    }
  }

  @override
  void write(BinaryWriter writer, ConversationMood obj) {
    switch (obj) {
      case ConversationMood.happy:
        writer.writeByte(0);
        break;
      case ConversationMood.sad:
        writer.writeByte(1);
        break;
      case ConversationMood.neutral:
        writer.writeByte(2);
        break;
      case ConversationMood.excited:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationMoodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
