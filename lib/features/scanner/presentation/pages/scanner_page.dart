import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/ml_service.dart';
import '../../domain/pdf_generator.dart';
import '../widgets/redaction_layer.dart';
import '../../../history/domain/models/history_item.dart';
import '../../../history/domain/services/history_service.dart';
import '../../../../core/utils/popup_utils.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MLService _mlService = MLService();

  final TextEditingController _fileNameController = TextEditingController(
    text: 'Dokumen_Sensor',
  );
  File? _imageFile;
  Size? _imageSize;
  List<RedactRegion> _regions = [];

  bool _isAnalyzing = false;
  bool _isRedacted = false;
  bool _isExporting = false;

  @override
  void dispose() {
    _mlService.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _scanDocument() async {
    try {
      final documentScanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormats: const {DocumentFormat.jpeg},
          mode: ScannerMode.full,
          pageLimit: 1,
          isGalleryImport: true,
        ),
      );

      final result = await documentScanner.scanDocument();
      documentScanner.close();

      if (result.images == null || result.images!.isEmpty) return;

      final croppedPath = result.images!.first;

      setState(() {
        _imageFile = File(croppedPath);
        _isAnalyzing = true;
        _isRedacted = false;
        _regions = [];
        _imageSize = null;
      });

      final bytes = await _imageFile!.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      _imageSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );
      final regions = await _mlService.analyzeImage(croppedPath);

      if (mounted) {
        setState(() {
          _regions = regions;
          _isAnalyzing = false;
        });

        if (regions.isEmpty) {
          PopupUtils.showNotification(
            context,
            'Tidak ada data sensitif yang terdeteksi.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        PopupUtils.showNotification(context, 'Error: $e', isError: true);
      }
    }
  }

  void _handleRegionTapped(int index) {
    if (_isRedacted) return;
    setState(() {
      _regions[index].isApplied = !_regions[index].isApplied;
    });
  }

  void _handleCustomDrawStart(Rect rect) {
    if (_isRedacted) return;
    setState(() {
      _regions.add(
        RedactRegion(rect: rect, type: RedactType.custom, isApplied: true),
      );
    });
  }

  void _handleCustomDrawUpdate(Rect rect) {
    if (_isRedacted) return;
    if (_regions.isNotEmpty && _regions.last.type == RedactType.custom) {
      setState(() {
        _regions[_regions.length - 1] = RedactRegion(
          rect: rect,
          type: RedactType.custom,
          isApplied: true,
        );
      });
    }
  }

  void _handleCustomDrawEnd() {}

  Future<void> _exportToPDF() async {
    if (_imageFile == null || _regions.isEmpty) return;

    setState(() => _isExporting = true);

    final pdfFile = await PDFGenerator.redactAndGeneratePDF(
      _imageFile!.path,
      _regions,
      _fileNameController.text,
    );

    if (mounted) {
      setState(() => _isExporting = false);
      if (pdfFile != null) {
        final appliedCount = _regions.where((r) => r.isApplied).length;

        await HistoryService().saveHistory(
          HistoryItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: HistoryType.document,
            title: 'Pemindaian Dokumen: ${_fileNameController.text}.pdf',
            description: '$appliedCount area disensor',
            status: HistoryStatus.info,
            timestamp: DateTime.now(),
          ),
        );

        await Share.shareXFiles([
          XFile(pdfFile.path),
        ], text: 'Dokumen tersensor oleh AKSI');
      } else {
        PopupUtils.showNotification(
          context,
          'Gagal membuat file PDF.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Sensor Dokumen'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_imageFile == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                ),
                child: Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2563EB).withOpacity(0.2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.document_scanner_rounded,
                        color: Color(0xFF2563EB),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pindai Dokumen Pribadi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pilih dokumen KTP atau file penting lainnya untuk disensor secara otomatis sebelum dibagikan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _scanDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Mulai Pindai Dokumen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 99),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Text(
                  'Menganalisis dokumen secara lokal... ${value.toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    fontSize: 16,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Data Anda diproses di dalam perangkat (offline).',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_imageSize != null) ...[
            if (!_isRedacted)
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Ketuk kotak kuning untuk menyensor, atau usap gambar untuk membuat kotak sensor sendiri.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RedactionLayer(
                imageFile: _imageFile!,
                regions: _regions,
                imageSize: _imageSize!,
                onRegionTapped: _handleRegionTapped,
                onCustomDrawStart: _handleCustomDrawStart,
                onCustomDrawUpdate: _handleCustomDrawUpdate,
                onCustomDrawEnd: _handleCustomDrawEnd,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (!_isRedacted && _regions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ditemukan ${_regions.length} area sensitif. Pilih area yang ingin disensor permanen.',
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_imageFile == null || _isAnalyzing || _regions.isEmpty) return null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: _isRedacted
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _fileNameController,
                      decoration: const InputDecoration(
                        hintText: 'Nama File (tanpa .pdf)',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.edit_document,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isExporting ? null : _exportToPDF,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Simpan / Bagikan PDF',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: () {
                  final hasSelected = _regions.any((r) => r.isApplied);
                  setState(() {
                    if (!hasSelected) {
                      for (var r in _regions) {
                        r.isApplied = true;
                      }
                    }
                    _isRedacted = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Selesai Memilih & Lanjut',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }
}

