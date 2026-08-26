import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiClient _apiClient = ApiClient();

  String _status = 'Checking backend...';

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    try {
      final result = await _apiClient.getHealth();

      if (!mounted) return;

      setState(() {
        _status = '${result['status']} — ${result['service']}';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _status = 'Backend unavailable';
      });
    }
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avijit Sahyog'),
      ),
      body: Center(
        child: Text(
          _status,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}