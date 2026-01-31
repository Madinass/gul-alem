import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const darkPink = Color.fromARGB(255, 230, 0, 100);
    final softPink = darkPink.withOpacity(0.1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Хабарламалар', style: TextStyle(color: darkPink, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: softPink,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: darkPink.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.notifications_active_outlined, size: 60, color: Colors.orange),
                    SizedBox(height: 15),
                    Text(
                      'Жаңа хабарламалар жоқ',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Соңғы жаңартулар мен жеңілдіктер осы жерде көрсетіледі.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
