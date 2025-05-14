import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/api_service.dart';

class SupplementPage extends StatefulWidget {
  const SupplementPage({Key? key}) : super(key: key);

  @override
  State<SupplementPage> createState() => _SupplementPageState();
}

class _SupplementPageState extends State<SupplementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<String> _fixedCategories = ['칼슘', '마그네슘', '비타민', '철분'];
  Map<String, List<Map<String, dynamic>>> _supplementData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _fixedCategories.length, vsync: this);
    _fetchSupplements();
  }

  Future<void> _fetchSupplements() async {
    final result = await ApiService.getRecommendedSupplements();
    final Map<String, List<Map<String, dynamic>>> mapped = {
      '칼슘': result['category#calcium'] ?? [],
      '마그네슘': result['category#magnesium'] ?? [],
      '비타민': result['category#vitamin'] ?? [],
      '철분': result['category#iron'] ?? [],
    };
    setState(() {
      _supplementData = mapped;
      _isLoading = false;
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '영양제 추천',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 16),
          tabs: _fixedCategories.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: _fixedCategories.map((cat) {
          final list = _supplementData[cat] ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Text(
                '추천 데이터가 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: GridView.builder(
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, i) {
                final sup = list[i];
                return GestureDetector(
                  onTap: () => _openUrl(sup['url']),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CachedNetworkImage(
                          imageUrl: sup['image'] ?? '',
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 100,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 100,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sup['name'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${sup['price']}원',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}