import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KeranjangPage extends StatefulWidget {
  const KeranjangPage({Key? key}) : super(key: key);

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  List<dynamic> keranjang = [];
  String username = '';
  bool isLoading = true;

  final Dio dio = Dio();
  final String baseUrl = 'https://alpatt.fortunis11.com/keranjang';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await getUsername();
    if (username.isNotEmpty) {
      await fetchKeranjang();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
    });
  }

  Future<void> fetchKeranjang() async {
    try {
      final response = await dio.post(
        '$baseUrl/lihatkeranjang.php',
        data: {'username': username},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data['status'] == 'success') {
        setState(() {
          keranjang = response.data['data'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> hapusProduk(String keranjangId) async {
    try {
      final response = await dio.post(
        '$baseUrl/hapuskeranjang.php',
        data: {'keranjang_id': keranjangId},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data['status'] == 'success') {
        fetchKeranjang();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus: ${response.data['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error hapus: $e')),
      );
    }
  }

  Future<void> updateKeranjang(String keranjangId, int jumlahBaru) async {
    try {
      final response = await dio.post(
        '$baseUrl/updatekeranjang.php',
        data: {
          'keranjang_id': keranjangId,
          'jumlah': jumlahBaru,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data['status'] == 'success') {
        fetchKeranjang();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui keranjang')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  int getTotalSemuaProduk() {
    int total = 0;
    for (var item in keranjang) {
      final harga = int.tryParse(item['total_harga'].toString()) ?? 0;
      total += harga;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final totalHarga = getTotalSemuaProduk();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Keranjang Belanja"),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : keranjang.isEmpty
          ? const Center(child: Text('Keranjang kamu kosong'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: keranjang.length,
              itemBuilder: (context, index) {
                final item = keranjang[index];
                final imageUrl = item['gambar']?.toString() ?? '';
                final jumlah = int.tryParse(item['jumlah'].toString()) ?? 1;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 1,
                  color: Colors.white,
                  shape: const RoundedRectangleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gambar produk
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            imageUrl,
                            width: 150,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Informasi produk
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12), // Geser info ke kanan
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['nama'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text("Rp : ${item['harga']}"),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 20),
                                      onPressed: () {
                                        if (jumlah > 1) {
                                          updateKeranjang(item['keranjang_id'].toString(), jumlah - 1);
                                        }
                                      },
                                    ),
                                    Text(
                                      '$jumlah',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 20),
                                      onPressed: () {
                                        updateKeranjang(item['keranjang_id'].toString(), jumlah + 1);
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  'Total : Rp ${item['total_harga']}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Tombol hapus
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.black),
                          tooltip: 'Hapus',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog( //Message untuk hapus
                                title: const Text('Konfirmasi'),
                                content: const Text('Apakah Anda yakin ingin menghapus produk ini dari keranjang?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      hapusProduk(item['keranjang_id'].toString());
                                    },
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Total Harga
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 3,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shopping_cart, color: Colors.black),
                      SizedBox(width: 8),
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Rp $totalHarga',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
