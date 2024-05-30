import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'asesorias_detail.dart';

class CompletedAsesoriasScreen extends StatelessWidget {
  const CompletedAsesoriasScreen({super.key});

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
        title: const Text("Asesorías Completadas"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('asesorias')
            .where('assistants',
                arrayContains: FirebaseAuth.instance.currentUser!.uid)
            .where('fecha', isLessThan: Timestamp.now())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay asesorías completadas.'));
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
                    child: Text('No hay asesorías completadas.'));
              }
              final asesoriasList = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(8),
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

                      if (result == true) {}
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: asessoria['image'].isNotEmpty
                            ? Image.network(asessoria['image'],
                                width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.image, size: 50),
                        title: Text(asessoria['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(asessoria['author']),
                            Text('Fecha: ${asessoria['date']}'),
                            Text('Hora: ${asessoria['time']}'),
                          ],
                        ),
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
