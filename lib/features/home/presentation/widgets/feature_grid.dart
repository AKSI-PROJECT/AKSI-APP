import 'package:flutter/material.dart';
import '../../../scanner/presentation/pages/scanner_page.dart';
import '../../../email_checker/presentation/pages/email_check_page.dart';
import '../../../link_checker/presentation/pages/link_check_page.dart';
import '../../../apk_scanner/presentation/pages/apk_scan_page.dart';

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildFeatureCard(
          title: 'Sensor Dokumen',
          icon: Icons.document_scanner_outlined,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFF3F4F6),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ScannerPage()),
            );
          },
        ),
        _buildFeatureCard(
          title: 'Periksa APK',
          icon: Icons.android_rounded,
          iconColor: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEF2F2),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ApkScanPage()),
            );
          },
        ),
        _buildFeatureCard(
          title: 'Cek Email',
          icon: Icons.email_outlined,
          iconColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF5F3FF),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EmailCheckPage()),
            );
          },
        ),
        _buildFeatureCard(
          title: 'Scan Tautan',
          icon: Icons.link_rounded,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFDBEAFE),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LinkCheckPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: iconColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

