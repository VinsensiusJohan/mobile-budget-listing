import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgetlisting/models/transaction_model.dart';
import 'package:budgetlisting/models/location_model.dart';
import 'package:budgetlisting/services/transaction_service.dart';
import 'package:budgetlisting/services/location_service.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();

  String? _type;
  String? _currencyCode = 'IDR';
  String? _timeZone = 'Asia/Jakarta';
  DateTime _selectedDate = DateTime.now();
  double _currencyRate = 1.0;

  final List<String> _types = ['income', 'expense'];
  final List<String> _currencies = ['USD', 'JPY', 'EUR', 'SGD', 'IDR'];
  final Map<String, double> _currencyRates = {
    'USD': 16200.0,
    'JPY': 112.0,
    'EUR': 18500.0,
    'SGD': 12600.0,
    'IDR': 1.0
  };

  final Map<String, String> _timezones = {
    'Asia/Jakarta': 'WIB',
    'Asia/Makassar': 'WITA',
    'Asia/Jayapura': 'WIT',
    'Europe/London': 'London',
  };

  List<Location> _allLocations = [];
  Location? _selectedLocation;
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadAllLocations();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _loadAllLocations() async {
    setState(() {
      _isLoadingLocation = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final results = await LocationService().getAllLocations(token);
      setState(() {
        _allLocations = results;
      });
    } catch (e) {
      setState(() {
        _allLocations = [];
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    print('Selected location: ${_selectedLocation?.name}');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Token not found')));
      return;
    }

    final transaction = Transaction(
      type: _type!,
      amount: double.parse(_amountController.text),
      category: _categoryController.text,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      currencyCode: _currencyCode,
      currencyRate: _currencyRate, 
      timeZone: _timeZone,
      locationName: _selectedLocation?.name,
    );

    print('Payload: ${transaction.toJson()}');
    final result = await TransactionAPI.addTransaction(transaction, token);

    if (result['message'] == 'Transaction added successfully' ||
        result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${result['message'] ?? 'Unknown error'}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator:
                    (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipe'),
                items:
                    _types
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (val) => setState(() => _type = val),
                validator: (val) => val == null ? 'Pilih tipe' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Jumlah'),
                keyboardType: TextInputType.number,
                validator:
                    (val) =>
                        val == null || double.tryParse(val) == null
                            ? 'Masukkan angka valid'
                            : null,
              ),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Choose Date'),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Currency'),
                items:
                    _currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                value: _currencyCode,
                onChanged: (val) {
                  setState(() {
                    _currencyCode = val;
                    _currencyRate = _currencyRates[val] ?? 1.0;
                  });
                },
              ),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Timezone'),
                items:
                    _timezones.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                value: _timeZone,
                onChanged: (val) => setState(() => _timeZone = val),
              ),
              const SizedBox(height: 12),
              if (_isLoadingLocation)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
              if (!_isLoadingLocation)
                DropdownButtonFormField<Location>(
                  decoration: const InputDecoration(
                    labelText: 'Pilih Lokasi (opsional)',
                  ),
                  items:
                      _allLocations
                          .map(
                            (loc) => DropdownMenuItem(
                              value: loc,
                              child: Text(loc.name),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() => _selectedLocation = val);
                  },
                  value: _selectedLocation,
                  isExpanded: true,
                  isDense: true,
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
