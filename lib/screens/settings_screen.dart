import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Nút quay lại
          onPressed: () {
            Navigator.pop(context); // Quay lại màn hình trước đó (MainScreen)
          },
        ),
        title: const Row(
          children: [
            Icon(Icons.settings), // Icon bánh răng
            SizedBox(width: 8), // Khoảng cách giữa icon và chữ
            Text('Settings'),
          ],
        ),
      ),
      body: const Center(child: Text('Cài đặt ở đây')),
    );
  }
}
