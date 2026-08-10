import 'package:flutter/material.dart';
import 'static_content_page.dart';
import '../../../../core/widgets/fade_in_slide.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInSlide(
                delay: const Duration(milliseconds: 100),
                child: const Text(
                  'Pengaturan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInSlide(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StaticContentPage(
                                title: 'Privacy Policy',
                                content: '''
## 1. Pengumpulan Informasi
Aplikasi AKSI dirancang untuk mengutamakan privasi Anda. Kami sama sekali tidak mengirimkan riwayat pemindaian Anda ke server atau cloud mana pun. Seluruh hasil scan tautan, APK, email, maupun dokumen diproses dan disimpan murni di dalam penyimpanan ponsel Anda.

## 2. Penggunaan Layanan Pihak Ketiga
Untuk memberikan hasil deteksi yang akurat, aplikasi ini melakukan pengecekan ke layanan keamanan pihak ketiga. Data yang dikirim hanya terbatas pada tautan atau alamat email yang sedang Anda cek, tanpa menyertakan data pribadi Anda.

## 3. Pemrosesan Tanpa Internet
Fitur sensor dokumen KTP atau file penting lainnya serta pengenalan teks sepenuhnya berjalan tanpa internet di ponsel Anda. Tidak ada gambar atau dokumen yang pernah diunggah ke internet oleh aplikasi ini.

## 4. Keamanan
Kami berkomitmen melindungi data Anda. Namun, Anda harus menyadari bahwa tidak ada metode transmisi di internet yang aman secara mutlak.
''',
                              ),
                            ),
                          );
                        },
                        showBorder: true,
                      ),
                      _buildSettingItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help Center',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StaticContentPage(
                                title: 'Help Center',
                                content: '''
## Pusat Bantuan

Selamat datang di Pusat Bantuan AKSI. Jika Anda mengalami kesulitan dalam menggunakan aplikasi, panduan di bawah ini mungkin dapat membantu Anda.

## Fitur Cek Tautan
Cukup tempelkan tautan yang Anda curigai ke dalam kolom pencarian, lalu tekan Scan. Aplikasi akan mengembalikan status aman atau berbahayanya tautan tersebut. Jika indikator menunjukkan warna merah, mohon jangan mengakses tautan tersebut.

## Sensor Dokumen
Gunakan fitur ini saat Anda ingin mengirim KTP, NPWP, atau dokumen penting lainnya ke orang lain. Aplikasi akan secara otomatis menutupi data sensitif seperti NIK, nomor kartu, atau wajah Anda sehingga aman untuk dibagikan.

## Riwayat Aktivitas
Riwayat Anda hanya disimpan di telepon Anda sendiri. Jika Anda berganti ponsel atau menghapus data aplikasi, riwayat Anda akan otomatis terhapus dan tidak bisa dikembalikan.

Jika ada kendala lebih lanjut, silakan baca selengkapnya melalui menu Edukasi kami.
''',
                              ),
                            ),
                          );
                        },
                        showBorder: true,
                      ),
                      _buildSettingItem(
                        icon: Icons.info_outline_rounded,
                        title: 'About',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StaticContentPage(
                                title: 'About',
                                content: '''
## Tentang AKSI

Aplikasi Keamanan Siber & Inspeksi-penipuan atau AKSI adalah aplikasi pelindung pribadi Anda dari ancaman penipuan digital dan serangan siber sehari-hari. 

Aplikasi ini diciptakan khusus untuk membantu masyarakat terhindar dari maraknya modus pencurian data, tautan palsu, penyalahgunaan identitas diri, dan aplikasi berbahaya.

## Misi Kami
Kami percaya bahwa keamanan digital adalah hak semua orang. Oleh karena itu, AKSI didesain agar sangat mudah digunakan oleh semua kalangan, tanpa mengorbankan keamanan dan privasi.

Terima kasih telah menggunakan AKSI untuk menjaga keamanan digital Anda.
''',
                              ),
                            ),
                          );
                        },
                        showBorder: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeInSlide(
                delay: const Duration(milliseconds: 300),
                child: const Center(
                  child: Text(
                    'App Version: 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool showBorder,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF475569), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
