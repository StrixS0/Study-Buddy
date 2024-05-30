import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditAsesoriaScreen extends StatefulWidget {
  final Map<String, dynamic> asessoria;

  const EditAsesoriaScreen({super.key, required this.asessoria});

  @override
  _EditAsesoriaScreenState createState() => _EditAsesoriaScreenState();
}

class _EditAsesoriaScreenState extends State<EditAsesoriaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descripcionController;
  late TextEditingController _linkController;
  late String _modalidad;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.asessoria['nombreMateria'] ?? '');
    _descripcionController = TextEditingController(text: widget.asessoria['descripcion'] ?? '');
    selectedDate = widget.asessoria['fecha'] != null 
        ? (widget.asessoria['fecha'] as Timestamp).toDate()
        : DateTime.now();
    selectedTime = widget.asessoria['hora'] != null 
        ? TimeOfDay(
            hour: int.parse(widget.asessoria['hora'].split(':')[0]), 
            minute: int.parse(widget.asessoria['hora'].split(':')[1])
          )
        : TimeOfDay.now();
    _linkController = TextEditingController(text: widget.asessoria['link'] ?? '');
    _modalidad = widget.asessoria['modalidad'] ?? 'Presencial';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descripcionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (pickedTime != null && pickedTime != selectedTime) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('asesorias')
          .child('${widget.asessoria['id']}.jpg');
      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la imagen: $e')),
      );
      return null;
    }
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        String? imageUrl = await _uploadImage();
        await FirebaseFirestore.instance
            .collection('asesorias')
            .doc(widget.asessoria['id'])
            .update({
          'nombreMateria': _titleController.text,
          'descripcion': _descripcionController.text,
          'fecha': Timestamp.fromDate(selectedDate),
          'hora': "${selectedTime.hour}:${selectedTime.minute}",
          'modalidad': _modalidad,
          'link': _modalidad == 'En línea' ? _linkController.text : null,
          if (imageUrl != null) 'imagenURL': imageUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Asesoría actualizada correctamente')));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar la asesoría: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Asesoría'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Center(
                  child: _imageFile != null
                      ? Image.file(_imageFile!, height: 200, fit: BoxFit.cover)
                      : Image.network(
                          widget.asessoria['imagenURL'] ?? 'https://via.placeholder.com/400x258',
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text("${selectedDate.toLocal()}".split(' ')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: ListTile(
                      title: Text(selectedTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _modalidad,
                items: ['Presencial', 'En línea']
                    .map((modalidad) => DropdownMenuItem(
                          value: modalidad,
                          child: Text(modalidad),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _modalidad = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Modalidad',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_modalidad == 'En línea') ...[
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Enlace a la reunión',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_modalidad == 'En línea' && (value == null || value.isEmpty)) {
                      return 'Por favor ingrese un enlace para la reunión en línea';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}