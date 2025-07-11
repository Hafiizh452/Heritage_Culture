import 'package:flutter/material.dart';
import 'main.dart';
import 'produk.dart';
import 'keranjang.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class Home extends StatefulWidget {
  final String username;
  final int initialIndex;

  const Home({Key? key, required this.username, this.initialIndex = 0}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
    );
  }

  List<Widget> get _pages => [
    Beranda(username: widget.username),
    ProdukList(),
    KeranjangPage(),
    TentangKamiPage(),
    AkunPage(username: widget.username, onLogout: () => _logout(context)),
  ];

  List<BottomNavigationBarItem> get _navItems => [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
    BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Produk'),
    BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Keranjang'),
    BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'Tentang'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: _navItems,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.brown[700],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// ------------------ BERANDA ------------------
class Beranda extends StatefulWidget {
  final String username;

  const Beranda({Key? key, required this.username}) : super(key: key);

  @override
  State<Beranda> createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  late Future<List<Produk>> _produkFuture;

  @override
  void initState() {
    super.initState();
    _produkFuture = ProdukService.fetchProduk();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.username}.'),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/header.png',
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),

            // Produk Terbaru
            Text('🆕 Produk Terbaru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            FutureBuilder<List<Produk>>(
              future: _produkFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Gagal memuat produk: ${snapshot.error}');
                }

                final produkList = snapshot.data ?? [];
                final batikList = produkList
                    .where((p) => p.kategori.toLowerCase().trim() == 'alat musik')
                    .take(2)
                    .toList();

                return Column(
                  children: batikList.map((p) {
                    final imageUrl = p.gambar.startsWith("https")
                        ? p.gambar
                        : 'https://alpatt.fortunis11.com/produk/${p.gambar}';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(p.nama),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Rp ${p.harga}", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                          Text("Stok: ${p.stok}", style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DetailProdukPage(id: p.id)),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Produk Unggulan
            Text('🌟 Produk Unggulan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            FutureBuilder<List<Produk>>(
              future: _produkFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Gagal memuat produk: ${snapshot.error}');
                }

                final produkList = snapshot.data ?? [];
                final musikList = produkList
                    .where((p) => p.kategori.toLowerCase().trim() == 'batik')
                    .take(2)
                    .toList();

                return Column(
                  children: musikList.map((p) {
                    final imageUrl = p.gambar.startsWith("https")
                        ? p.gambar
                        : 'https://alpatt.fortunis11.com/produk/${p.gambar}';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(p.nama),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Rp ${p.harga}", style: TextStyle(color: Colors.teal)),
                          Text("Stok: ${p.stok}"),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DetailProdukPage(id: p.id)),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ TENTANG KAMI ------------------
class TentangKamiPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tentang Kami'),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          'Heritage Culture adalah toko yang berkomitmen melestarikan warisan budaya Indonesia melalui dua harta tak ternilai: kain batik dan alat musik tradisional. Kami percaya bahwa keduanya bukan sekadar produk, melainkan bagian dari identitas bangsa yang kaya makna dan sejarah.\n\n'
              'Batik, dengan ragam motif seperti parang, mega mendung, kawung, dan truntum, bukan hanya kain berhias. Ia adalah simbol filosofi hidup, harapan, serta kearifan lokal yang diwariskan turun-temurun dari generasi ke generasi. Kami menghadirkan batik tulis, cap, dan printing dari berbagai penjuru nusantara yang mencerminkan keindahan budaya dan nilai-nilai luhur bangsa.\n\n'
              'Tak hanya batik, kami juga mempersembahkan koleksi alat musik tradisional seperti angklung, gamelan, sasando, kolintang, dan lainnya yang telah menjadi denyut nadi dari upacara, kesenian, dan kehidupan masyarakat Indonesia sejak zaman dahulu. Alat musik ini menghadirkan harmoni yang menghubungkan manusia dengan alam, leluhur, dan sesama.\n\n'
              'Heritage Culture ingin menjadi jembatan antara masa lalu dan masa kini. Produk kami tampil modern, namun tetap mengakar pada nilai tradisi. Baik batik maupun alat musik kami cocok sebagai koleksi, cinderamata, media edukasi, hingga pelengkap gaya hidup yang mencintai budaya.\n\n'
              'Dengan mendukung produk lokal ini, Anda turut menjaga keberlanjutan budaya dan memberdayakan para pengrajin serta seniman di berbagai daerah. Mari bersama-sama merayakan kekayaan Indonesia, karena dalam setiap helaian batik dan denting nada tradisional, ada kisah cinta yang abadi untuk tanah air tercinta.',
          style: GoogleFonts.aBeeZee(fontSize: 18, height: 1.6),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }
}

// ------------------ AKUN ------------------
class AkunPage extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;

  const AkunPage({required this.username, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Akun Saya'),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Username', style: TextStyle(fontSize: 18)),
              subtitle: Text(username, style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onLogout,
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
