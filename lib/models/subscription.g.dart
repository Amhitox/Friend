// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionAdapter extends TypeAdapter<Subscription> {
  @override
  final int typeId = 10;

  @override
  Subscription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subscription(
      tier: fields[0] as SubscriptionTier,
      status: fields[1] as SubscriptionStatus,
      startDate: fields[2] as DateTime,
      expiryDate: fields[3] as DateTime,
      trialEndDate: fields[4] as DateTime?,
      autoRenew: fields[5] as bool,
      productId: fields[6] as String,
      originalTransactionId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Subscription obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.tier)
      ..writeByte(1)
      ..write(obj.status)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.expiryDate)
      ..writeByte(4)
      ..write(obj.trialEndDate)
      ..writeByte(5)
      ..write(obj.autoRenew)
      ..writeByte(6)
      ..write(obj.productId)
      ..writeByte(7)
      ..write(obj.originalTransactionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubscriptionTierAdapter extends TypeAdapter<SubscriptionTier> {
  @override
  final int typeId = 8;

  @override
  SubscriptionTier read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SubscriptionTier.free;
      case 1:
        return SubscriptionTier.premium;
      case 2:
        return SubscriptionTier.vip;
      default:
        return SubscriptionTier.free;
    }
  }

  @override
  void write(BinaryWriter writer, SubscriptionTier obj) {
    switch (obj) {
      case SubscriptionTier.free:
        writer.writeByte(0);
        break;
      case SubscriptionTier.premium:
        writer.writeByte(1);
        break;
      case SubscriptionTier.vip:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionTierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubscriptionStatusAdapter extends TypeAdapter<SubscriptionStatus> {
  @override
  final int typeId = 9;

  @override
  SubscriptionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SubscriptionStatus.active;
      case 1:
        return SubscriptionStatus.expired;
      case 2:
        return SubscriptionStatus.trial;
      case 3:
        return SubscriptionStatus.cancelled;
      case 4:
        return SubscriptionStatus.gracePeriod;
      default:
        return SubscriptionStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, SubscriptionStatus obj) {
    switch (obj) {
      case SubscriptionStatus.active:
        writer.writeByte(0);
        break;
      case SubscriptionStatus.expired:
        writer.writeByte(1);
        break;
      case SubscriptionStatus.trial:
        writer.writeByte(2);
        break;
      case SubscriptionStatus.cancelled:
        writer.writeByte(3);
        break;
      case SubscriptionStatus.gracePeriod:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
