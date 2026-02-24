// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FocusTaskModelAdapter extends TypeAdapter<FocusTaskModel> {
  @override
  final int typeId = 20;

  @override
  FocusTaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FocusTaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      targetDurationSeconds: fields[2] as int,
      isDone: fields[3] as bool,
      dateCreated: fields[4] as DateTime,
      accumulatedSeconds: fields[5] as int,
      isPinned: fields[6] as bool,
      isArchived: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FocusTaskModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.targetDurationSeconds)
      ..writeByte(3)
      ..write(obj.isDone)
      ..writeByte(4)
      ..write(obj.dateCreated)
      ..writeByte(5)
      ..write(obj.accumulatedSeconds)
      ..writeByte(6)
      ..write(obj.isPinned)
      ..writeByte(7)
      ..write(obj.isArchived);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusTaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
