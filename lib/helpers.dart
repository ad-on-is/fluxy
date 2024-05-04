abstract class Helpers {
  static String cutText(String s, int length, {String ellipsis = "..."}) {
    s = s.substring(0, s.length > length ? length : s.length);
    return s.length == length ? s + ellipsis : s;
  }
}
