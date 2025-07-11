import 'package:flutter/material.dart';
import 'home.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ------------------- MODEL -------------------
class Produk {
  final String id;
  final String nama;
  final String kategori;
  final String harga;
  final String stok;
  final String gambar;
  final String asalDaerah;
  final String deskripsi;
  final String ceritaBudaya;

  Produk({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.harga,
    required this.stok,
    required this.gambar,
    required this.asalDaerah,
    required this.deskripsi,
    required this.ceritaBudaya,
  });

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      id: json['id'],
      nama: json['nama'],
      kategori: json['kategori'],
      harga: json['harga'],
      stok: json['stok'],
      gambar: json['gambar'],
      asalDaerah: json['asal_daerah'],
      deskripsi: json['deskripsi'],
      ceritaBudaya: json['cerita_budaya'],
    );
  }
}

// ------------------- SERVICE -------------------
class ProdukService {
  static const String _basePath = 'https://alpatt.fortunis11.com/produk';

  static Future<List<Produk>> fetchProduk() async {
    final response = await Dio().get("$_basePath/List.php");
    if (response.data is List) {
      return (response.data as List).map((item) => Produk.fromJson(item)).toList();
    } else {
      throw Exception('Format data dari server tidak sesuai.');
    }
  }

  static Future<Produk> fetchDetail(String id) async {
    final response = await Dio().get("$_basePath/detail.php", queryParameters: {'id': id});
    if (response.data is Map<String, dynamic>) {
      return Produk.fromJson(response.data);
    } else {
      throw Exception('Format data detail salah: ${response.data}');
    }
  }

  static Future<void> createProduk(Map<String, dynamic> data) async {
    final response = await Dio().post(
      "$_basePath/create.php",
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data['message'] != 'Produk berhasil ditambahkan') {
      throw Exception(response.data['message']);
    }
  }

  static Future<void> deleteProduk(String id) async {
    try {
      final response = await Dio().post(
        "$_basePath/delete.php",
        data: {'id': id},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = response.data is String ? jsonDecode(response.data) : response.data;

      if (data['message'] != 'Produk berhasil dihapus') {
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception("Delete gagal: $e");
    }
  }

  static Future<void> updateProduk(Map<String, dynamic> data) async {
    final response = await Dio().post(
      "$_basePath/Update.php",
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (response.data['message'] != 'Produk berhasil diperbarui') {
      throw Exception(response.data['message']);
    }
  }
}

// ------------------- PRODUK LIST -------------------
class ProdukList extends StatefulWidget {
  const ProdukList({super.key});

  @override
  _ProdukListState createState() => _ProdukListState();
}

class _ProdukListState extends State<ProdukList> {
  late Future<List<Produk>> _produkList;

  @override
  void initState() {
    super.initState();
    _produkList = ProdukService.fetchProduk();
  }

  Map<String, List<Produk>> pisahkanProduk(List<Produk> semuaProduk) {
    return {
      'batik': semuaProduk
          .where((p) => p.kategori.toLowerCase() == 'batik')
          .toList(),
      'alat musik': semuaProduk
          .where((p) => p.kategori.toLowerCase() == 'alat musik')
          .toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Produk"),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Produk>>(
        future: _produkList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada produk'));
          }

          final produkPerKategori = pisahkanProduk(snapshot.data!);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildKategoriSection(context, '🧵 Batik', produkPerKategori['batik']!, 'batik'),
              _buildKategoriSection(context, '🎶 Alat Musik', produkPerKategori['alat musik']!, 'alat musik'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKategoriSection(
      BuildContext context,
      String title,
      List<Produk> produkList,
      String kategori,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TambahProdukPage(initialKategori: kategori),
                    ),
                  );
                  setState(() {
                    _produkList = ProdukService.fetchProduk();
                  });
                },
                child: const Icon(Icons.add, size: 22),
              ),
            ],
          ),
        ),
        ...produkList.map((p) {
          final imageUrl = p.gambar.startsWith("https")
              ? p.gambar
              : 'https://alpatt.fortunis11.com/produk/${p.gambar}';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              p.nama,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "Rp ${p.harga}",
                  style: const TextStyle(fontSize: 14, color: Colors.teal),
                ),
                Text(
                  "Stok: ${p.stok}",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailProdukPage(id: p.id),
                ),
              ).then((_) {
                setState(() {
                  _produkList = ProdukService.fetchProduk();
                });
              });
            },
          );
        }).toList(),
      ],
    );
  }
}

