import 'package:flutter/material.dart';
import 'Asesorias/to_teach.dart';
import 'Asesorias/taught.dart';
import 'Asesorias/to_take.dart';
import 'Asesorias/completed_asesorias.dart';

class TeachingScreen extends StatefulWidget {
  const TeachingScreen({super.key});

  @override
  _TeachingScreenState createState() => _TeachingScreenState();
}

class _TeachingScreenState extends State<TeachingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Clases'),
        bottom: TabBar(
          controller: _tabController,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(
                width: 4.0, color: Color.fromARGB(255, 107, 138, 210)),
            insets: EdgeInsets.symmetric(horizontal: 16.0),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'A impartir'),
            Tab(text: 'Impartidas'),
            Tab(text: 'Completadas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ToTeachScreen(),
          ImpartidasScreen(),
          CompletedAsesoriasScreen(),
        ],
      ),
    );
  }
}
