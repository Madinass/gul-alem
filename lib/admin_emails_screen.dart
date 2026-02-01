import 'package:flutter/material.dart';
import 'services/api_service.dart';

class AdminEmailsScreen extends StatefulWidget {
  const AdminEmailsScreen({super.key});

  @override
  State<AdminEmailsScreen> createState() => _AdminEmailsScreenState();
}

class _AdminEmailsScreenState extends State<AdminEmailsScreen> {
  final Color darkPink = const Color(0xFFE60064);
  bool _loading = true;
  List<dynamic> admins = [];

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    try {
      final data = await ApiService.fetchAdmins();
      if (!mounted) return;
      setState(() {
        admins = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addAdmin() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Әкімші қосу'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Эл. пошта'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Бас тарту')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: darkPink),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сақтау'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await ApiService.addAdmin(controller.text.trim());
      await _loadAdmins();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _removeAdmin(String email) async {
    try {
      await ApiService.removeAdmin(email);
      await _loadAdmins();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Әкімшілер', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: darkPink,
        onPressed: _addAdmin,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE60064)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: admins.length,
              itemBuilder: (context, index) {
                final admin = admins[index];
                final email = admin['email']?.toString() ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Color(0xFFE60064)),
                    title: Text(email),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _removeAdmin(email),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
