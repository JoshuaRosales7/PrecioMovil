import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:math_expressions/math_expressions.dart';
import 'firebase_options.dart';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:syncfusion_flutter_charts/charts.dart' as sf;
import 'package:intl/intl.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:auth_button_kit/auth_button_kit.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Inicializa Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: HexColor('#42A5F5'), // Usa el color hexadecimal
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);

    _controller.repeat(reverse: true);

    // Espera 3 segundos y luego verifica si el usuario ya ha iniciado sesión
    Timer(Duration(seconds: 3), () {
      // Verifica si el usuario ya ha iniciado sesión
      // Si ya ha iniciado sesión, navega a la pantalla principal usando AuthenticationWrapper
      // Si no ha iniciado sesión, navega a la pantalla de inicio de sesión
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            // Aquí se verifica si el usuario ya ha iniciado sesión
            // Puedes implementar tu lógica de verificación aquí
            // En este ejemplo, siempre navegamos a la pantalla de inicio de sesión
            return AuthenticationWrapper();
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexColor('#E0E1DD'), // Color de fondo del SplashScreen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _animation,
              child: Image.asset(
                'assets/logo.png', // Ruta de tu logo
                width: 300, // Ancho del logo
                height: 300, // Alto del logo
              ),
            ),
            SizedBox(height: 20),
            SpinKitCircle(
              color: HexColor('#1B263B'), // Color del Spinner
              size: 50.0, // Tamaño del Spinner
            ),
          ],
        ),
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;

    if (user != null) {
      return MenuScreen(user: user);
    } else {
      return LoginScreen();
    }
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _loading = false;

  Future<void> _handleSignIn(BuildContext context) async {
    setState(() {
      _loading = true;
    });

    try {
      // Implement Google sign-in logic using GoogleSignIn
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        // Handle successful Google sign-in
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final User user = userCredential.user!;

        // Create a Firestore document with the user's UID
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'budget': 0, // Presupuesto inicial
          'purchases': [], // Lista de compras
          'productosComprados': 0,
          'savedProducts': [], // Productos guardados
          // Agrega más datos según sea necesario
        });

        // Navigate to MenuScreen after successful sign-in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MenuScreen(user: user)),
        );
      } else {
        print("User canceled Google sign-in.");
      }
    } catch (error) {
      print("Error signing in with Google: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al iniciar sesión con Google: $error"),
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _signInAnonymously(BuildContext context) async {
    setState(() {
      _loading = true;
    });

    try {
      // Implement anonymous sign-in logic using FirebaseAuth
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInAnonymously();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => MenuScreen(user: userCredential.user!)),
      );
    } catch (error) {
      print("Error signing in anonymously: $error");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con imagen y efecto de desenfoque
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/fondo.png'), // Ruta de la imagen de fondo
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: 5, sigmaY: 5), // Aplica el efecto de desenfoque
              child: Container(
                color: HexColor('#1B263B'), // Color del fondo difuminado
              ),
            ),
          ),
          // Contenido de la pantalla
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 35.0),
                  Text(
                    'Comienza a cotizar tus productos!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 45.0, // Tamaño de fuente aumentado
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto', // Cambio de fuente
                    ),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 2.0),
                  Opacity(
                    opacity: 0.5, // Opacidad al 50%
                    child: Text(
                      'PrecioMóvil es una aplicación para realizar cotizaciones de productos de forma rápida y sencilla.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.0, // Tamaño de fuente reducido
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Spacer(), // Alineación al centro
                  // Alineación al centro
                  SizedBox(height: 10.0),
                  AuthButton(
                    onPressed: (method) =>
                        _handleSignIn(context), // Adapta la firma de la función
                    brand: Method.google,
                  ),
                  AuthButton(
                    onPressed: (method) => _signInAnonymously(context),
                    brand: Method.custom,
                    text: 'Continue anonymously',
                    customImage: Image.asset('assets/anom.png'),
                  ),

                  SizedBox(height: 10.0),
                  Text(
                    'PrecioMóvil se preocupa por la seguridad de tus datos. Utilizamos las últimas tecnologías de protección para garantizar la confidencialidad y seguridad de tu información en todo momento.',
                    style: TextStyle(
                      color: const Color.fromARGB(146, 255, 255, 255),
                      fontSize: 10.0, // Tamaño de fuente reducido
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          _loading
              ? Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: SpinKitCircle(
                      color: HexColor('#E0E1DD'),
                      size: 50.0,
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}

class MenuScreen extends StatefulWidget {
  final User user;
  const MenuScreen({Key? key, required this.user}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0;
  static List<Widget> _widgetOptions = <Widget>[
    ProductListScreen(),
    CotizarScreen(),
    CalculadoraScreen(),
    ProfileScreen(), // Agrega la pantalla de perfil
    DatosScreen(), // Agrega la pantalla de datos
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Precio Movil',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: HexColor('#E0E1DD'),
          ),
        ),
        backgroundColor: HexColor('#1B263B'),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: HexColor('#E0E1DD'), // Cambia el color del ícono del Drawer
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              arrowColor: HexColor('#E0E1DD'),
              accountName: Text(
                widget.user.displayName ?? 'Anonimo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.email ?? '',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'UID: ${widget.user.uid}',
                      style: TextStyle(
                        color: Colors.indigo,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(
                  widget.user.photoURL ??
                      'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.indigo,
              ),
            ),
            SizedBox(height: 4),
            ListTile(
              leading: Icon(Icons.list, color: HexColor('#1B263B')),
              title: Text(
                'Productos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: HexColor('#1B263B')),
              title: Text(
                'Cotizar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.calculate, color: HexColor('#1B263B')),
              title: Text(
                'Calculadora',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: HexColor('#1B263B')),
              title: Text(
                'Perfil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.data_exploration, color: HexColor('#1B263B')),
              title: Text(
                'Datos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                _onItemTapped(4);
                Navigator.pop(context);
              },
            ),
            Divider(
              color: Colors.grey,
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Cerrar sesión'),
                      content:
                          Text('¿Estás seguro de que deseas cerrar sesión?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            FirebaseAuth.instance.signOut();
                            Navigator.pop(context); // Cerrar el Drawer
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                            );
                          },
                          child: Text('Cerrar sesión'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: ConvexAppBar.badge(
        {
          0: '6',
        }, // Diccionario con badges para cada ítem
        items: [
          TabItem(icon: Icons.list, title: 'Productos'),
          TabItem(icon: Icons.dashboard, title: 'Cotizar'),
          TabItem(icon: Icons.calculate, title: 'Calculadora'),
        ],
        onTap: _onItemTapped,
        backgroundColor: HexColor('#1B263B'),
        activeColor: HexColor('#E0E1DD'),
      ),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late TextEditingController _searchController;
  late Stream<QuerySnapshot> _productsStream;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _productsStream =
        FirebaseFirestore.instance.collection('products').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lista de Productos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: HexColor('#1B263B'),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddProductDialog(context);
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar productos...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchTerm = value;
                  });
                },
              ),
            ),
          ),
          StreamBuilder(
            stream: _productsStream,
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final filteredProducts = snapshot.data!.docs.where((product) {
                final title = product['title'] as String;
                return title.toLowerCase().contains(_searchTerm.toLowerCase());
              }).toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    var product = filteredProducts[index];
                    var title = product['title'];
                    var description = product['description'];
                    var price = product['price'] is double
                        ? product['price']
                        : double.parse(product['price'].toString());
                    var rating = product['rating'] is double
                        ? product['rating']
                        : double.parse(product['rating'].toString());
                    var imageUrl = product['image'];

                    return Card(
                      elevation: 4,
                      margin:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      color:
                          HexColor('#F3F4F6'), // Color de fondo personalizado
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                              : Placeholder(
                                  fallbackWidth: 60,
                                  fallbackHeight: 60,
                                ),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4.0),
                            Text(
                              description,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              'Precio: \$${price.toString()}',
                              style: TextStyle(
                                color: HexColor('#778DA9'),
                              ),
                            ),
                            SizedBox(height: 4.0),
                            Row(
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < rating.floor()
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.orange,
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                title: title,
                                description: description,
                                price: price,
                                rating: rating,
                                imageUrl: imageUrl,
                                product: product,
                              ),
                            ),
                          );
                        },
                        trailing: IconButton(
                          icon: Icon(Icons.add_shopping_cart),
                          onPressed: () {
                            _handleAddToQuote(context, product);
                          },
                        ),
                      ),
                    );
                  },
                  childCount: filteredProducts.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddProductDialog(BuildContext context) async {
    File? imageFile;
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    TextEditingController ratingController = TextEditingController();
    TextEditingController marcaController = TextEditingController();
    TextEditingController pesoController = TextEditingController();
    TextEditingController tamanoController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: Text('Agregar Producto'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            imageFile = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        height: 150.0,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: imageFile != null
                              ? Image.file(imageFile!)
                              : Icon(
                                  Icons.camera_alt,
                                  size: 50.0,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                        hintText: 'Ejemplo: Producto 1',
                      ),
                    ),
                    SizedBox(height: 8.0),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                        hintText: 'Ejemplo: Descripción del producto 1',
                      ),
                    ),
                    SizedBox(height: 8.0),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Precio',
                        border: OutlineInputBorder(),
                        hintText: 'Ejemplo: 50',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 8.0),
                    TextField(
                      controller: ratingController,
                      decoration: InputDecoration(
                        labelText: 'Rating',
                        border: OutlineInputBorder(),
                        hintText: 'Ejemplo: 4.5',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 8.0),
                    TextField(
                      controller: marcaController,
                      decoration: InputDecoration(
                        labelText: 'Marca',
                        border: OutlineInputBorder(),
                        hintText: 'Ejemplo: Marca A',
                      ),
                    ),
                    SizedBox(height: 8.0),
                    TextField(
                      controller: pesoController,
                      decoration: InputDecoration(
                        labelText: 'Peso',
                        border: OutlineInputBorder(),
                        hintText: 'Ejemplo: 100',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 8.0),
                    TextField(
                      controller: tamanoController,
                      decoration: InputDecoration(
                        labelText: 'Tamaño',
                        border: OutlineInputBorder(),
                        hintText: 'Ejemplo: 10',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (imageFile != null) {
                      try {
                        final imageUrl = await _uploadImage(imageFile!);
                        _addProduct(
                          titleController.text,
                          descriptionController.text,
                          double.parse(priceController.text),
                          double.parse(ratingController.text),
                          marcaController.text,
                          double.parse(pesoController.text),
                          double.parse(tamanoController.text),
                          imageUrl,
                        );
                      } catch (error) {
                        // Handle upload error (e.g., show a snackbar)
                      }
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> _uploadImage(File imageFile) async {
    try {
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child(
              'products/${DateTime.now().millisecondsSinceEpoch.toString()}');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  void _addProduct(
    String title,
    String description,
    double price,
    double rating,
    String marca, // Modificado
    double peso,
    double tamano,
    String imageUrl,
  ) {
    FirebaseFirestore.instance.collection('products').add({
      'title': title,
      'description': description,
      'price': price,
      'rating': rating,
      'marca': marca, // Modificado
      'peso': peso,
      'tamano': tamano,
      'image': imageUrl,
    });
  }

  Future<void> _addToQuote(
      BuildContext context, DocumentSnapshot product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        int? quantity = await showDialog<int>(
          context: context,
          builder: (BuildContext context) {
            int selectedQuantity = 1;
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text('Agregar a Cotización'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Selecciona la cantidad:'),
                      DropdownButton<int>(
                        value: selectedQuantity,
                        items: List.generate(10, (index) => index + 1)
                            .map<DropdownMenuItem<int>>(
                              (int value) => DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedQuantity = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(selectedQuantity);
                      },
                      child: Text('Aceptar'),
                    ),
                  ],
                );
              },
            );
          },
        );

        if (quantity != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'quote': FieldValue.arrayUnion([
              {
                'product': product.data(),
                'quantity': quantity,
              }
            ]),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Producto agregado a la cotización - ($quantity)',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.orange,
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text('No se ha seleccionado la cantidad',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          );
        }
      } catch (error) {
        print('Error adding product to quote: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Error al agregar producto a la cotización',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Debes iniciar sesión para agregar a la cotización',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }
  }

  void _handleAddToQuote(BuildContext context, DocumentSnapshot product) {
    _addToQuote(context, product);
  }
}

class ProductDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final double price;
  final double rating;
  final String imageUrl;
  final DocumentSnapshot product;

  const ProductDetailScreen({
    Key? key,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Producto',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: HexColor('#778DA9'),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        )
                      : Placeholder(
                          fallbackHeight: 200,
                          fallbackWidth: 200,
                        ),
                ),
              ),
            ),
            SizedBox(height: 24.0),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                          fontSize: 24.0, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12.0),
                    Text(
                      'Descripción:',
                      style: TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      description,
                      style: TextStyle(fontSize: 18.0),
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Precio:',
                          style: TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\Q${price.toString()}',
                          style: TextStyle(fontSize: 18.0),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rating:',
                          style: TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.orange, size: 20),
                            SizedBox(width: 4),
                            Text(
                              rating.toString(),
                              style: TextStyle(fontSize: 18.0),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.0),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información Adicional',
                      style: TextStyle(
                          fontSize: 20.0, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Marca:',
                          style: TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          product['marca'] ?? 'No disponible',
                          style: TextStyle(fontSize: 18.0),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Peso:',
                          style: TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          product['peso'].toString() + "kg" ?? 'No disponible',
                          style: TextStyle(fontSize: 18.0),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tamaño:',
                          style: TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          product['tamano'].toString() + "cm" ??
                              'No disponible',
                          style: TextStyle(fontSize: 18.0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 80.0),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _handleAddToQuote(context, product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  HexColor('#1B263B'), // Cambia el color de fondo del botón
            ),
            icon: Icon(
              Icons.add_shopping_cart,
              color: HexColor('#E0E1DD'),
            ), // Agrega un ícono al botón
            label: Text(
              'Agregar a la Cotización',
              style: TextStyle(
                color: Colors.white,
                fontSize:
                    17, // Cambia el color del texto del botón// Cambia el color del texto del botón
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleAddToQuote(BuildContext context, DocumentSnapshot product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      const errorMessage = 'Error al agregar producto a la cotización';
      try {
        int? quantity = await showDialog<int>(
          context: context,
          builder: (BuildContext context) {
            int selectedQuantity = 1;
            return StatefulBuilder(
              builder: (BuildContext context, setState) {
                return AlertDialog(
                  title: Text('Agregar a Cotización'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Selecciona la cantidad:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      SizedBox(height: 16.0),
                      DropdownButton<int>(
                        value: selectedQuantity,
                        items: List.generate(10, (index) => index + 1)
                            .map<DropdownMenuItem<int>>(
                              (int value) => DropdownMenuItem<int>(
                                value: value,
                                child: Text(
                                  value.toString(),
                                  style: TextStyle(fontSize: 16.0),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedQuantity = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(selectedQuantity);
                      },
                      child: Text(
                        'Aceptar',
                        style: TextStyle(
                          color: HexColor('#1B263B'),
                          fontSize: 17.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );

        if (quantity != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'quote': FieldValue.arrayUnion([
              {
                'product': product.data(),
                'quantity': quantity,
              }
            ]),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor:
                  Colors.green, // Color de fondo del SnackBar para éxito
              content: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.white), // Ícono de éxito
                  SizedBox(width: 8),
                  Text('Producto(s) agregado(s) a la cotización: $quantity',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          );
        }
      } catch (error) {
        print('Error adding product to quote: $error');
        // Consider logging the error for further analysis
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor:
                Colors.red, // Color de fondo del SnackBar para error
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white), // Ícono de error
                SizedBox(width: 8),
                Text('Error al agregar el producto a la cotización',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              Colors.orange, // Color de fondo del SnackBar para advertencia
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white), // Ícono de advertencia
              SizedBox(width: 8),
              Text('Debes iniciar sesión para agregar a la cotización',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }
  }
}

class ChartData {
  final double x;
  final double y;

  ChartData(this.x, this.y);
}

class CotizarScreen extends StatefulWidget {
  @override
  _CotizarScreenState createState() => _CotizarScreenState();
}

class _CotizarScreenState extends State<CotizarScreen> {
  late double budget;
  late List<Map<String, dynamic>> quote;
  late TextEditingController _budgetController;
  bool _isEditing = false;

  late List<sf.ChartSeries<ChartData, num>> series;

  List<ChartData> chartData = []; // Initialize chartData here

  @override
  void initState() {
    super.initState();
    _budgetController = TextEditingController();
    budget = 0;
    quote = [];
    chartData = [];
    _updateChartData(); // Llamada aquí
    series = [
      sf.LineSeries<ChartData, double>(
        dataSource: chartData,
        xValueMapper: (ChartData data, _) => data.x,
        yValueMapper: (ChartData data, _) => data.y,
        dataLabelSettings: sf.DataLabelSettings(
          isVisible: true,
        ),
      ),
    ];
    _loadUserData();
  }

  void _updateChartData() {
    setState(() {
      chartData.clear(); // Limpiar los datos existentes
      chartData.add(ChartData(0, budget)); // Punto para el presupuesto inicial
      double spentAmount = quote.fold(
          0.0,
          (total, quoteItem) =>
              total + quoteItem['product']['price'] * quoteItem['quantity']);
      chartData.add(ChartData(1, spentAmount)); // Punto para el monto gastado
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        Map<String, dynamic>? userDataMap =
            userData.data() as Map<String, dynamic>?;

        if (userData.exists) {
          if (userDataMap != null && userDataMap.containsKey('budget')) {
            setState(() {
              budget = userDataMap['budget'].toDouble();
            });
          } else {
            print('El campo "budget" no existe en el documento.');
          }

          if (userDataMap != null && userDataMap.containsKey('quote')) {
            setState(() {
              quote =
                  List<Map<String, dynamic>>.from(userDataMap['quote'] ?? []);
            });
          } else {
            print('El campo "quote" no existe en el documento.');
          }
        } else {
          print('El documento del usuario no existe en Firestore.');
        }
        _updateChartData(); // Llamada aquí
      }
    } catch (e) {
      print('Error al cargar los datos del usuario: $e');
    }
  }

  Future<void> _updateBudget(double newBudget) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'budget': newBudget});

        setState(() {
          budget = newBudget;
        });

        _updateChartData(); // Llamada aquí

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Presupuesto actualizado correctamente')),
        );
      }
    } catch (e) {
      print('Error al actualizar el presupuesto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el presupuesto')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: EdgeInsets.all(5.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Presupuesto',
                          style: TextStyle(
                              fontSize: 20.0, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 16.0),
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                              _budgetController.text = budget.toString();
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    _isEditing
                        ? Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  style: TextStyle(fontSize: 18.0),
                                  controller: _budgetController,
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Nuevo presupuesto',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.0),
                              ElevatedButton(
                                onPressed: () {
                                  double newBudget =
                                      double.tryParse(_budgetController.text) ??
                                          0;
                                  _updateBudget(newBudget);
                                  setState(() {
                                    _isEditing = false;
                                  });
                                },
                                child: Text('Guardar'),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q ${budget.toStringAsFixed(2).replaceAll('.', ',')}', // Agrega un espacio entre "Q" y el valor del presupuesto
                                style: TextStyle(fontSize: 18.0),
                              ),
                              SizedBox(height: 8.0),
                              budget -
                                          quote.fold(
                                              0.0,
                                              (total, quoteItem) =>
                                                  total +
                                                  quoteItem['product']
                                                          ['price'] *
                                                      quoteItem['quantity']) >
                                      0
                                  ? Text(
                                      'Costo restante: \Q${(budget - quote.fold(0.0, (total, quoteItem) => total + quoteItem['product']['price'] * quoteItem['quantity'])).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.green,
                                      ),
                                    )
                                  : SizedBox(), // Mostrar solo si es positivo
                            ],
                          ),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: MediaQuery.of(context).size.width * 0.05,
                columns: [
                  DataColumn(label: Text('Cantidad')),
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Precio')),
                  DataColumn(label: Text('Total')),
                ],
                rows: [
                  ...quote.map<DataRow>((quoteItem) {
                    var product = quoteItem['product'];
                    var title = product['title'];
                    var price = product['price'];
                    var quantity = quoteItem['quantity'];
                    var total = price * quantity;

                    return DataRow(cells: [
                      DataCell(Text(quantity.toString())),
                      DataCell(Text(title)),
                      DataCell(Text(
                          'Q${price.toStringAsFixed(2).replaceAll('.', ',')}')), // Formatea el precio con dos decimales y reemplaza "." por ","
                      DataCell(Text(
                          'Q${total.toStringAsFixed(2).replaceAll('.', ',')}')), // Formatea el total con dos decimales y reemplaza "." por ","
                    ]);
                  }).toList(),
                  DataRow(
                    cells: [
                      DataCell(Text('')), // Celda 1: Texto vacío
                      DataCell(Text('')), // Celda 2: Texto vacío
                      DataCell(Text('Total')), // Celda 3: Muestra "Total"
                      DataCell(
                        Text(
                          'Q${quote.fold<double>(0.0, (total, quoteItem) => total + quoteItem['product']['price'] * quoteItem['quantity']).toStringAsFixed(2).replaceAll('.', ',')}',
                          style: TextStyle(
                            color: quote.fold<double>(
                                        0.0,
                                        (total, quoteItem) =>
                                            total +
                                            quoteItem['product']['price'] *
                                                quoteItem['quantity']) >
                                    budget
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ), // Celda 4: Calcula y muestra el total, establece el color condicionalmente
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20), // Espacio entre la tabla y el gráfico
            Container(
              width: 500,
              height: 300,
              child: sf.SfCartesianChart(
                // Set chart title
                title: sf.ChartTitle(text: 'Presupuesto vs. Gasto'),
                // Define axis labels
                primaryXAxis: sf.NumericAxis(
                  title: sf.AxisTitle(text: 'Categoría'),
                ),
                primaryYAxis: sf.NumericAxis(
                  title: sf.AxisTitle(text: 'Monto (Q)'),
                ),
                // Set chart series
                series: [
                  sf.LineSeries<ChartData, double>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: sf.DataLabelSettings(
                      isVisible: true,
                    ),
                    name: 'Presupuesto',
                    color: Colors.blue,
                    width: 3,
                  ),
                  sf.BarSeries<ChartData, double>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: sf.DataLabelSettings(
                      isVisible: true,
                    ),
                    name: 'Gasto',
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class BudgetFormField extends StatelessWidget {
  final String initialValue;
  final Function(String) onSave;

  const BudgetFormField({
    required this.initialValue,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: 'Presupuesto',
        suffixIcon: IconButton(
          icon: Icon(Icons.save),
          onPressed: () {
            // Guardar el presupuesto
            onSave(initialValue);
          },
        ),
      ),
      keyboardType: TextInputType.number,
    );
  }
}

class CalculadoraScreen extends StatefulWidget {
  @override
  _CalculadoraScreenState createState() => _CalculadoraScreenState();
}

class _CalculadoraScreenState extends State<CalculadoraScreen> {
  late TextEditingController _expressionController;
  late String _expression = '';
  late String _result = '';
  List<Map<String, dynamic>> quote = [];

  @override
  void initState() {
    super.initState();
    _expressionController = TextEditingController();
    _loadQuoteData();
  }

  @override
  void dispose() {
    _expressionController.dispose();
    super.dispose();
  }

  Future<void> _loadQuoteData() async {
    try {
      // Obtener el usuario actual
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Obtener los datos de cotización desde Firestore
        DocumentSnapshot quoteSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (quoteSnapshot.exists && quoteSnapshot.data() != null) {
          // Convertir los datos de cotización a un mapa
          Map<String, dynamic>? quoteData =
              quoteSnapshot.data() as Map<String, dynamic>?;

          if (quoteData != null && quoteData.containsKey('quote')) {
            // Actualizar la lista de cotización en el estado del widget
            setState(() {
              quote = List<Map<String, dynamic>>.from(quoteData['quote']);
            });
          }
        }
      }
    } catch (e) {
      print('Error al cargar la cotización: $e');
    }
  }

  void _addToExpression(String value) {
    setState(() {
      _expression += value;
      _expressionController.text = _expression;
    });
  }

  void _calculateResult() {
    try {
      Parser p = Parser();
      Expression exp = p.parse(_expression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      setState(() {
        if (eval == eval.toInt()) {
          _result = eval.toInt().toString();
        } else {
          _result = eval.toStringAsFixed(2);
        }
        _expression = _result;
      });
    } catch (e) {
      setState(() {
        _result = 'Error';
      });
    }
  }

  void _clearExpression() {
    setState(() {
      _expression = '';
      _expressionController.text = '';
      _result = '';
    });
  }

  void _addToExpressionFromQuote(double price) {
    setState(() {
      _expression += price.toString();
      _expressionController.text = _expression;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 10),
          Container(
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: quote.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    double price = quote[index]['product']['price'];
                    _addToExpressionFromQuote(price);
                  },
                  child: Container(
                    width: 125,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quote[index]['product']['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Precio: Q${quote[index]['product']['price']}',
                            style: TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(6),
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _expression.isEmpty ? '0' : _expression,
                      style: TextStyle(
                        fontSize: 48,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    _result,
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Divider(
                  color: Colors.grey,
                ),
                Expanded(
                  flex: 3,
                  child: GridView.count(
                    crossAxisCount: 4,
                    childAspectRatio: 1.2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    padding: EdgeInsets.all(16),
                    children: [
                      _buildButton('C', Colors.red, _clearExpression),
                      _buildButton(
                          '÷', Colors.orange, () => _addToExpression('/')),
                      _buildButton(
                          '×', Colors.orange, () => _addToExpression('*')),
                      _buildButton('⌫', Colors.orange, () {
                        if (_expression.isNotEmpty) {
                          setState(() {
                            _expression = _expression.substring(
                                0, _expression.length - 1);
                            _expressionController.text = _expression;
                          });
                        }
                      }),
                      ...[7, 8, 9, 4, 5, 6, 1, 2, 3, 0]
                          .map((num) => _buildButton(
                                num.toString(),
                                Colors.black,
                                () => _addToExpression(num.toString()),
                              )),
                      _buildButton(
                          '+', Colors.orange, () => _addToExpression('+')),
                      _buildButton(
                          '-', Colors.orange, () => _addToExpression('-')),
                      _buildButton(
                          '.', Colors.black, () => _addToExpression('.')),
                      _buildButton('=', Colors.orange, _calculateResult),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, Color color, VoidCallback onPressed) {
    return MaterialButton(
      onPressed: onPressed,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 24,
          color: color == Colors.black ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class DatosScreen extends StatefulWidget {
  @override
  _DatosScreenState createState() => _DatosScreenState();
}

class _DatosScreenState extends State<DatosScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _nombre;
  late String _telefono;
  late String _direccion;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
          if (data != null) {
            setState(() {
              _nombre = data['nombre'] ?? '';
              _telefono = data['telefono'] ?? '';
              _direccion = data['direccion'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      print('Error al cargar los datos: $e');
    }
  }

  Future<void> _saveUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'nombre': _nombre,
          'telefono': _telefono,
          'direccion': _direccion,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error al guardar los datos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Datos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _nombre,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                ),
                onChanged: (value) {
                  _nombre = value;
                },
              ),
              TextFormField(
                initialValue: _telefono,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                ),
                onChanged: (value) {
                  _telefono = value;
                },
              ),
              TextFormField(
                initialValue: _direccion,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                ),
                onChanged: (value) {
                  _direccion = value;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _saveUserData,
                child: Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _displayName;
  late String _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _displayName = user.displayName ?? '';
          _photoUrl = user.photoURL ?? '';
        });
      }
    } catch (e) {
      print('Error al cargar los datos del perfil: $e');
    }
  }

  Future<void> _updateProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_displayName);
        await user.updatePhotoURL(_photoUrl);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': _displayName,
          'photoUrl': _photoUrl,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error al actualizar el perfil: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _displayName,
                decoration: InputDecoration(
                  labelText: 'Nombre de usuario',
                ),
                onChanged: (value) {
                  _displayName = value;
                },
              ),
              TextFormField(
                initialValue: _photoUrl,
                decoration: InputDecoration(
                  labelText: 'URL de la foto de perfil',
                ),
                onChanged: (value) {
                  _photoUrl = value;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Actualizar perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
