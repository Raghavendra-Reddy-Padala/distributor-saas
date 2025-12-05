class CardFormatters {
  static String formatNumber(String number) {
    if (number.isEmpty) return 'N/A';
    final buffer = StringBuffer();
    for (int i = 0; i < number.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(number[i]);
    }
    return buffer.toString();
  }
}



