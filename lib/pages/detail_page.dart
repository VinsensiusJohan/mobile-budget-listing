import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:budgetlisting/services/transaction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgetlisting/models/transaction_model.dart';

class DetailPage extends StatefulWidget {
  final int transactionId;

  const DetailPage({Key? key, required this.transactionId}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<Transaction> _futureTransaction;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _futureTransaction = _initializeFutureTransaction();
  }

  Future<Transaction> _initializeFutureTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final json = await TransactionAPI.getTransactionById(
      token,
      widget.transactionId,
    );
    return Transaction.fromJson(json);
  }

  Future<void> _deleteTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    setState(() {
      _isDeleting = true;
    });

    try {
      await TransactionAPI.deleteTransaction(widget.transactionId, token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus')),
        );
        Navigator.of(
          context,
        ).pop(true); // Kembali dengan hasil bahwa delete berhasil
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus transaksi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  String formatCurrency(dynamic amount, String? currencyCode) {
    if (amount == null) return '-';
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: currencyCode != null ? '$currencyCode ' : 'Rp ',
      decimalDigits: 2,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: FutureBuilder<Transaction>(
        future: _futureTransaction,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Transaksi tidak ditemukan'));
          } else {
            final transaction = snapshot.data!;
            final amount = transaction.amount;
            final rate = transaction.currencyRate ?? 1.0;
            final totalInIDR = (amount != null) ? amount * rate : 0;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  ListTile(
                    title: const Text('Tipe'),
                    subtitle: Text(transaction.type ?? '-'),
                  ),
                  ListTile(
                    title: const Text('Jumlah'),
                    subtitle: Text(
                      formatCurrency(amount, transaction.currencyCode),
                    ),
                  ),
                  ListTile(
                    title: const Text('Jumlah (IDR)'),
                    subtitle: Text(formatCurrency(totalInIDR, 'Rp')),
                  ),
                  ListTile(
                    title: const Text('Nama'),
                    subtitle: Text(transaction.category ?? '-'),
                  ),
                  ListTile(
                    title: const Text('Catatan'),
                    subtitle: Text(transaction.note ?? '-'),
                  ),
                  ListTile(
                    title: const Text('Tanggal'),
                    subtitle: Text(transaction.date ?? '-'),
                  ),
                  if (transaction.locationId != null)
                    ListTile(
                      title: const Text('Lokasi'),
                      subtitle: Text(transaction.locationName ?? '-'),
                    ),
                  ListTile(
                    title: const Text('Timezone'),
                    subtitle: Text(transaction.timeZone ?? '-'),
                  ),
                  ListTile(
                    title: const Text('Dibuat pada'),
                    subtitle: Text(transaction.createdAt ?? '-'),
                  ),
                  ListTile(
                    title: const Text('Diperbarui pada'),
                    subtitle: Text(transaction.updatedAt ?? '-'),
                  ),
                  ElevatedButton(
                    onPressed: _isDeleting ? null : _deleteTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child:
                        _isDeleting
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              'Hapus Transaksi',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
