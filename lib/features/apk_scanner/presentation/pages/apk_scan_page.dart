import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/services/apk_repository.dart';
import '../../../history/domain/models/history_item.dart';
import '../../../history/domain/services/history_service.dart';
import '../../../../core/utils/popup_utils.dart';

class ApkScanPage extends StatefulWidget {
  const ApkScanPage({super.key});

  @override
  State<ApkScanPage> createState() => _ApkScanPageState();
}

class _ApkScanPageState extends State<ApkScanPage> {
  final ApkRepository _repository = ApkRepository();

  File? _selectedFile;
  bool _isScanning = false;
  ApkReputation? _reputation;

  Future<void> _pickAndScanFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;

        if (!path.toLowerCase().endsWith('.apk')) {
          if (!mounted) return;
          PopupUtils.showNotification(
            context,
            'Pilih file aplikasi Android (.apk)',
          );
          return;
        }

        setState(() {
          _selectedFile = File(path);
          _isScanning = true;
          _reputation = null;
        });

        final rep = await _repository.scanApk(_selectedFile!);

        await HistoryService().saveHistory(
          HistoryItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: HistoryType.apk,
            title: 'Inspeksi APK: ${rep.fileName}',
            description: rep.status == ApkStatus.safe
                ? 'Aman'
                : 'Aktivitas Mencurigakan',
            status: rep.status == ApkStatus.safe
                ? HistoryStatus.safe
                : HistoryStatus.dangerous,
            timestamp: DateTime.now(),
          ),
        );

        setState(() {
          _reputation = rep;
          _isScanning = false;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (!mounted) return;
      PopupUtils.showNotification(
        context,
        'Terjadi kesalahan: $e',
        isError: true,
      );
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _selectedFile = null;
      _reputation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Periksa APK'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_reputation != null) _buildResultHeader(),

              if (_reputation == null && !_isScanning) ...[
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFDC2626).withOpacity(0.1),
                    ),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFDC2626).withOpacity(0.2),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.android_rounded,
                            color: Color(0xFFDC2626),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Cek Keamanan File APK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unggah file .apk yang Anda dapatkan dari luar Play Store (WhatsApp, Telegram, dll) untuk dianalisa keamanannya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: _pickAndScanFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text(
                    'Pilih File APK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],

              if (_isScanning) ...[
                const SizedBox(height: 64),
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFDC2626),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 99),
                  duration: const Duration(seconds: 2),
                  builder: (context, value, child) {
                    return Text(
                      'Membedah struktur file APK... ${value.toInt()}%',
                      textAlign: TextAlign.center,
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
                  'Harap tunggu, proses ini memakan waktu beberapa detik.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],

              if (_reputation != null) ...[
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Periksa File Lain',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    final isSafe = _reputation!.status == ApkStatus.safe;
    final color = isSafe ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final icon = isSafe ? Icons.verified_user_rounded : Icons.gpp_bad_rounded;
    final title = isSafe ? 'File Terlihat Aman' : 'Peringatan Bahaya!';

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Center(child: Icon(icon, color: color, size: 32)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(
                'File: ${_reputation!.fileName}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Ukuran: ${_reputation!.fileSizeMB.toStringAsFixed(2)} MB',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _reputation!.message,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF475569),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        if (_reputation!.detectedThreats.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ancaman Terdeteksi:',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._reputation!.detectedThreats.map(
            (threat) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      threat,
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

