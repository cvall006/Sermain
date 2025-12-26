class Sermon {
  String titulo;
  String tema; // Ej: "Fe", "Familia"
  DateTime fecha;
  String contenidoJson; // El texto del editor

  Sermon({
    required this.titulo,
    required this.tema,
    required this.fecha,
    required this.contenidoJson,
  });
}