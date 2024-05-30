import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pia_moviles/pages/editar_perfil.dart';
import 'package:pia_moviles/pages/enrolledadvisoryscreen.dart';
import 'ExploreScreen.dart';
import 'login.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userName;
  String? photoURL;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    User? user = _auth.currentUser;
    final uid = user?.uid;

    if (uid != null) {
      var userData = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      setState(() {
        userName =
            "${userData.data()?['nombre']} ${userData.data()?['apellido']}";
        photoURL = userData.data()?['profileImageUrl'];
      });
    }
  }

  Stream<List<Map<String, dynamic>>> _getAdvisoriesStream() {
    User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('asesorias')
        .where('assistants', arrayContains: user.uid)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['fecha'] = (data['fecha'] as Timestamp).toDate();
        return data;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hola ${userName ?? 'Usuario'}!"),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(userName ?? 'Usuario'),
              accountEmail: Text(_auth.currentUser?.email ?? ''),
              currentAccountPicture: photoURL != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(photoURL!),
                    )
                  : CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        userName?.substring(0, 1) ?? 'U',
                        style: const TextStyle(fontSize: 40.0),
                      ),
                    ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                await _auth.signOut();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const LoginScreen()));
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getAdvisoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar asesorías'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                    'Parece que aún no estás registrado en alguna asesoría',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExploreScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      textStyle:
                          const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    child: const Text('Explorar Asesorías',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          } else {
            var advisories = snapshot.data!;
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Tus próximas asesorías',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: advisories.length,
                    itemBuilder: (context, index) {
                      var advisory = advisories[index];
                      return Card(
                        margin: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        child: Column(
                          children: [
                            advisory['imagenURL'] != null
                                ? Image.network(
                                    advisory['imagenURL'],
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
                              contentPadding: const EdgeInsets.all(15),
                              title: Text(
                                advisory['nombreMateria'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  Text(
                                    advisory['descripcion'] ??
                                        'Sin descripción',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              size: 16),
                                          const SizedBox(width: 5),
                                          Text(advisory['hora'] ??
                                              'Hora desconocida'),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 16),
                                          const SizedBox(width: 5),
                                          Text(advisory['lugar'] ??
                                              'Salón desconocido'),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.class_, size: 16),
                                      const SizedBox(width: 5),
                                      Text(advisory['modalidad'] ??
                                          'Modalidad desconocida'),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EnrolledAdvisoryDetailScreen(
                                      advisory: advisory,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  setState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
