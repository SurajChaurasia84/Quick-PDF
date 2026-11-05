import 'package:flutter/widgets.dart';

import 'package:pdfrx/pdfrx.dart';
import 'app.dart';
import 'services/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pdfrxFlutterInitialize();
  await AdService.initialize();
  runApp(const DocReaderApp());
}
