import 'package:flutter/foundation.dart';

const String generateImageUrl = String.fromEnvironment(
  'GENERATE_IMAGE_URL',
  defaultValue: kReleaseMode
      ? 'https://generateimage-suwaxy27ya-uc.a.run.app'
      : 'http://127.0.0.1:5001/f-food-menu/us-central1/generateImage',
);

const String extractMenuUrl = String.fromEnvironment(
  'EXTRACT_MENU_URL',
  defaultValue: kReleaseMode
      ? 'https://extractmenu-suwaxy27ya-uc.a.run.app'
      : 'http://127.0.0.1:5001/f-food-menu/us-central1/extractMenu',
);
