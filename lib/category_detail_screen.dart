import 'package:flutter/material.dart';

class CategoryDetailScreen extends StatelessWidget {
  final int categoryIndex;
  const CategoryDetailScreen({super.key, required this.categoryIndex});

  @override
  Widget build(BuildContext context) {
    final Color darkPink = const Color.fromARGB(255, 230, 0, 100);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("$categoryIndex - категория", style: const TextStyle(color: Colors.black)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 80, color: darkPink),
            const SizedBox(height: 20),
            Text(
              "Бұл $categoryIndex-ші бөлім",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Бұл жерде сіз таңдаған санаттағы ең әдемі гүлдер жинақталған. Креативті дизайн бойынша осы жерге өнімдер тізімін қосамыз.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}