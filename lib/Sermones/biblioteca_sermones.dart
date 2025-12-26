import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BibliotecaSermones extends StatelessWidget {
  const BibliotecaSermones({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Biblioteca de Sermones'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        // Escuchamos la caja de Hive en tiempo real
        valueListenable: Hive.box('mis_sermones').listenable(),
        builder: (context, Box box, _) {
          if (box.values.isEmpty) {
            return const Center(
              child: Text("Aún no tienes sermones guardados.\n¡Empieza a escribir el primero!"),
            );
          }

          return ListView.builder(
            itemCount: box.values.length,
            itemBuilder: (context, index) {
              final sermon = box.getAt(index);
              final String titulo = sermon['titulo'] ?? 'Sin título';
              final String tema = sermon['tema'] ?? 'General';
              final String fecha = sermon['fecha'].toString().substring(0, 10);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.book, color: Colors.white),
                  ),
                  title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("$tema • $fecha"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Aquí enviaremos los datos de vuelta al editor
                    _cargarSermon(context, sermon);
                  },
                  onLongPress: () {
                    // Opción para borrar manteniendo presionado
                    _confirmarEliminacion(context, box, index, titulo);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _cargarSermon(BuildContext context, dynamic sermon) {
    // Por ahora solo avisamos, en el siguiente paso conectaremos el cargado real
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Cargando: ${sermon['titulo']}")),
    );
    Navigator.pop(context, sermon); 
  }

  void _confirmarEliminacion(BuildContext context, Box box, int index, String titulo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Sermón"),
        content: Text("¿Estás seguro de que quieres borrar '$titulo'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              box.deleteAt(index);
              Navigator.pop(context);
            }, 
            child: const Text("Eliminar", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}