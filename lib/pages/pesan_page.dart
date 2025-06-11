import 'package:flutter/material.dart';

class PesanPage extends StatelessWidget {
  const PesanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const String pesan = '''
Yth. Bapak Bagus,

Saya ingin menyampaikan terima kasih atas bimbingan dan pembelajaran yang telah diberikan selama perkuliahan ini. 
Semoga Bapak selalu diberikan kesehatan dan kelancaran dalam menjalankan tugas.

Hormat saya,
Vinsensius Johan
''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan untuk Dosen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            pesan,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
