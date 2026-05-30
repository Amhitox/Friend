// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_tracker.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyUsageAdapter extends TypeAdapter<DailyUsage> {
  @override
  final int typeId = 11;

  @override
  DailyUsage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyUsage(
      date: fields[0] as DateTime,
      messagesSent: fields[1] as int,
      aiResponsesReceived: fields[2] as int,
      callMinutesUsed: fields[3] as double,
      checkInsCompleted: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyUsage obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.messagesSent)
      ..writeByte(2)
      ..write(obj.aiResponsesReceived)
      ..writeByte(3)
      ..write(obj.callMinutesUsed)
      ..writeByte(4)
      ..write(obj.checkInsCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyUsageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
