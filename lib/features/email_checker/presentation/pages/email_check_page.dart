import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/services/email_repository.dart';
import '../../../history/domain/models/history_item.dart';
import '../../../history/domain/services/history_service.dart';
import '../../../../core/utils/popup_utils.dart';

class EmailCheckPage extends StatefulWidget {
  const EmailCheckPage({super.key});

  @override
  State<EmailCheckPage> createState() => _EmailCheckPageState();
}

class _EmailCheckPageState extends State<EmailCheckPage> {
  final TextEditingController _emailController = TextEditingController();
  final EmailRepository _repository = EmailRepository();

  bool _isLoading = false;
  ApiEmailReputation? _reputation;

  Future<void> _scanEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      PopupUtils.showNotification(context, 'Masukkan alamat email yang ingin dicek', isError: true);
      return;
    }

    final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$', caseSensitive: false);
    if (!emailPattern.hasMatch(email)) {
      PopupUtils.showNotification(context, 'Format email tidak valid (contoh: budi@gmail.com)', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _reputation = null;
    });

    final reputation = await _repository.checkEmailReputationAPI(email);

    final isSuspicious =
        reputation != null &&
        (reputation.suspicious || reputation.reputation == 'low');
    await HistoryService().saveHistory(
      HistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: HistoryType.email,
        title: 'Pengecekan Email: $email',
        description: isSuspicious ? 'Aktivitas Mencurigakan' : 'Aman',
        status: isSuspicious ? HistoryStatus.dangerous : HistoryStatus.safe,
        timestamp: DateTime.now(),
      ),
    );

    setState(() {
      _reputation = reputation;
      _isLoading = false;
    });
  }

  void _showReportDialog() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          _ReportDialogForm(email: email, repository: _repository),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Cek Email'),
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
              if (_reputation == null && !_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'Masukkan alamat email untuk memeriksa riwayat keamanan dan reputasinya.',
                    style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 32.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ),
              _buildEmailInput(),
              const SizedBox(height: 24),
              _buildActionButton(),
              if (_reputation != null) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Merasa email ini penipuan dan belum terdeteksi?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showReportDialog,
                  icon: const Icon(
                    Icons.report_problem_rounded,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Laporkan Penipuan',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
    final isSuspicious =
        _reputation!.suspicious || _reputation!.reputation == 'low';
    final color = isSuspicious
        ? const Color(0xFFEF4444)
        : const Color(0xFF22C55E);
    final icon = isSuspicious
        ? Icons.gpp_bad_rounded
        : Icons.verified_user_rounded;
    final title = isSuspicious ? 'Peringatan!' : 'Email Aman';

    String message = isSuspicious
        ? 'Email ini memiliki reputasi buruk atau pernah dilaporkan.'
        : 'Tidak ada aktivitas mencurigakan yang terdeteksi dari email ini.';

    if (isSuspicious && _reputation!.details.isNotEmpty) {
      if (_reputation!.details['blacklisted'] == true) {
        message = 'Email ini masuk dalam daftar hitam (blacklisted).';
      } else if (_reputation!.details['malicious_activity'] == true) {
        message = 'Email ini terindikasi melakukan aktivitas berbahaya.';
      } else if (_reputation!.details['credentials_leaked'] == true) {
        message = 'Kredensial email ini pernah bocor. Harap berhati-hati.';
      }
    }

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
        Text(
          message,
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
        if (_reputation!.isOffline) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Mode Offline: Pemindaian tidak optimal',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildEmailInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8)),
          ),
          Expanded(
            child: TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'contoh@gmail.com',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _scanEmail(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_reputation != null) {
      return OutlinedButton(
        onPressed: () {
          setState(() {
            _emailController.clear();
            _reputation = null;
          });
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Periksa Email Lain',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _isLoading ? null : _scanEmail,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        disabledBackgroundColor: const Color(0xFFC4B5FD),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Cek Reputasi Email',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

class _ReportDialogForm extends StatefulWidget {
  final String email;
  final EmailRepository repository;

  const _ReportDialogForm({required this.email, required this.repository});

  @override
  State<_ReportDialogForm> createState() => _ReportDialogFormState();
}

class _ReportDialogFormState extends State<_ReportDialogForm> {
  final _descController = TextEditingController();
  String _selectedCategory = 'Scam Lamaran Kerja';
  File? _imageFile;
  bool _isSubmitting = false;

  final categories = [
    'Scam Lamaran Kerja',
    'Minta Uang/Transfer',
    'Phishing Akun',
    'Undangan Palsu (APK)',
    'Lainnya',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_imageFile == null) {
      PopupUtils.showNotification(
        context,
        'Harap unggah screenshot bukti penipuan.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.repository.submitScamReport(
      emailAddress: widget.email,
      categoryTag: _selectedCategory,
      evidenceImage: _imageFile!,
      description: _descController.text,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
      PopupUtils.showNotification(
        context,
        'Laporan berhasil dikirim. Terima kasih!',
      );
    } else if (mounted) {
      PopupUtils.showNotification(
        context,
        'Gagal mengirim laporan. Coba lagi.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Laporkan Email Penipuan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Text(
              'Email: ${widget.email}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Kategori Penipuan',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Keterangan Tambahan (Opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: Text(
                _imageFile == null
                    ? 'Unggah Bukti Screenshot'
                    : 'Bukti Terpilih (Ketuk untuk ubah)',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text('KIRIM LAPORAN'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

