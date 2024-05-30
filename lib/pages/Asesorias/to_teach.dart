import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'asesorias_detail.dart';
import 'register_asesoria.dart';

class ToTeachScreen extends StatefulWidget {
  const ToTeachScreen({super.key});

  @override
  _ToTeachScreenState createState() => _ToTeachScreenState();
}

class _ToTeachScreenState extends State<ToTeachScreen> {
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
        title: const Text("Mis Asesorías"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('asesorias')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .where('status', isEqualTo: 'pending')
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
                    'Aún no tienes Asesorías',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Parece que aún no has registrado ninguna asesoría',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddAdvisory(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('Registrar Asesoría'),
                  ),
                ],
              ),
            );
          }

          final asesorias = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'nombreMateria': data['nombreMateria'] ?? 'Sin título',
              'userId': data['userId'] ?? '',
              'fecha': data['fecha'],
              'hora': data['hora'] ?? 'Hora desconocida',
              'imagenURL': data['imagenURL'] ?? '',
              'tags': List<String>.from(data['tags'] ?? []),
              'assistants': List<String>.from(data['assistants'] ?? []),
              'descripcion':
                  data['descripcion'] ?? 'No hay descripción disponible',
            };
          }).toList();

          return ListView.builder(
            itemCount: asesorias.length,
            itemBuilder: (context, index) {
              final asessoria = asesorias[index];
              return FutureBuilder<String>(
                future: _getUserName(asessoria['userId']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final author = snapshot.data ?? 'Autor no disponible';
                  return GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AsesoriasDetail(asessoria: asessoria),
                        ),
                      );

                      if (result == true) {
                        setState(() {});
                      }
                    },
                    child: Card(
                      child: Column(
                        children: [
                          asessoria['imagenURL'] != null &&
                                  asessoria['imagenURL'].isNotEmpty
                              ? Image.network(
                                  asessoria['imagenURL'],
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/images/missing.png',
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                          ListTile(
                            title: Text(asessoria['nombreMateria']),
                            subtitle: Text('Por: $author'),
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
