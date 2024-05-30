import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'EnrollScreen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  Future<String> _getUserName(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .get();
    return "${userDoc['nombre']} ${userDoc['apellido']}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explorar Asesorías"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('asesorias')
            .where('userId',
                isNotEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                    'No hay asesorías disponibles',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Parece que no hay asesorías disponibles en este momento',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final asesorias = snapshot.data!.docs.map((doc) async {
            final data = doc.data() as Map<String, dynamic>;
            final userName = await _getUserName(data['userId']);
            return {
              'id': doc.id,
              'nombreMateria': data['nombreMateria'] ?? 'Sin título',
              'author': userName,
              'fecha': (data['fecha'] as Timestamp?)
                      ?.toDate()
                      .toString()
                      .split(' ')[0] ??
                  'Fecha desconocida',
              'hora': data['hora'] ?? 'Hora desconocida',
              'imagenURL': data['imagenURL'] ?? '',
              'tags': List<String>.from(data['tags'] ?? []),
              'assistants': List<String>.from(data['assistants'] ?? []),
              'descripcion':
                  data['descripcion'] ?? 'No hay descripción disponible',
              'modalidad': data['modalidad'] ?? 'Modalidad desconocida',
              'lugar': data['lugar'] ?? 'Lugar desconocido',
            };
          }).toList();

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.wait(asesorias),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('No hay asesorías disponibles'));
              }
              final asesoriasList = snapshot.data!;
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: asesoriasList.length,
                itemBuilder: (context, index) {
                  final asessoria = asesoriasList[index];
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AdvisoryDetailScreen(advisory: asessoria),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: asessoria['imagenURL'].isNotEmpty
                              ? NetworkImage(asessoria['imagenURL'])
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
                                  asessoria['nombreMateria'],
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
                                  asessoria['fecha'],
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
          );
        },
      ),
    );
  }
}
