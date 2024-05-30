import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'asesorias_detail.dart';

class ToTakeScreen extends StatefulWidget {
  const ToTakeScreen({super.key});

  @override
  _ToTakeScreenState createState() => _ToTakeScreenState();
}

class _ToTakeScreenState extends State<ToTakeScreen> {
  Future<List<Map<String, dynamic>>> _getAdvisories() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('asesorias')
        .where('assistants', arrayContains: user.uid)
        .get();

    return querySnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      data['fecha'] = (data['fecha'] as Timestamp).toDate();
      return {
        'id': doc.id,
        'title': data['nombreMateria'] ?? 'Sin título',
        'author': data['author'] ?? 'Autor no disponible',
        'date': (data['fecha'] as Timestamp).toDate().toString().split(' ')[0],
        'time': data['hora'] ?? 'Hora desconocida',
        'image': data['imagenURL'] ?? '',
        'descripcion': data['descripcion'] ?? 'No hay descripción disponible',
        'tags': List<String>.from(data['tags'] ?? []),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Asesorías a Tomar"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAdvisories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/missing.png',
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Aún no tienes asesorías inscritas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Parece que aún no te has inscrito en ninguna asesoría',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final asesorias = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: asesorias.length,
            itemBuilder: (context, index) {
              final asessoria = asesorias[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AsesoriasDetail(asessoria: asessoria),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: asessoria['image'].isNotEmpty
                          ? NetworkImage(asessoria['image'])
                          : const AssetImage('assets/images/missing.png')
                              as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              asessoria['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              asessoria['author'],
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              asessoria['date'],
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
