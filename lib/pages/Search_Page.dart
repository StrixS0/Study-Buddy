import 'dart:math';

import 'package:flutter/material.dart';
import 'EnrollScreen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> allTags = [
    'Física I',
    'Física II',
    'Optativa I FBP',
    'Sistemas digitales y lab',
    'Arquitectura de computadoras',
    'Optimización',
    'Optativa I FP',
    'Optativa II FP y Lab',
    'Certificación',
    'Investigación',
    'Proyectos especiales',
    'Estancia en la Industria',
    'Movilidad Académica',
    'Unidades de aprendizaje de Libre Elección',
    'Programa de Ingeniero Emprendedor',
    'Programa de Educación Continua',
    'Física I y Lab',
    'Física II y Lab',
    'Optativa I FBP y Lab',
    'Matemáticas Discretas',
    'Matemáticas III',
    'Matemáticas IV',
    'Algoritmos y Estructuras de Datos',
    'Lenguajes de programación',
    'Sistemas Operativos',
    'Matemáticas',
    'Automatización y Control de Sistemas Dinámicos',
    'Cómputo Integrado y Lab',
    'Verificación y Validación de Software',
    'Proyecto Integrador I',
    'Proyecto Integrador II',
    'Proyecto Integrador III',
    'Transmisión y comunicación de datos y lab',
    'Ambiente y Sustentabilidad',
    'Contexto Social de la Profesión',
    'Ética, Sociedad y Profesión',
    'Tópicos Selectos para el Desarrollo Académico y Profesional',
    'Competencia Comunicativa',
    'Apreciación a las Artes',
    'Tópicos Selectos de Lenguas y Culturas Extranjeras',
    'Dibujo para Ingeniería',
    'Química General y Lab',
    'Aplicación de las Tecnologías de Información',
    'Laboratorio Optativa II FBP',
    'Interacción humana-computadora y Lab',
    'Taller de Programación orientada a objetos',
    'Taller de Programación',
    'Programación orientada a objetos',
    'Diseño de Experimentos',
    'Modelado y Simulación de Sistemas Dinámicos',
    'Temas Selectos de Optimización',
    'Temas Selectos de Ciencias Sociales, Artes y Humanidades'
  ];

  List<String> popularTags = [];
  List<String> selectedTags = [];
  String searchTerm = '';
  List<Map<String, dynamic>> searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchTerm = _searchController.text.trim().toLowerCase();
      });
      _searchAdvisories();
    });
    _selectRandomTags();
  }

  void _selectRandomTags() {
    final random = Random();
    Set<String> uniqueTags = {};
    while (uniqueTags.length < 10) {
      uniqueTags.add(allTags[random.nextInt(allTags.length)]);
    }
    setState(() {
      popularTags = uniqueTags.toList();
    });
  }

  Future<void> _searchAdvisories() async {
    try {
      QuerySnapshot querySnapshot;

      if (searchTerm.isEmpty && selectedTags.isEmpty) {
        setState(() {
          searchResults = [];
        });
        return;
      }

      if (selectedTags.isNotEmpty) {
        querySnapshot = await FirebaseFirestore.instance
            .collection('asesorias')
            .where('tags', arrayContainsAny: selectedTags)
            .get();
      } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('asesorias')
            .where('nombreMateriaLower', isGreaterThanOrEqualTo: searchTerm)
            .where('nombreMateriaLower',
                isLessThanOrEqualTo: '$searchTerm\uf8ff')
            .get();
      }

      setState(() {
        searchResults = querySnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          data['fecha'] = (data['fecha'] as Timestamp).toDate();
          return data;
        }).toList();
      });
    } catch (e) {
      print('Error searching advisories: $e');
      setState(() {
        searchResults = [];
      });
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
    });
    _searchAdvisories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Asesorías'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Temas Populares',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: popularTags.map((tag) {
                return ChoiceChip(
                  label: Text(tag),
                  selected: selectedTags.contains(tag),
                  onSelected: (_) {
                    _toggleTag(tag);
                  },
                  selectedColor: Colors.blue[100],
                  backgroundColor: Colors.blue[50],
                );
              }).toList(),
            ),
            const SizedBox(height: 16.0),
            if (searchResults.isEmpty &&
                searchTerm.isEmpty &&
                selectedTags.isEmpty)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.help_outline, size: 100, color: Colors.grey),
                    SizedBox(height: 16.0),
                    Text(
                      '¿De qué necesitas asesorarte hoy?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if (searchResults.isEmpty)
              const Center(
                child: Text(
                  'No se encontraron resultados',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  var advisory = searchResults[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      leading: advisory['imagenURL'] != null
                          ? Image.network(advisory['imagenURL'],
                              width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.image, size: 50),
                      title: Text(advisory['nombreMateria'] ?? 'Sin nombre'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(advisory['descripcion'] ?? 'Sin descripción'),
                          Text(
                              'Fecha: ${advisory['fecha'].toString().split(' ')[0]}'),
                          Text('Modalidad: ${advisory['modalidad']}'),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                AdvisoryDetailScreen(advisory: advisory),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
