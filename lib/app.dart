import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import 'models/app_file.dart';
import 'screens/document_viewer_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/shell_screen.dart';
import 'services/ai_service.dart';
import 'services/app_controller.dart';
import 'services/database_service.dart';
import 'services/file_service.dart';
import 'services/office_service.dart';
import 'services/ocr_service.dart';
import 'services/pdf_service.dart';
import 'services/scanner_service.dart';
import 'services/storage_info_service.dart';
import 'services/storage_service.dart';
import 'utils/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DocReaderApp extends StatefulWidget {
  const DocReaderApp({super.key});

  @override
  State<DocReaderApp> createState() => _DocReaderAppState();
}

class _DocReaderAppState extends State<DocReaderApp> {
  static const MethodChannel _channel = MethodChannel('quick_pdf/storage_info');

  @override
  void initState() {
    super.initState();
    _initIntentListener();
  }

  void _initIntentListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPdfOpened') {
        final String? path = call.arguments as String?;
        if (path != null) {
          _openSharedPdf(path);
        }
      }
    });

    // Check for initial PDF if app was closed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final String? path = await _channel.invokeMethod<String>('getSharedPdfPath');
        if (path != null) {
          _openSharedPdf(path);
        }
      } catch (e) {
        debugPrint('Error getting initial shared PDF: $e');
      }
    });
  }

  void _openSharedPdf(String path) {
    final file = File(path);
    if (file.existsSync()) {
      final appFile = AppFile(
        path: path,
        name: p.basename(path),
        extension: 'pdf',
        size: file.lengthSync(),
        modifiedAt: file.lastModifiedSync(),
      );

      // Navigate to the document viewer screen
      navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (context) => DocumentViewerScreen(file: appFile),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppController(
        storageService: StorageService(),
        databaseService: DatabaseService(),
        fileService: FileService(),
        pdfService: PdfService(),
        officeService: OfficeService(),
        ocrService: OcrService(),
        aiService: AiService(),
        scannerService: ScannerService(),
        storageInfoService: StorageInfoService(),
      )..initialize(),
      child: Consumer<AppController>(
        builder: (context, controller, _) {
          final themeMode = controller.isDarkMode ? ThemeMode.dark : ThemeMode.light;
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Quick PDF',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            builder: (context, child) {
              final activeTheme = Theme.of(context);
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: overlayStyleForTheme(activeTheme),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const SplashScreen(child: ShellScreen()),
          );
        },
      ),
    );
  }
}
