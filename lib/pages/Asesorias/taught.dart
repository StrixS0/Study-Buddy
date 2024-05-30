import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'asesorias_detail.dart';

class ImpartidasScreen extends StatefulWidget {
  const ImpartidasScreen({super.key});

  @override
  _ImpartidasScreenState createState() => _ImpartidasScreenState();
}

class _ImpartidasScreenState extends State<ImpartidasScreen> {
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
        title: const Text("Asesorías Impartidas"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('asesorias')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .where('status', isEqualTo: 'impartida')
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
                    'Aún no has impartido asesorías',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Parece que aún no has impartido ninguna asesoría',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }

          final asesorias = snapshot.data!.docs.map((doc) async {
            final data = doc.data() as Map<String, dynamic>;
            final userName = await _getUserName(data['userId']);
            return {
              'id': doc.id,
              'title': data['nombreMateria'] ?? 'Sin título',
              'author': userName,
              'date': (data['fecha'] as Timestamp?)
                      ?.toDate()
                      .toString()
                      .split(' ')[0] ??
                  'Fecha desconocida',
              'time': data['hora'] ?? 'Hora desconocida',
              'image': data['imagenURL'] ?? '',
              'tags': List<String>.from(data['tags'] ?? []),
              'assistants': List<String>.from(data['assistants'] ?? []),
              'descripcion':
                  data['descripcion'] ?? 'No hay descripción disponible',
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
                    child: Text('No hay asesorías impartidas disponibles'));
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
          );
        },
      ),
    );
  }
}
