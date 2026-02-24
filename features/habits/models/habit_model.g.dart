// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitModelAdapter extends TypeAdapter<HabitModel> {
  @override
  final int typeId = 0;

  @override
  HabitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      typeString: fields[3] as String,
      streakGoal: fields[4] as int,
      completedDaysList: (fields[5] as List).cast<DateTime>(),
      scheduledWeekdays: (fields[6] as List).cast<int>(),
      startDate: fields[7] as DateTime,
      endDate: fields[8] as DateTime?,
      startTimeString: fields[9] as String?,
      endTimeString: fields[10] as String?,
      folderId: fields[11] as String?,
      isArchived: fields[12] as bool?,
      importanceString: fields[13] as String?,
      reminderTimeString: fields[14] as String?,
      activePeriodStartString: fields[15] as String?,
      activePeriodEndString: fields[16] as String?,
      durationMinutes: fields[17] as int?,
      statusString: fields[18] as String?,
      targetDates: (fields[19] as List?)?.cast<DateTime>(),
      durationModeString: fields[20] as String?,
      isPinned: fields[21] == null ? false : fields[21] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HabitModel obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.typeString)
      ..writeByte(4)
      ..write(obj.streakGoal)
      ..writeByte(5)
      ..write(obj.completedDaysList)
      ..writeByte(6)
      ..write(obj.scheduledWeekdays)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.startTimeString)
      ..writeByte(10)
      ..write(obj.endTimeString)
      ..writeByte(11)
      ..write(obj.folderId)
      ..writeByte(12)
      ..write(obj.isArchived)
      ..writeByte(13)
      ..write(obj.importanceString)
      ..writeByte(14)
      ..write(obj.reminderTimeString)
      ..writeByte(15)
      ..write(obj.activePeriodStartString)
      ..writeByte(16)
      ..write(obj.activePeriodEndString)
      ..writeByte(17)
      ..write(obj.durationMinutes)
      ..writeByte(18)
      ..write(obj.statusString)
      ..writeByte(19)
      ..write(obj.targetDates)
      ..writeByte(20)
      ..write(obj.durationModeString)
      ..writeByte(21)
      ..write(obj.isPinned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
