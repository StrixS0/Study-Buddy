import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? selectedCarrera;
  String? selectedSemestre;
  File? _profileImage;

  final List<String> carreras = [
    "IAS",
    "IB",
    "IAE",
    "IEA",
    "IEC",
    "IMF",
    "IMT",
    "IMTC",
    "ITS",
    "IMA",
    "IME",
  ];

  final List<String> semestres = [
    '1ero',
    '2do',
    '3er',
    '4to',
    '5to',
    '6to',
    '7mo',
    '8vo',
    '9no',
    '10mo'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          firstNameController.text = userDoc['nombre'] ?? '';
          lastNameController.text = userDoc['apellido'] ?? '';
          phoneController.text = userDoc['telefono'] ?? '';
          String? carrera = userDoc['carrera'];
          String? semestre = userDoc['semestre'];

          if (carrera != null && carreras.contains(carrera)) {
            selectedCarrera = carrera;
          } else {
            selectedCarrera = null;
          }

          if (semestre != null && semestres.contains(semestre)) {
            selectedSemestre = semestre;
          } else {
            selectedSemestre = null;
          }
        });
      }
    }
  }

  Future<void> _updateUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadProfileImage(user.uid);
      }

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({
        'nombre': firstNameController.text.trim(),
        'apellido': lastNameController.text.trim(),
        'telefono': phoneController.text.trim(),
        'carrera': selectedCarrera,
        'semestre': selectedSemestre,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado exitosamente')),
      );
      Navigator.pop(context); // Cierra la pantalla de edición
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadProfileImage(String uid) async {
    final storageRef =
        FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
    final uploadTask = storageRef.putFile(_profileImage!);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color.fromARGB(255, 215, 215, 215),
              Color.fromARGB(255, 215, 215, 215)
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Editar Perfil',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  const SizedBox(height: 48.0),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? const Icon(Icons.add_a_photo, size: 50)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      hintText: 'Nombre',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      hintText: 'Apellido',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Teléfono',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  DropdownButtonFormField<String>(
                    value: selectedCarrera,
                    hint: const Text('Selecciona tu carrera'),
                    items:
                        carreras.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedCarrera = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  DropdownButtonFormField<String>(
                    value: selectedSemestre,
                    hint: const Text('Selecciona tu semestre'),
                    items:
                        semestres.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedSemestre = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: _updateUserProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}