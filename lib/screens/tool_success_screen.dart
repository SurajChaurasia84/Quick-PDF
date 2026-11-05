import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/app_file.dart';
import '../services/ad_service.dart';
import '../utils/file_action_helper.dart';
import '../utils/formatters.dart';
import '../utils/instant_page_route.dart';
import '../utils/theme_utils.dart';
import 'document_viewer_screen.dart';

class ToolSuccessScreen extends StatefulWidget {
  const ToolSuccessScreen({
    super.key,
    required this.file,
    this.title = 'File Created Successfully',
    this.subtitle = 'Your document is ready to view and share.',
    this.pageCount,
  });

  final AppFile file;
  final String title;
  final String subtitle;
  final int? pageCount;

  static void show(
    BuildContext context, {
    required AppFile file,
    String title = 'File Created Successfully',
    String subtitle = 'Your document is ready to view and share.',
    int? pageCount,
  }) {
    AdService.showInterstitial(
      cooldownSeconds: 0,
      onDismissed: () {
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          InstantPageRoute<void>(
            builder: (_) => ToolSuccessScreen(
              file: file,
              title: title,
              subtitle: subtitle,
              pageCount: pageCount,
            ),
          ),
        );
      },
    );
  }

  @override
  State<ToolSuccessScreen> createState() => _ToolSuccessScreenState();
}

class _ToolSuccessScreenState extends State<ToolSuccessScreen> {
  int? _pageCount;

  @override
  void initState() {
    super.initState();
    _pageCount = widget.pageCount;
    if (_pageCount == null && widget.file.isPdf) {
      _loadPageCount();
    }
  }

  Future<void> _loadPageCount() async {
    try {
      final file = File(widget.file.path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final document = PdfDocument(inputBytes: bytes);
        final count = document.pages.count;
        document.dispose();
        if (mounted) {
          setState(() {
            _pageCount = count;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Success'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_rounded),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 12),
              // Success celebration badge
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.14),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 44,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.secondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // File information card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.panelBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Color(0xFFEF4444),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.file.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.primaryText,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: <Widget>[
                                  Text(
                                    formatFileSize(widget.file.size),
                                    style: TextStyle(
                                      color: context.secondaryText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_pageCount != null && _pageCount! > 0) ...<Widget>[
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        color: context.secondaryText,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '$_pageCount ${_pageCount == 1 ? 'page' : 'pages'}',
                                      style: TextStyle(
                                        color: context.secondaryText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      color: context.secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: context.isDarkMode
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.file.extension.toUpperCase(),
                                      style: TextStyle(
                                        color: context.primaryText,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Open & Share Action Buttons
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => FileActionHelper.shareFile(context, widget.file),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: context.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          InstantPageRoute<void>(
                            builder: (_) => DocumentViewerScreen(file: widget.file),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('Open File'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Dynamic Medium Native Ad
              AdService.dynamicNative(
                templateType: TemplateType.medium,
                height: 360,
                margin: const EdgeInsets.only(bottom: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
