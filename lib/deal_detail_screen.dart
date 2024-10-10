import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DealDetailsScreen extends StatefulWidget {
  final String dealId;

  DealDetailsScreen({required this.dealId});

  @override
  _DealDetailsScreenState createState() => _DealDetailsScreenState();
}

class _DealDetailsScreenState extends State<DealDetailsScreen> {
  Map<String, dynamic>? _dealDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDealDetails(widget.dealId);
  }

  Future<void> _fetchDealDetails(String dealId) async {
    final url = Uri.parse('https://www.cheapshark.com/api/1.0/deals?id=$dealId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _dealDetails = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load deal details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deal Details'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dealDetails?['gameInfo']['name'] ?? 'No name',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Image.network(_dealDetails?['gameInfo']['thumb'] ?? ''),
            SizedBox(height: 10),
            Text('Price: \$${_dealDetails?['gameInfo']['salePrice'] ?? 'N/A'}'),
            Text('Retail Price: \$${_dealDetails?['gameInfo']['retailPrice'] ?? 'N/A'}'),
            Text('Steam Rating: ${_dealDetails?['gameInfo']['steamRatingText'] ?? 'N/A'}'),
            SizedBox(height: 10),
            Text(
              'Cheaper Deals:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Expanded(
              child: ListView.builder(
                itemCount: (_dealDetails?['cheaperStores'] as List).length,
                itemBuilder: (context, index) {
                  final cheaperDeal = _dealDetails?['cheaperStores'][index];
                  return ListTile(
                    title: Text('Store ID: ${cheaperDeal['storeID']}'),
                    subtitle: Text('Sale Price: \$${cheaperDeal['salePrice']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
