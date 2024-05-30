import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EnrolledAdvisoryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> advisory;

  const EnrolledAdvisoryDetailScreen({super.key, required this.advisory});

  @override
  _EnrolledAdvisoryDetailScreenState createState() =>
      _EnrolledAdvisoryDetailScreenState();
}

class _EnrolledAdvisoryDetailScreenState
    extends State<EnrolledAdvisoryDetailScreen> {
  bool isCancelled = false;

  Future<void> _cancelarAsistencia(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('asesorias')
          .doc(widget.advisory['id'])
          .update({
        'assistants': FieldValue.arrayRemove([user.uid])
      });

      Fluttertoast.showToast(
          msg: "Cancelada con Éxito",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);

      setState(() {
        isCancelled = true;
      });

      Navigator.pop(context,
          true); // Regresa a la pantalla anterior y marca la acción como exitosa
    }
  }

  Future<void> _inscribirAsesoria(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('asesorias')
          .doc(widget.advisory['id'])
          .update({
        'assistants': FieldValue.arrayUnion([user.uid])
      });

      Fluttertoast.showToast(
          msg: "Inscripción Exitosa",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0);

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isCancelled) {
      return Scaffold(
        appBar: AppBar(
          title:
              Text(widget.advisory['nombreMateria'] ?? 'Detalles de Asesoría'),
        ),
        body: Center(
          child: Text('Asistencia cancelada'),
        ),
      );
    }

    final fecha = widget.advisory['fecha'];
    final fechaString = fecha is Timestamp
        ? fecha.toDate().toString().split(' ')[0]
        : fecha.toString().split(' ')[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.advisory['nombreMateria'] ?? 'Detalles de Asesoría'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.advisory['imagenURL'] != null)
              Image.network(widget.advisory['imagenURL'],
                  width: double.infinity, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16.0),
            Text(widget.advisory['nombreMateria'] ?? 'Sin nombre',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Text(widget.advisory['descripcion'] ?? 'Sin descripción'),
            const SizedBox(height: 8.0),
            Text('Fecha: $fechaString'),
            const SizedBox(height: 8.0),
            Text('Hora: ${widget.advisory['hora']}'),
            const SizedBox(height: 8.0),
            Text('Modalidad: ${widget.advisory['modalidad']}'),
            if (widget.advisory['modalidad'] == 'Presencial')
              Text('Lugar: ${widget.advisory['lugar']}'),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: (widget.advisory['tags'] as List<dynamic>).map((tag) {
                return Chip(label: Text(tag.toString()));
              }).toList(),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: () => _cancelarAsistencia(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Cancelar asistencia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
