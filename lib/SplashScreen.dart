import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Aquí puedes colocar el logo de tu empresa
            Image.asset('assets/PrecioMovilTempLogo.jpeg'),
            SizedBox(height: 20),
            // Puedes agregar un texto opcional debajo del logo
            Text(
              'Bienvenido a PrecioMovil 00',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
