// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_folder_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskFolderAdapter extends TypeAdapter<TaskFolder> {
  @override
  final int typeId = 4;

  @override
  TaskFolder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskFolder(
      id: fields[0] as String,
      name: fields[1] as String,
      dateCreated: fields[2] as DateTime,
      sections: (fields[3] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, TaskFolder obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.dateCreated)
      ..writeByte(3)
      ..write(obj.sections);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskFolderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
