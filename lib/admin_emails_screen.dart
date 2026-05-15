import 'package:flutter/material.dart';
import 'app_language.dart';
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
    final t = context.t;
    final controller = TextEditingController();
    var role = 'admin';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(t.adminAdd),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(labelText: t.email),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: InputDecoration(labelText: t.role),
                  items: [
                    DropdownMenuItem(value: 'admin', child: Text(t.roleAdmin)),
                    DropdownMenuItem(
                      value: 'worker',
                      child: Text(t.roleWorker),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => role = value ?? 'admin'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: darkPink),
                onPressed: () => Navigator.pop(context, true),
                child: Text(t.save),
              ),
            ],
          ),
        );
      },
    );

    if (result != true) {
      controller.dispose();
      return;
    }

    try {
      await ApiService.addAdmin(controller.text.trim(), role: role);
      await _loadAdmins();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.errorWith(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _removeAdmin(String email) async {
    try {
      await ApiService.removeAdmin(email);
      await _loadAdmins();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t.errorWith(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(t.admins, style: const TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: darkPink,
        onPressed: _addAdmin,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE60064)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: admins.length,
              itemBuilder: (context, index) {
                final admin = admins[index];
                final email = admin['email']?.toString() ?? '';
                final role = t.roleLabel(admin['role']?.toString() ?? '');
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.admin_panel_settings,
                      color: Color(0xFFE60064),
                    ),
                    title: Text(email),
                    subtitle: Text(role),
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
