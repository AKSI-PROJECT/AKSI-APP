class Article {
  final String id;
  final String title;
  final String shortDescription;
  final String content;
  final String threatLevel;
  final String imageUrl;

  const Article({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.content,
    required this.threatLevel,
    this.imageUrl = '',
  });
}

final List<Article> popularArticles = [
  const Article(
    id: '1',
    title: 'Jangan Asal Install APK',
    shortDescription:
        'Pelajari cara mengenali file APK berbahaya yang sering dikirim lewat pesan.',
    threatLevel: 'Ancaman Tinggi',
    content: '''
Pernahkah Anda menerima pesan dari nomor tidak dikenal yang mengirimkan file berakhiran .APK dengan alasan resi paket kurir, undangan pernikahan digital, atau tagihan pajak? Hati-hati, ini adalah salah satu modus penipuan pencurian data yang sedang marak terjadi.

## Apa Bahayanya?
File APK adalah format aplikasi untuk ponsel Android. Jika Anda mengunduh dan menginstal file APK dari sumber yang tidak resmi, Anda berisiko memberikan akses penuh kepada peretas untuk:
- Membaca SMS Anda, termasuk kode OTP dari bank.
- Mengambil alih akun media sosial Anda.
- Mengakses galeri foto dan kontak telepon.
- Menguras saldo rekening bank tanpa Anda sadari.

## Cara Melindungi Diri:
1. Jangan pernah klik atau unduh file APK dari orang asing atau sumber tidak tepercaya.
2. Matikan pengaturan instal aplikasi dari sumber tidak dikenal di ponsel Anda.
3. Selalu unduh aplikasi hanya dari layanan resmi seperti Play Store.
4. Jika sudah terlanjur mengunduh, jangan buka file tersebut. Segera hapus dan blokir nomor pengirim.

Selalu waspada dan pastikan keluarga Anda juga mengetahui modus penipuan ini.
''',
  ),
  const Article(
    id: '2',
    title: 'Waspada Link Phishing',
    shortDescription:
        'Cara mengenali tautan palsu yang dirancang untuk mencuri kata sandi Anda.',
    threatLevel: 'Ancaman Menengah',
    content: '''
Phishing adalah upaya menipu orang untuk mendapatkan data sensitif seperti nama lengkap, kata sandi, hingga data kartu kredit.

## Modus Operandi
Penipu biasanya mengirimkan tautan melalui email atau pesan yang terlihat sangat mirip dengan situs resmi bank, toko online, atau layanan populer. Ketika Anda menekan tautan tersebut, Anda akan diarahkan ke halaman masuk akun palsu.

## Tanda-tanda Link Phishing:
- Tautan tidak memiliki simbol gembok keamanan.
- Ada ejaan yang aneh pada nama alamat situs.
- Pesan yang mendesak, menakut-nakuti agar akun tidak diblokir, atau menjanjikan hadiah undian yang terlalu besar.

Gunakan fitur cek tautan di aplikasi AKSI untuk memeriksa keamanan setiap tautan yang meragukan sebelum Anda membukanya.
''',
  ),
  const Article(
    id: '3',
    title: 'Bahaya Wi-Fi Publik Terbuka',
    shortDescription:
        'Risiko menggunakan Wi-Fi gratisan tanpa perlindungan ekstra.',
    threatLevel: 'Ancaman Menengah',
    content: '''
Wi-Fi publik di kafe, bandara, atau hotel memang menggiurkan karena gratis. Namun, jaringan ini seringkali tidak dilindungi dengan baik, sehingga siapa saja yang berada di jaringan yang sama dapat mencegat data yang Anda kirim dan terima.

## Risiko Utama:
- Penyadapan data login dan kata sandi Anda.
- Serangan penyusupan di mana peretas menyisipkan virus ke perangkat Anda.

## Langkah Pencegahan:
1. Hindari melakukan transaksi perbankan atau masuk ke akun penting saat menggunakan Wi-Fi publik.
2. Gunakan koneksi jaringan pribadi virtual untuk mengamankan koneksi internet Anda.
3. Pastikan fitur berbagi jaringan di perangkat Anda sudah dimatikan.
4. Gunakan kuota seluler pribadi Anda jika memungkinkan untuk urusan yang sangat penting.
''',
  ),
];
