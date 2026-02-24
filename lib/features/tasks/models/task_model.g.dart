// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 3;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      isDone: fields[2] as bool,
      folderId: fields[3] as String,
      sectionName: fields[4] as String,
      dateCreated: fields[5] as DateTime,
      description: fields[6] as String?,
      checklist: (fields[7] as List?)?.cast<String>(),
      taskType: fields[8] as TaskType,
      viewType: fields[9] as TaskViewType,
      importance: fields[10] as TaskImportance,
      showCategoryIcon: fields[11] as bool,
      startTime: fields[12] as DateTime?,
      endTime: fields[13] as DateTime?,
      location: fields[14] as String?,
      habitStreak: fields[15] as int?,
      habitGoal: fields[16] as int?,
      completedAt: fields[17] as DateTime?,
      isArchived: fields[18] as bool,
      focusSeconds: fields[19] as int?,
      isPinned: fields[20] as bool,
      parentId: fields[21] as String?,
      endDate: fields[22] as DateTime?,
      isHabit: fields[23] as bool,
      completedHistory: (fields[24] as List?)?.cast<DateTime>(),
      isStreakCount: fields[25] as bool,
      showSmartPopup: fields[26] as bool,
      reminderTime: fields[27] as DateTime?,
      activePeriodStart: fields[28] as DateTime?,
      activePeriodEnd: fields[29] as DateTime?,
      durationMinutes: fields[30] as int?,
      recurrenceRule: fields[31] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(32)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.isDone)
      ..writeByte(3)
      ..write(obj.folderId)
      ..writeByte(4)
      ..write(obj.sectionName)
      ..writeByte(5)
      ..write(obj.dateCreated)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.checklist)
      ..writeByte(8)
      ..write(obj.taskType)
      ..writeByte(9)
      ..write(obj.viewType)
      ..writeByte(10)
      ..write(obj.importance)
      ..writeByte(11)
      ..write(obj.showCategoryIcon)
      ..writeByte(12)
      ..write(obj.startTime)
      ..writeByte(13)
      ..write(obj.endTime)
      ..writeByte(14)
      ..write(obj.location)
      ..writeByte(15)
      ..write(obj.habitStreak)
      ..writeByte(16)
      ..write(obj.habitGoal)
      ..writeByte(17)
      ..write(obj.completedAt)
      ..writeByte(18)
      ..write(obj.isArchived)
      ..writeByte(19)
      ..write(obj.focusSeconds)
      ..writeByte(20)
      ..write(obj.isPinned)
      ..writeByte(21)
      ..write(obj.parentId)
      ..writeByte(22)
      ..write(obj.endDate)
      ..writeByte(23)
      ..write(obj.isHabit)
      ..writeByte(24)
      ..write(obj.completedHistory)
      ..writeByte(25)
      ..write(obj.isStreakCount)
      ..writeByte(26)
      ..write(obj.showSmartPopup)
      ..writeByte(27)
      ..write(obj.reminderTime)
      ..writeByte(28)
      ..write(obj.activePeriodStart)
      ..writeByte(29)
      ..write(obj.activePeriodEnd)
      ..writeByte(30)
      ..write(obj.durationMinutes)
      ..writeByte(31)
      ..write(obj.recurrenceRule);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskTypeAdapter extends TypeAdapter<TaskType> {
  @override
  final int typeId = 10;

  @override
  TaskType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskType.normal;
      case 1:
        return TaskType.event;
      case 2:
        return TaskType.habit;
      case 3:
        return TaskType.reminder;
      default:
        return TaskType.normal;
    }
  }

  @override
  void write(BinaryWriter writer, TaskType obj) {
    switch (obj) {
      case TaskType.normal:
        writer.writeByte(0);
        break;
      case TaskType.event:
        writer.writeByte(1);
        break;
      case TaskType.habit:
        writer.writeByte(2);
        break;
      case TaskType.reminder:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskViewTypeAdapter extends TypeAdapter<TaskViewType> {
  @override
  final int typeId = 11;

  @override
  TaskViewType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskViewType.slim;
      case 1:
        return TaskViewType.expanded;
      default:
        return TaskViewType.slim;
    }
  }

  @override
  void write(BinaryWriter writer, TaskViewType obj) {
    switch (obj) {
      case TaskViewType.slim:
        writer.writeByte(0);
        break;
      case TaskViewType.expanded:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskViewTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskImportanceAdapter extends TypeAdapter<TaskImportance> {
  @override
  final int typeId = 12;

  @override
  TaskImportance read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskImportance.none;
      case 1:
        return TaskImportance.low;
      case 2:
        return TaskImportance.medium;
      case 3:
        return TaskImportance.high;
      default:
        return TaskImportance.none;
    }
  }

  @override
  void write(BinaryWriter writer, TaskImportance obj) {
    switch (obj) {
      case TaskImportance.none:
        writer.writeByte(0);
        break;
      case TaskImportance.low:
        writer.writeByte(1);
        break;
      case TaskImportance.medium:
        writer.writeByte(2);
        break;
      case TaskImportance.high:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskImportanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
