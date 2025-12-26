import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'Editor/editor_sermon.dart';

void main() async {
  // 1. Inicialización básica
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar base de datos
  await Hive.initFlutter();
  await Hive.openBox('mis_sermones');

  // 3. TRUCO DE ESTABILIDAD: Esperar a que la ventana de Windows esté lista
  await Future.delayed(const Duration(milliseconds: 500));

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PantallaEditorSermon(),
  ));
}