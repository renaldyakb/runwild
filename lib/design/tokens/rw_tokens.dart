import 'dart:ui';

abstract final class RwColors {
  static const transparent = Color(0x00000000);
  static const ink950 = Color(0xFF171A14);
  static const ink900 = Color(0xFF20241C);
  static const ink800 = Color(0xFF282D23);
  static const ink700 = Color(0xFF3B4233);
  static const ink500 = Color(0xFF6B6B72);
  static const mutedTextOnLight = Color(0xFF65656C);
  static const paper50 = Color(0xFFF7F9F2);
  static const paper100 = Color(0xFFFFFFFF);
  static const paper200 = Color(0xFFDEE3D6);
  static const lime500 = Color(0xFFC5FF41);
  static const lime600 = Color(0xFFB0EB2E);
  static const lime300 = Color(0xFFD5FF80);
  static const lime100 = Color(0xFFEFFFCC);
  static const lime700 = Color(0xFF486600);
  static const limeTextOnLight = Color(0xFF486600);
  static const dangerTextOnLight = Color(0xFFB4232D);
  static const go500 = Color(0xFF2ECC71);
  static const warn500 = Color(0xFFFFB020);
  static const danger500 = Color(0xFFE5484D);
}

abstract final class RwSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const screen = 20.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
  static const huge = 56.0;
  static const giant = 72.0;
}

abstract final class RwRadius {
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const pill = 999.0;
}

abstract final class RwType {
  static const family = 'Google Sans Flex';
  static const displayXL = 72.0;
  static const displayL = 48.0;
  static const displayM = 32.0;
  static const title = 22.0;
  static const body = 16.0;
  static const bodySmall = 14.0;
  static const label = 12.0;
  static const tight = -1.2;
  static const bodyHeight = 1.5;
}

abstract final class RwSize {
  static const touch = 48.0;
  static const button = 56.0;
  static const pause = 88.0;
  static const icon = 24.0;
  static const hairline = 1.0;
  static const outline = 1.5;
  static const focus = 3.0;
  static const navIndicator = 4.0;
  static const contentMax = 560.0;
  static const landscape = 104.0;
  static const homeArtwork = 180.0;
  static const homeAction = 224.0;
  static const liveMapHeight = 360.0;
  static const countdownCircle = 160.0;
  static const skeleton = 20.0;
  static const skeletonHeading = 32.0;
  static const skeletonShortFraction = 0.65;
}

abstract final class RwMotion {
  static const micro = Duration(milliseconds: 120);
  static const transition = Duration(milliseconds: 200);
  static const page = Duration(milliseconds: 320);
}
