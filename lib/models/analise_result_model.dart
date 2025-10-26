// ============================================================================
// ARQUIVO: lib/models/analise_result_model.dart
// LOCALIZAÇÃO: uber_monitor/lib/models/
// ============================================================================

class AnaliseResultModel {
  final bool deveAceitar;
  final String motivo;
  final double valorCorrida;
  final int tempoTotal; // Em minutos
  final double valorPorMinuto;
  final int tempoRestanteCiclo;
  final double valorRestanteParaMeta;
  final double projecaoFinal;
  
  AnaliseResultModel({
    required this.deveAceitar,
    required this.motivo,
    required this.valorCorrida,
    required this.tempoTotal,
    required this.valorPorMinuto,
    required this.tempoRestanteCiclo,
    required this.valorRestanteParaMeta,
    required this.projecaoFinal,
  });
  
  @override
  String toString() {
    return 'AnaliseResult(aceitar: $deveAceitar, motivo: $motivo, valor: R\$ $valorCorrida, tempo: ${tempoTotal}min)';
  }
}