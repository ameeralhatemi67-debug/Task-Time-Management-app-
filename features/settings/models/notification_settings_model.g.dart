// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationSettingsAdapter extends TypeAdapter<NotificationSettings> {
  @override
  final int typeId = 30;

  @override
  NotificationSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationSettings(
      allEnabled: fields[0] as bool,
      loopingAlarm: fields[1] as bool,
      ringtoneName: fields[2] as String,
      vibrationEnabled: fields[3] as bool,
      taskNotifications: fields[4] as bool,
      habitNotifications: fields[5] as bool,
      focusNotifications: fields[6] as bool,
      completionSounds: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.allEnabled)
      ..writeByte(1)
      ..write(obj.loopingAlarm)
      ..writeByte(2)
      ..write(obj.ringtoneName)
      ..writeByte(3)
      ..write(obj.vibrationEnabled)
      ..writeByte(4)
      ..write(obj.taskNotifications)
      ..writeByte(5)
      ..write(obj.habitNotifications)
      ..writeByte(6)
      ..write(obj.focusNotifications)
      ..writeByte(7)
      ..write(obj.completionSounds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
