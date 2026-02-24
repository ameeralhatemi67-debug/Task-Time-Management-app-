// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_folder_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitFolderAdapter extends TypeAdapter<HabitFolder> {
  @override
  final int typeId = 5;

  @override
  HabitFolder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitFolder(
      id: fields[0] as String,
      name: fields[1] as String,
      dateCreated: fields[2] as DateTime,
      habitIds: (fields[3] as List?)?.cast<String>(),
      iconKey: fields[4] == null ? 'folder' : fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HabitFolder obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.dateCreated)
      ..writeByte(3)
      ..write(obj.habitIds)
      ..writeByte(4)
      ..write(obj.iconKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitFolderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
