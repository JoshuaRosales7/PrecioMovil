import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Aquí puedes personalizar el tema de tu aplicación si lo deseas
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(), // Establece SplashScreen como la pantalla de inicio
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _visible = true; // Variable para controlar la visibilidad del logo
  late Timer _timer; // Temporizador para controlar el parpadeo del logo

  @override
  void initState() {
    super.initState();
    // Inicia un temporizador para cambiar la visibilidad del logo cada 0.5 segundos
    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        _visible = !_visible; // Cambia la visibilidad del logo
      });
    });
    // Simula una carga de 3 segundos antes de navegar a la siguiente pantalla
    Future.delayed(Duration(seconds: 3), () {
      // Navega a la siguiente pantalla (en este ejemplo, se navega a la pantalla del menú)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MenuScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Detiene el temporizador al salir del widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Puedes personalizar el contenido de tu splash screen aquí
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
              height: MediaQuery.of(context).size.height *
                  0.3), // Espacio arriba para centrar el logo
          // Muestra el logo con visibilidad alternativa para parpadear
          AnimatedOpacity(
            opacity: _visible ? 1.0 : 0.0,
            duration: Duration(milliseconds: 500),
            child: Image.asset(
              'assets/logo.png', // Ruta de la imagen de tu logo
              width: 300, // Ancho de la imagen (ajusta según sea necesario)
            ),
          ),
          // Utilizamos un Expanded para centrar el texto y la animación en la parte inferior
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Agrega el texto "Cargando" con una animación moderna
                SpinKitRing(
                  color: Colors.blue, // Color de la animación
                  lineWidth: 2, // Grosor de la línea
                  size: 30, // Tamaño de la animación
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    ProductListScreen(),
    CalculatorScreen(),
    DataVisualizationScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.blue,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Productos',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Calculadora',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart),
            label: 'Gráficos',
            backgroundColor: Colors.black,
          ),
        ],
      ),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    final String productsJson =
        await rootBundle.loadString('assets/products.json');
    final List<dynamic> productsData = json.decode(productsJson);
    setState(() {
      _products = productsData
          .map((productJson) => Product.fromJson(productJson))
          .toList();
      _filteredProducts = _products;
    });
  }

  void filterProducts(String query) {
    setState(() {
      _filteredProducts = _products
          .where((product) =>
              product.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar Producto',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: filterProducts,
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).orientation == Orientation.portrait
                        ? 2
                        : 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3 / 4,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          product: _filteredProducts[index],
                        ),
                      ),
                    );
                  },
                  child: ProductCard(product: _filteredProducts[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(8),
      height: 300, // Altura fija para la tarjeta del producto
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: AssetImage(product.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(
              height:
                  12), // Separación entre la imagen y la información del producto
          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título del producto
                Text(
                  product.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                    height: 4), // Separación entre el título y la descripción
                // Descripción del producto
                Text(
                  product.description,
                  style: TextStyle(fontSize: 11),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                    height: 4), // Separación entre la descripción y el precio
                // Precio del producto
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(
                    height: 4), // Separación entre el precio y la calificación
                // Calificación del producto (estrellas)
                Row(
                  children: List.generate(
                    product.rating.round(),
                    (index) => Icon(Icons.star, color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Product {
  final int id;
  final String title;
  final String image;
  final String description;
  final double price;
  final double rating;
  final int timesSold;
  final String category;
  final String brand;
  final String color;
  final String size;
  final String material;
  final int discount;

  Product({
    required this.id,
    required this.title,
    required this.image,
    required this.description,
    required this.price,
    required this.rating,
    required this.timesSold,
    required this.category,
    required this.brand,
    required this.color,
    required this.size,
    required this.material,
    required this.discount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      description: json['description'],
      price: json['price'].toDouble(),
      rating: json['rating'].toDouble(),
      timesSold: json['timesSold'],
      category: json['category'],
      brand: json['brand'],
      color: json['color'],
      size: json['size'],
      material: json['material'],
      discount: json['discount'],
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Producto'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contenido de los detalles del producto
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(
                        product.image,
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Título del producto
                Text(
                  product.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                // Descripción del producto
                Text(
                  product.description,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                // Precio del producto
                Text(
                  'Precio: \$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                // Calificación del producto (estrellas)
                Row(
                  children: List.generate(
                    product.rating.round(),
                    (index) => Icon(Icons.star, color: Colors.amber),
                  ),
                ),
                SizedBox(height: 20),
                // Otras características del producto
                Text(
                  'Características:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                // Lista de características
                buildFeatureSection(
                    'Categoría', Icons.category, product.category),
                buildFeatureSection(
                    'Marca', Icons.branding_watermark, product.brand),
                buildFeatureSection('Color', Icons.color_lens, product.color),
                buildFeatureSection('Tamaño', Icons.straighten, product.size),
                buildFeatureSection(
                    'Material', Icons.texture, product.material),
                buildFeatureSection(
                    'Descuento', Icons.local_offer, '${product.discount}%'),
              ],
            ),
          ),
          // Botón de compra fijo en la parte inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Acción al presionar el botón de compra
                  },
                  child: Text('Comprar'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método para construir la sección de características con un icono
  Widget buildFeatureSection(String title, IconData icon, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CalculatorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Calculadora(),
    );
  }
}

class Calculadora extends StatefulWidget {
  @override
  _CalculadoraState createState() => _CalculadoraState();
}

class _CalculadoraState extends State<Calculadora> {
  String displayText = '';
  Parser parser = Parser();
  late Expression expression;

  void addToDisplay(String value) {
    setState(() {
      displayText += value;
    });
  }

  void clearDisplay() {
    setState(() {
      displayText = '';
    });
  }

  void calculateResult() {
    setState(() {
      try {
        expression = parser.parse(displayText);
        ContextModel contextModel = ContextModel();
        double result = expression.evaluate(EvaluationType.REAL, contextModel);
        if (result % 1 == 0) {
          displayText = result.toInt().toString();
        } else {
          displayText = result.toStringAsFixed(2);
        }
      } catch (e) {
        displayText = 'Error';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Calculadora Básica'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(15.0),
                alignment: Alignment.bottomRight,
                child: Text(
                  displayText,
                  style: TextStyle(fontSize: 50.0),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: GridView.count(
                crossAxisCount: 4,
                children: [
                  buildButton('7'),
                  buildButton('8'),
                  buildButton('9'),
                  buildButton('+'),
                  buildButton('4'),
                  buildButton('5'),
                  buildButton('6'),
                  buildButton('-'),
                  buildButton('1'),
                  buildButton('2'),
                  buildButton('3'),
                  buildButton('*'),
                  buildButton('C', color: Colors.red),
                  buildButton('0'),
                  buildButton('=', color: Colors.green),
                  buildButton('/', color: Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton(String text, {Color color = Colors.black}) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () {
          if (text == 'C') {
            clearDisplay();
          } else if (text == '=') {
            calculateResult();
          } else {
            addToDisplay(text);
          }
        },
        style: ElevatedButton.styleFrom(
          primary: color,
          minimumSize: Size(
            MediaQuery.of(context).size.width / 4 - 20,
            MediaQuery.of(context).size.width / 4 - 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 24.0, color: Colors.white),
        ),
      ),
    );
  }
}

class DataVisualizationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Graficar Datos'),
    );
  }
}
