import 'package:flutter/material.dart';
import 'package:spotify/common/widgets/appbar/app_bar.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BasicAppbar(
        title: Text("data"),
      ),
      body: Container(
        color: Colors.red,
      ),
    );
  }
}
