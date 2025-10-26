// ============================================================================
// ARQUIVO: lib/models/ciclo_model.dart
// LOCALIZAÇÃO: uber_monitor/lib/models/
// ============================================================================

class CicloModel {
  final DateTime inicio;
  final double metaValor; // R$ 50.00
  final int duracaoMinutos; // 60 minutos
  final double valorAcumulado;
  final List<CorridaResumida> corridas;
  
  CicloModel({
    required this.inicio,
    this.metaValor = 50.0,
    this.duracaoMinutos = 60,
    this.valorAcumulado = 0.0,
    this.corridas = const [],
  });
  
  /// Tempo decorrido desde o início do ciclo
  Duration get tempoDecorrido => DateTime.now().difference(inicio);
  
  /// Minutos decorridos
  int get minutosDecorridos => tempoDecorrido.inMinutes;
  
  /// Minutos restantes no ciclo
  int get minutosRestantes => (duracaoMinutos - minutosDecorridos).clamp(0, duracaoMinutos);
  
  /// Valor restante para atingir a meta
  double get valorRestante => (metaValor - valorAcumulado).clamp(0.0, metaValor);
  
  /// Percentual de progresso (0-100)
  double get percentualProgresso => ((valorAcumulado / metaValor) * 100).clamp(0.0, 100.0);
  
  /// Verifica se o ciclo terminou
  bool get cicloTerminado => minutosDecorridos >= duracaoMinutos;
  
  /// Verifica se a meta foi atingida
  bool get metaAtingida => valorAcumulado >= metaValor;
  
  /// Projeção de ganhos no final do ciclo (baseado no ritmo atual)
  double get projecaoFinal {
    if (minutosDecorridos == 0) return 0.0;
    final ganhoPorMinuto = valorAcumulado / minutosDecorridos;
    return ganhoPorMinuto * duracaoMinutos;
  }
  
  CicloModel copyWith({
    DateTime? inicio,
    double? metaValor,
    int? duracaoMinutos,
    double? valorAcumulado,
    List<CorridaResumida>? corridas,
  }) {
    return CicloModel(
      inicio: inicio ?? this.inicio,
      metaValor: metaValor ?? this.metaValor,
      duracaoMinutos: duracaoMinutos ?? this.duracaoMinutos,
      valorAcumulado: valorAcumulado ?? this.valorAcumulado,
      corridas: corridas ?? this.corridas,
    );
  }
  
  @override
  String toString() {
    return 'Ciclo(inicio: $inicio, meta: R\$ $metaValor, acumulado: R\$ $valorAcumulado, restante: ${minutosRestantes}min)';
  }
}

/// Resumo simplificado de corrida para o ciclo
class CorridaResumida {
  final double valor;
  final int tempoMinutos;
  final DateTime inicio;
  
  CorridaResumida({
    required this.valor,
    required this.tempoMinutos,
    required this.inicio,
  });
}