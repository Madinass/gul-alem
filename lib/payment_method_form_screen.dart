import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_language.dart';
import 'payment_card_input.dart';
import 'services/api_service.dart';
import 'widgets/top_toast.dart';

class PaymentMethodFormScreen extends StatefulWidget {
  const PaymentMethodFormScreen({super.key});

  @override
  State<PaymentMethodFormScreen> createState() =>
      _PaymentMethodFormScreenState();
}

class _PaymentMethodFormScreenState extends State<PaymentMethodFormScreen> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.t;
    final name = formatCardholderName(_nameController.text).trim();
    final number = paymentCardDigits(_numberController.text);
    final expiry = parsePaymentExpiry(_expiryController.text);
    final cvv = paymentCardDigits(_cvvController.text);

    String? errorMessage;
    if (name.isEmpty) {
      errorMessage = t.invalidCardholderName;
    } else if (number.length != 16) {
      errorMessage = t.invalidCardNumber;
    } else if (expiry == null) {
      errorMessage = t.invalidExpiryDate;
    } else if (cvv.length < 3 || cvv.length > 4) {
      errorMessage = t.invalidCvv;
    }
    if (errorMessage != null) {
      showTopToast(context, errorMessage);
      return;
    }
    final validExpiry = expiry!;
    setState(() => _saving = true);
    try {
      await ApiService.createPaymentMethod(
        cardholderName: name,
        cardNumber: number,
        expMonth: validExpiry.month,
        expYear: validExpiry.year,
        cvv: cvv,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      showTopToast(context, t.savePaymentMethodFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    String? hintText,
    IconData? prefixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        filled: true,
        fillColor: const Color(0xFFFFF6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final darkPink = const Color(0xFFE60064);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          t.addPaymentMethod,
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField(
              t.cardNumber,
              _numberController,
              keyboardType: TextInputType.number,
              hintText: '1234 5678 9012 3456',
              prefixIcon: Icons.credit_card,
              inputFormatters: const [CardNumberInputFormatter()],
              autofillHints: const [AutofillHints.creditCardNumber],
            ),
            const SizedBox(height: 12),
            _buildField(
              t.cardholderName,
              _nameController,
              textCapitalization: TextCapitalization.characters,
              hintText: t.cardholderNameHint,
              prefixIcon: Icons.person_outline,
              inputFormatters: const [CardholderNameInputFormatter()],
              autofillHints: const [AutofillHints.creditCardName],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    t.expiryDate,
                    _expiryController,
                    keyboardType: TextInputType.number,
                    hintText: '08/28',
                    prefixIcon: Icons.calendar_today_outlined,
                    inputFormatters: const [ExpiryDateInputFormatter()],
                    autofillHints: const [
                      AutofillHints.creditCardExpirationDate,
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    t.cvv,
                    _cvvController,
                    keyboardType: TextInputType.number,
                    obscure: true,
                    hintText: '123',
                    prefixIcon: Icons.lock_outline,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    autofillHints: const [AutofillHints.creditCardSecurityCode],
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(t.save, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
