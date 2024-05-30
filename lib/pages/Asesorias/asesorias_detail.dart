import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'asesoria_edit.dart';

class AsesoriasDetail extends StatelessWidget {
  final Map<String, dynamic> asessoria;

  const AsesoriasDetail({super.key, required this.asessoria});

  void _markAsImparted(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('asesorias')
          .doc(asessoria['id'])
          .update({'status': 'impartida'});
      _showSnackBar(context, 'Asesoría marcada como impartida', Colors.green);
    } catch (error) {
      _showSnackBar(
          context, 'Error al marcar como impartida: $error', Colors.red);
    }
  }

  void _cancelAsesoria(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('asesorias')
          .doc(asessoria['id'])
          .update({'status': 'cancelada'});
      _showSnackBar(context, 'Asesoría cancelada', Colors.red);
    } catch (error) {
      _showSnackBar(
          context, 'Error al cancelar la asesoría: $error', Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );

    Future.microtask(() {
      Navigator.pop(context, true);
    });
  }

  Future<String> _getAuthorName(String userId) async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        return "${userData['nombre'] ?? 'Nombre no disponible'} ${userData['apellido'] ?? 'Apellido no disponible'}";
      } else {
        return 'Autor no disponible';
      }
    } catch (e) {
      return 'Autor no disponible';
    }
  }

  Future<List<String>> _getAssistantsNames(List<dynamic> assistants) async {
    List<String> assistantsNames = [];
    for (var userId in assistants) {
      var userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        assistantsNames.add(
            "${userData['nombre'] ?? 'Nombre no disponible'} ${userData['apellido'] ?? 'Apellido no disponible'}");
      } else {
        assistantsNames.add('Asistente no disponible');
      }
    }
    return assistantsNames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información de tu Asesoría'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<String>(
          future: _getAuthorName(asessoria['userId'] ?? ''),
          builder: (context, snapshot) {
            String authorName = 'Autor no disponible';
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              authorName = snapshot.data!;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: asessoria['imagenURL'] != null &&
                          asessoria['imagenURL'].isNotEmpty
                      ? Image.network(
                          asessoria['imagenURL'],
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/images/missing.png',
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  asessoria['nombreMateria'] ?? 'Nombreasd',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                Text(
                  authorName,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text(asessoria['fecha'] != null
                        ? (asessoria['fecha'] as Timestamp)
                            .toDate()
                            .toString()
                            .split(' ')[0]
                        : 'Fecha no disponible'),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time),
                    const SizedBox(width: 8),
                    Text(asessoria['hora'] ?? 'Hora no disponible'),
                  ],
                ),
                const SizedBox(height: 16),
                if (asessoria.containsKey('link') &&
                    asessoria['link'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        // Aquí puedes agregar la lógica para abrir el link
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.link),
                          const SizedBox(width: 8),
                          Text(
                            asessoria['link'],
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Text(
                  'Asistentes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                FutureBuilder<List<String>>(
                  future: _getAssistantsNames(asessoria['assistants'] ?? []),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return const Text('Error al cargar asistentes');
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('No hay asistentes');
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          snapshot.data!.map((name) => Text(name)).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Etiquetas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Wrap(
                  spacing: 8.0,
                  children: (asessoria['tags'] ?? [])
                      .map<Widget>((tag) =>
                          Chip(label: Text(tag ?? 'Etiqueta no disponible')))
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Descripción',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  asessoria['descripcion'] ?? 'No hay descripción disponible',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(25.0)),
                        ),
                        builder: (context) => Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text('Editar Asesoría'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditAsesoriaScreen(
                                        asessoria: asessoria,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.check),
                                title: const Text('Marcar como Impartida'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _markAsImparted(context);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.cancel),
                                title: const Text('Cancelar Asesoría'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _cancelAsesoria(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: const Text('Opciones'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
