import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgetlisting/pages/add_location_page.dart';
import 'package:budgetlisting/pages/add_page.dart';
import 'package:budgetlisting/pages/detail_page.dart';
import 'package:budgetlisting/pages/login_register_page.dart';
import 'package:budgetlisting/models/transaction_model.dart';
import 'package:budgetlisting/services/transaction_service.dart';
import 'package:budgetlisting/pages/pesan_page.dart';
import 'package:budgetlisting/pages/profil_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Transaction> transactions = [];
  bool isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      logout(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> fetchTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await TransactionAPI.getTransactions(token);
      if (response['transactions'] != null) {
        setState(() {
          transactions =
              (response['transactions'] as List)
                  .map((json) => Transaction.fromJson(json))
                  .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginRegisterPage()),
    );
  }

  Future<void> navigateToAddPage() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionPage()),
    );
    if (added == true) {
      fetchTransactions();
    }
  }

  Future<void> navigateToAddLocationPage() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddLocationPage()),
    );
    if (added == true) {
      fetchTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      buildHomePageContent(),
      const ProfilePage(),
      const PesanPage(),
      Container(),
    ];

    return Scaffold(
      appBar:
          _selectedIndex == 0
              ? AppBar(title: const Text('Dashboard'))
              : null, 
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Pesan'),
          BottomNavigationBarItem(icon: Icon(Icons.exit_to_app), label: 'Exit'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget buildHomePageContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Tambah Transaksi'),
            onPressed: navigateToAddPage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 10,),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_location),
            label: const Text('Tambah Lokasi'),
            onPressed: navigateToAddLocationPage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                transactions.isEmpty
                    ? const Center(child: Text("No transactions found"))
                    : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final t = transactions[index];
                        final amount = t.amount ?? 0;
                        final rate = t.currencyRate ?? 1.0;
                        final totalInIDR = amount * rate;

                        final formattedIDR = NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                        ).format(totalInIDR);
                        final formattedOriginal = NumberFormat.currency(
                          locale: 'en_US',
                          symbol: '${t.currencyCode ?? ''} ',
                          decimalDigits: 0,
                        ).format(amount);

                        return ListTile(
                          title: Text(
                            "${t.type?.toUpperCase()} - $formattedIDR ($formattedOriginal)",
                          ),
                          subtitle: Text("${t.category} • ${t.date}"),
                          trailing: Text(t.note ?? ""),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        DetailPage(transactionId: t.id!),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
