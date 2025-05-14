import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../utils/data_manager.dart';
import '../utils/api_service.dart';


class SupplementPage extends StatefulWidget {
  const SupplementPage({super.key});

  @override
  State<SupplementPage> createState() => _SupplementPageState();
}

class _SupplementPageState extends State<SupplementPage> {
  Map<String, List<Map<String, dynamic>>> supplementsByCategory = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSupplements();
  }

  Future<void> _fetchSupplements() async {
    final result = await ApiService.getRecommendedSupplements();
    setState(() {
      supplementsByCategory = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("영양제 추천")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        children: supplementsByCategory.entries.map((entry) {
          final category = entry.key;
          final supplements = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Text("🔹 ${category.replaceAll('category#', '').toUpperCase()}"),
              ),
              ...supplements.map((item) => ListTile(
                leading: Image.network(item['image'], width: 50, errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported)),
                title: Text(item['name']),
                onTap: () => launchUrl(Uri.parse(item['url']), mode: LaunchMode.externalApplication),
              )),
              Divider(),
            ],
          );
        }).toList(),
      ),
    );
  }
}

