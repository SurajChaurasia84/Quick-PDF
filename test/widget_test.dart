import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_pdf/models/app_file.dart';
import 'package:quick_pdf/screens/document_viewer_screen.dart';
import 'package:quick_pdf/services/ai_service.dart';
import 'package:quick_pdf/services/app_controller.dart';
import 'package:quick_pdf/services/database_service.dart';
import 'package:quick_pdf/services/file_service.dart';
import 'package:quick_pdf/services/office_service.dart';
import 'package:quick_pdf/services/ocr_service.dart';
import 'package:quick_pdf/services/pdf_service.dart';
import 'package:quick_pdf/services/scanner_service.dart';
import 'package:quick_pdf/services/storage_info_service.dart';
import 'package:quick_pdf/services/storage_service.dart';
import 'package:quick_pdf/utils/app_theme.dart';

void main() {
  testWidgets('DocumentViewerScreen navigation and build test', (tester) async {
    final tempDir = Directory.systemTemp.createTempSync('pdf_test');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final tempPdf = File('${tempDir.path}/sample.pdf');
    tempPdf.writeAsBytesSync(<int>[0, 1, 2, 3]);

    final testFile = AppFile(
      path: tempPdf.path,
      name: 'sample.pdf',
      extension: 'pdf',
      size: 4,
      modifiedAt: DateTime.now(),
    );

    final appController = AppController(
      storageService: StorageService(),
      databaseService: DatabaseService(),
      fileService: FileService(),
      pdfService: PdfService(),
      officeService: OfficeService(),
      ocrService: OcrService(),
      aiService: AiService(),
      scannerService: ScannerService(),
      storageInfoService: StorageInfoService(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppController>.value(
        value: appController,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => DocumentViewerScreen(file: testFile),
                    ),
                  );
                },
                child: const Text('Open PDF'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Open PDF'), findsOneWidget);
    await tester.tap(find.text('Open PDF'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  });
}