// ------------------- DETAIL PRODUK -------------------
class DetailProdukPage extends StatefulWidget {
  final String id;

  const DetailProdukPage({required this.id, Key? key}) : super(key: key);

  @override
  State<DetailProdukPage> createState() => _DetailProdukPageState();
}

class _DetailProdukPageState extends State<DetailProdukPage> {
  late Future<Produk> _produkFuture;

  @override
  void initState() {
    super.initState();
    _produkFuture = ProdukService.fetchDetail(widget.id);
  }

  void _refreshDetail() {
    setState(() {
      _produkFuture = ProdukService.fetchDetail(widget.id);
    });
  }

  Future<void> tambahKeKeranjang(Produk produk) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal: username tidak ditemukan')),
        );
        return;
      }

      final response = await Dio().post(
        'https://alpatt.fortunis11.com/keranjang/tambahkeranjang.php',
        data: {
          'username': username,
          'produk_id': produk.id,
          'jumlah': 1,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk ditambahkan ke keranjang')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Home(
              username: username,
              initialIndex: 2, // tab keranjang
            ),
          ),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${response.data['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan ke keranjang: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'Tambah ke Keranjang',
            onPressed: () async {
              final produk = await _produkFuture;
              tambahKeKeranjang(produk);
            },
          ),
        ],
      ),
      body: FutureBuilder<Produk>(
        future: _produkFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Gagal: ${snapshot.error}'));

          final produk = snapshot.data!;
          final imageUrl = produk.gambar.startsWith("https")
              ? produk.gambar
              : 'https://alpatt.fortunis11.com/produk/${produk.gambar}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  produk.nama,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text("Harga : Rp ${produk.harga}",
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text("Stok : ${produk.stok}",
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text("Asal Daerah : ${produk.asalDaerah}",
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text("Kategori : ${produk.kategori}",
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text("Deskripsi : ${produk.deskripsi}",
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text("Cerita Budaya : ${produk.ceritaBudaya}",
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        label: const Text("Edit Produk"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProdukPage(produk: produk),
                            ),
                          );
                          _refreshDetail();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        label: const Text("Hapus Produk"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final konfirmasi = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Konfirmasi"),
                              content: const Text("Apakah Anda yakin ingin menghapus produk ini?"),
                              actions: [
                                TextButton(
                                  child: const Text("Batal"),
                                  onPressed: () => Navigator.pop(context, false),
                                ),
                                TextButton(
                                  child: const Text("Hapus"),
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ],
                            ),
                          );

                          if (konfirmasi == true) {
                            try {
                              await ProdukService.deleteProduk(produk.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Produk berhasil dihapus')),
                                );
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal menghapus produk: $e')),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ------------------- EDIT PRODUK -------------------
class EditProdukPage extends StatefulWidget {
  final Produk produk;
  const EditProdukPage({required this.produk, Key? key}) : super(key: key);

  @override
  State<EditProdukPage> createState() => _EditProdukPageState();
}

class _EditProdukPageState extends State<EditProdukPage> {
  late TextEditingController nama;
  late TextEditingController kategori;
  late TextEditingController stok;
  late TextEditingController harga;
  late TextEditingController asal_daerah;
  late TextEditingController deskripsi;
  late TextEditingController cerita_budaya;

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    nama = TextEditingController(text: widget.produk.nama);
    kategori = TextEditingController(text: widget.produk.kategori);
    stok = TextEditingController(text: widget.produk.stok);
    harga = TextEditingController(text: widget.produk.harga);
    asal_daerah = TextEditingController(text: widget.produk.asalDaerah);
    deskripsi = TextEditingController(text: widget.produk.deskripsi);
    cerita_budaya = TextEditingController(text: widget.produk.ceritaBudaya);
  }

  Future<void> _updateProduk() async {
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'id': widget.produk.id,
        'nama': nama.text,
        'kategori': kategori.text,
        'harga': harga.text,
        'stok': stok.text,
        'asal_daerah': asal_daerah.text,
        'deskripsi': deskripsi.text,
        'cerita_budaya': cerita_budaya.text,
        if (_selectedImage != null)
          'gambar': await MultipartFile.fromFile(
            _selectedImage!.path,
            filename: _selectedImage!
                .path
                .split('/')
                .last,
          ),
      });

      final response = await dio.post(
        'https://alpatt.fortunis11.com/produk/Update.php',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk berhasil diperbarui')),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception("Gagal update: ${response.data}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Produk"),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildTextField(nama, 'Nama Produk'),
            buildTextField(kategori, 'Kategori'),
            buildTextField(stok, 'Stok'),
            buildTextField(harga, 'Harga'),
            buildTextField(asal_daerah, 'Asal Daerah'),
            buildTextField(deskripsi, 'Deskripsi', maxLines: 2),
            buildTextField(cerita_budaya, 'Cerita Budaya', maxLines: 2),

            ElevatedButton.icon(
              onPressed: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                    source: ImageSource.gallery);
                if (picked != null) {
                  setState(() {
                    _selectedImage = File(picked.path);
                  });
                }
              },
              icon: const Icon(Icons.image),
              label: const Text("Pilih Gambar Baru"),
            ),

            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Image.file(_selectedImage!, height: 150),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Image.network(
                  "https://alpatt.fortunis11.com/produk/${widget.produk
                      .gambar}",
                  height: 150,
                  errorBuilder: (context, error, stackTrace) =>
                  const Text("Gambar gagal dimuat"),
                ),
              ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                    "Simpan Perubahan", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _updateProduk,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

// ------------------- TAMBAH PRODUK -------------------
class TambahProdukPage extends StatefulWidget {
  final String? initialKategori;

  const TambahProdukPage({super.key, this.initialKategori});

  @override
  State<TambahProdukPage> createState() => _TambahProdukPageState();
}

class _TambahProdukPageState extends State<TambahProdukPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nama = TextEditingController();
  final TextEditingController kategori = TextEditingController();
  final TextEditingController harga = TextEditingController();
  final TextEditingController stok = TextEditingController();
  final TextEditingController asalDaerah = TextEditingController();
  final TextEditingController deskripsi = TextEditingController();
  final TextEditingController ceritaBudaya = TextEditingController();

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.initialKategori != null) {
      kategori.text = widget.initialKategori!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Produk"),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildTextField(controller: nama, label: 'Nama Produk'),
              buildTextField(controller: kategori, label: 'Kategori'),
              buildTextField(controller: harga, label: 'Harga', inputType: TextInputType.number),
              buildTextField(controller: stok, label: 'Stok', inputType: TextInputType.number),
              buildTextField(controller: asalDaerah, label: 'Asal Daerah'),
              buildTextField(controller: deskripsi, label: 'Deskripsi', maxLines: 3),
              buildTextField(controller: ceritaBudaya, label: 'Cerita Budaya', maxLines: 3),

              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text("Pilih Gambar"),
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

                  if (pickedFile != null) {
                    setState(() {
                      _selectedImage = File(pickedFile.path);
                    });
                  }
                },
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Image.file(_selectedImage!, height: 150),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "Simpan Produk",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    try {
                      final dio = Dio();
                      String url = "https://alpatt.fortunis11.com/produk/create.php";

                      FormData formData = FormData.fromMap({
                        'nama': nama.text,
                        'kategori': kategori.text,
                        'harga': harga.text,
                        'stok': stok.text,
                        'asal_daerah': asalDaerah.text,
                        'deskripsi': deskripsi.text,
                        'cerita_budaya': ceritaBudaya.text,
                        if (_selectedImage != null)
                          'gambar': await MultipartFile.fromFile(
                            _selectedImage!.path,
                            filename: _selectedImage!.path.split('/').last,
                          ),
                      });

                      final response = await dio.post(url, data: formData);

                      if (response.statusCode == 200 &&
                          response.data['message'] == 'Produk berhasil ditambahkan') {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Produk berhasil ditambahkan')),
                          );
                          Navigator.pop(context);
                        }
                      } else {
                        throw Exception("Upload gagal");
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menambahkan produk: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
