import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdvisoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> advisory;

  const AdvisoryDetailScreen({super.key, required this.advisory});

  Future<String> _getAuthorName(String? userId) async {
    if (userId == null || userId.isEmpty) {
      return "Autor desconocido";
    }

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .get();
    if (userDoc.exists) {
      var data = userDoc.data() as Map<String, dynamic>;
      return "${data['nombre'] ?? 'Nombre desconocido'} ${data['apellido'] ?? 'Apellido desconocido'}";
    } else {
      return "Autor desconocido";
    }
  }

  Future<void> _inscribirse(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('asesorias')
          .doc(advisory['id'])
          .update({
        'assistants': FieldValue.arrayUnion([user.uid])
      });

      await _sendConfirmationEmail(user.email, advisory);

      Fluttertoast.showToast(
        msg: "Inscripción Exitosa",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      Navigator.pop(context, true);
    }
  }

  Future<void> _sendConfirmationEmail(
      String? userEmail, Map<String, dynamic> advisory) async {
    const sendGridApiKey =
        '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';

    final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $sendGridApiKey',
    };

    final body = jsonEncode({
      'personalizations': [
        {
          'to': [
            {'email': userEmail}
          ],
          'subject': 'Confirmación de inscripción a la asesoría'
        }
      ],
      'from': {'email': 'eduardosocp@gmail.com'},
      'content': [
        {
          'type': 'text/plain',
          'value':
              'Te has inscrito exitosamente a la asesoría de ${advisory['nombreMateria']}.'
        }
      ]
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 202) {
      throw Exception('Error al enviar el correo: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Asesoría'),
      ),
      body: FutureBuilder<String>(
        future: _getAuthorName(advisory['userId'] as String?),
        builder: (context, snapshot) {
          String author = 'Autor desconocido';
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            author = snapshot.data!;
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (advisory['imagenURL'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        advisory['imagenURL'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16.0),
                  Text(
                    advisory['nombreMateria'] ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    author,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        'Información',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(width: 24.0),
                      const Text(
                        'Etiquetas',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 20),
                              const SizedBox(width: 4.0),
                              Text(advisory['hora'] ?? 'Hora desconocida',
                                  style: const TextStyle(fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 20),
                              const SizedBox(width: 4.0),
                              Text(advisory['lugar'] ?? 'Lugar desconocido',
                                  style: const TextStyle(fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              const Icon(Icons.class_, size: 20),
                              const SizedBox(width: 4.0),
                              Text(
                                  advisory['modalidad'] ??
                                      'Modalidad desconocida',
                                  style: const TextStyle(fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (advisory['tags'] as List<dynamic>? ?? [])
                            .map((tag) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Chip(
                              label: Text(tag.toString(),
                                  style: const TextStyle(fontSize: 16)),
                              backgroundColor: Colors.deepPurple[50],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    advisory['descripcion'] ?? 'No hay descripción disponible',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16.0),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _inscribirse(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 20),
                      ),
                      child: const Text('La quiero tomar'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
