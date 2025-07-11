import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'home.dart';
import 'produk.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

// ------------------ APP ENTRY ------------------
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heritage Culture',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
      routes: {
        'tambahproduk': (context) => const TambahProdukPage(),
      },
    );
  }
}

// ------------------ LOGIN PAGE ------------------
class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _login() async {
    String username = usernameController.text;
    String password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username dan Password wajib diisi')),
      );
      return;
    }

    try {
      var response = await Dio().post(
        'https://alpatt.fortunis11.com/users/login.php',
        data: {'username': username, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data['message'] == 'Login berhasil') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', response.data['user']['username']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Home(username: response.data['user']['username']),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan saat login')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // nama aplikasi
              Text(
                'HERITAGE CULTURE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[700],
                ),
              ),
              SizedBox(height: 40),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              SizedBox(height: 32),

              // Tombol Login
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'Login',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),

              SizedBox(height: 16),

              // Link daftar akun
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RegisterPage()),
                      );
                    },
                    child: Text('Daftar akun disini', style: TextStyle(color: Colors.black)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DaftarUserPage()),
                      );
                    },
                    child: Text('Daftar akun pengguna', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ REGISTER PAGE ------------------
class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _register() async {
    String username = usernameController.text;
    String password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua field wajib diisi')),
      );
      return;
    }

    try {
      var response = await Dio().post(
        'https://alpatt.fortunis11.com/users/register.php',
        data: {'username': username, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      String message = response.data['message'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

      if (message == 'Registrasi berhasil') {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan saat registrasi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrasi'),
      backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'Daftar',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ DAFTAR USER PAGE ------------------
class DaftarUserPage extends StatefulWidget {
  @override
  State<DaftarUserPage> createState() => _DaftarUserPageState();
}

class _DaftarUserPageState extends State<DaftarUserPage> {
  List<dynamic> userList = [];
  bool isLoading = true;

  Future<void> fetchUsers() async {
    try {
      var response = await Dio().get(
          'https://alpatt.fortunis11.com/users/daftaruser.php');
      final data = response.data;

      if (data is List) {
        setState(() {
          userList = data;
          isLoading = false;
        });
      } else {
        throw Exception('Data bukan list');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data user: ${e.toString()}')),
      );
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      var response = await Dio().post(
        'https://alpatt.fortunis11.com/users/delete.php',
        data: {'id': id},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data['message'].toString().contains('berhasil')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User berhasil dihapus')),
        );
        fetchUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus user: ${e.toString()}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar User',),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userList.isEmpty
          ? Center(child: Text('Tidak ada data pengguna.'))
          : ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: userList.length,
        separatorBuilder: (context, index) => SizedBox(height: 10),
        itemBuilder: (context, index) {
          final user = userList[index];
          final username = user['username'] ?? '';
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: Colors.brown[700],
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                username,
                style: TextStyle(fontSize: 18,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteUser(user['id']),
              ),
            ),
          );
        },
      ),
    );
  }
}