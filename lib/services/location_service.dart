import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:budgetlisting/models/location_model.dart';

class LocationService {
  final String baseUrl = 'https://budget-listing.onrender.com/api';

  Future<List<Location>> getAllLocations(String token) async {
    final url = Uri.parse('$baseUrl/locations');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List locationsJson = data['locations'];
      return locationsJson.map((json) => Location.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load locations');
    }
  }
}
