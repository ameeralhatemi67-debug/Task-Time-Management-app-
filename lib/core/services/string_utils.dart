class StringUtils {
  /// Converts a number like 1 to "1st", 22 to "22nd", etc.
  static String getOrdinal(int number) {
    if (number < 0) return number.toString();

    // Logic for special cases (11, 12, 13)
    if (number % 100 >= 11 && number % 100 <= 13) {
      return "${number}th";
    }

    switch (number % 10) {
      case 1:
        return "${number}st";
      case 2:
        return "${number}nd";
      case 3:
        return "${number}rd";
      default:
        return "${number}th";
    }
  }
}
