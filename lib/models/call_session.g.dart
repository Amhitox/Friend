// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CallSessionAdapter extends TypeAdapter<CallSession> {
  @override
  final int typeId = 4;

  @override
  CallSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CallSession(
      id: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime?,
      durationSeconds: fields[3] as int,
      wasIncoming: fields[4] as bool,
      transcript: (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CallSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.durationSeconds)
      ..writeByte(4)
      ..write(obj.wasIncoming)
      ..writeByte(5)
      ..write(obj.transcript);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
