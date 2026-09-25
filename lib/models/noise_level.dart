enum NoiseLevel {
  baixo(0.02, 'Baixo'),
  medio(0.08, 'Médio'),
  alto(0.20, 'Alto');

  const NoiseLevel(this.density, this.label);

  /// Fração de pixels afetados pelo ruído (0..1).
  final double density;
  final String label;
}
