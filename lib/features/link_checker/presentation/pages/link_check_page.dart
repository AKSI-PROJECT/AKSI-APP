import 'package:flutter/material.dart';
import '../../domain/services/link_repository.dart';
import '../../../history/domain/models/history_item.dart';
import '../../../history/domain/services/history_service.dart';
import '../../../../core/utils/popup_utils.dart';

class LinkCheckPage extends StatefulWidget {
  const LinkCheckPage({super.key});

  @override
  State<LinkCheckPage> createState() => _LinkCheckPageState();
}

class _LinkCheckPageState extends State<LinkCheckPage> {
  final TextEditingController _urlController = TextEditingController();
  final LinkRepository _repository = LinkRepository();

  bool _isLoading = false;
  LinkReputation? _reputation;

  Future<void> _scanUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      PopupUtils.showNotification(context, 'Masukkan URL yang ingin di-scan', isError: true);
      return;
    }

    final urlPattern = RegExp(r'^(https?:\/\/)?([\w\d\-]+\.)+\w{2,}(\/.*)?$', caseSensitive: false);
    if (!urlPattern.hasMatch(url)) {
      PopupUtils.showNotification(context, 'Format URL tidak valid (contoh: google.com)', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _reputation = null;
    });

    String fullUrl = url;
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      fullUrl = 'https://$fullUrl';
    }

    final reputation = await _repository.checkLink(fullUrl);

    await HistoryService().saveHistory(
      HistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: HistoryType.link,
        title: 'Pemindaian URL: $url',
        description: reputation.status == LinkStatus.safe
            ? 'Aman'
            : 'Berpotensi Bahaya',
        status: reputation.status == LinkStatus.safe
            ? HistoryStatus.safe
            : HistoryStatus.dangerous,
        timestamp: DateTime.now(),
      ),
    );

    setState(() {
      _reputation = reputation;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Scan tautan'),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_reputation != null) _buildResultHeader(),
              if (_reputation == null && !_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'Masukkan tautan untuk mengecek keamanannya dari ancaman phishing dan malware.',
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
                        Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
              _buildUrlInput(),
              const SizedBox(height: 24),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    final isSafe = _reputation!.status == LinkStatus.safe;
    final color = isSafe ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final icon = isSafe ? Icons.verified_user_rounded : Icons.gpp_bad_rounded;
    final title = isSafe ? 'URL aman' : 'Peringatan!';

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
          _reputation!.message,
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

  Widget _buildUrlInput() {
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
            child: const Text(
              'https://',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: 'google.com',
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
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _scanUrl(),
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
            _urlController.clear();
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
          'Periksa situs lain',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _isLoading ? null : _scanUrl,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        disabledBackgroundColor: const Color(0xFF93C5FD),
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
              'Scan Tautan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}

