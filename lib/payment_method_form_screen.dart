import 'package:flutter/material.dart';
import 'services/api_service.dart';

class PaymentMethodFormScreen extends StatefulWidget {
  const PaymentMethodFormScreen({super.key});

  @override
  State<PaymentMethodFormScreen> createState() => _PaymentMethodFormScreenState();
}

class _PaymentMethodFormScreenState extends State<PaymentMethodFormScreen> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expMonthController = TextEditingController();
  final _expYearController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _expMonthController.dispose();
    _expYearController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final number = _numberController.text.trim();
    final expMonth = _expMonthController.text.trim();
    final expYear = _expYearController.text.trim();
    final cvv = _cvvController.text.trim();
    if (name.isEmpty || number.isEmpty || expMonth.isEmpty || expYear.isEmpty || cvv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Барлық өрістерді толтырыңыз')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.createPaymentMethod(
        cardholderName: name,
        cardNumber: number,
        expMonth: expMonth,
        expYear: expYear,
        cvv: cvv,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Төлем әдісін сақтау сәтсіз')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool obscure = false}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFFFF6F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkPink = const Color(0xFFE60064);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Төлем әдісін қосу', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildField('Карта иесінің аты', _nameController),
            const SizedBox(height: 12),
            _buildField('Карта нөмірі', _numberController, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField('Аяқталу айы', _expMonthController, keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField('Аяқталу жылы', _expYearController, keyboardType: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildField('CVV', _cvvController, keyboardType: TextInputType.number, obscure: true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Сақтау', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
