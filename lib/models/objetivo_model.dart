// ============================================================================
// ARQUIVO: lib/models/objetivo_model.dart (CORRIGIDO)
// DESCRIÇÃO: Modelo para gerenciar objetivos/metas do motorista
// ============================================================================

/// Classe que representa os objetivos e metas diárias do motorista
/// Gerencia tempo disponível, valor atual conquistado e meta de valor
class ObjetivoModel {
  /// Tempo total disponível para trabalho no dia (em minutos)
  /// Exemplo: 480 minutos = 8 horas
  final int tempoDisponivel;
  
  /// Valor total já conquistado até o momento (R$)
  /// Soma de todas as corridas finalizadas no ciclo atual
  final double valorAtual;
  
  /// Meta de valor a ser alcançada no dia (R$)
  /// Objetivo financeiro definido pelo motorista
  final double metaValor;
  
  /// Data e hora de início do ciclo de objetivos
  /// Usado para controlar quando o ciclo começou
  final DateTime dataInicio;
  
  /// Construtor principal da classe
  /// Todos os parâmetros são obrigatórios
  ObjetivoModel({
    required this.tempoDisponivel,
    required this.valorAtual,
    required this.metaValor,
    required this.dataInicio,
  });
  
  /// Calcula o percentual de conclusão da meta
  /// Retorna um valor entre 0 e 100
  /// Exemplo: se metaValor = 200 e valorAtual = 150, retorna 75.0
  double get percentualConcluido {
    if (metaValor == 0) return 0;
    return (valorAtual / metaValor * 100).clamp(0.0, 100.0);
  }
  
  /// Calcula quanto ainda falta para atingir a meta
  /// Retorna sempre um valor >= 0 (não pode ser negativo)
  double get valorRestante {
    final restante = metaValor - valorAtual;
    return restante > 0 ? restante : 0.0;
  }
  
  /// Verifica se a meta já foi atingida ou superada
  /// true = meta atingida, false = ainda não atingiu
  bool get metaAtingida => valorAtual >= metaValor;
  
  /// Converte tempo disponível para formato de horas e minutos
  /// Retorna uma string formatada (ex: "8h 30min")
  String get tempoDisponivelFormatado {
    final horas = tempoDisponivel ~/ 60;
    final minutos = tempoDisponivel % 60;
    
    if (minutos == 0) {
      return '${horas}h';
    }
    return '${horas}h ${minutos}min';
  }
  
  /// Calcula quantos dias se passaram desde o início do ciclo
  int get diasDecorridos {
    final agora = DateTime.now();
    final diferenca = agora.difference(dataInicio);
    return diferenca.inDays;
  }
  
  /// Verifica se o objetivo é do dia atual
  bool get ehObjetivoDeHoje {
    final agora = DateTime.now();
    return dataInicio.year == agora.year &&
           dataInicio.month == agora.month &&
           dataInicio.day == agora.day;
  }
  
  /// Converte o objeto para Map para serialização
  Map<String, dynamic> toMap() {
    return {
      'tempoDisponivel': tempoDisponivel,
      'valorAtual': valorAtual,
      'metaValor': metaValor,
      'dataInicio': dataInicio.toIso8601String(),
    };
  }
  
  /// Factory constructor para criar objeto a partir de Map
  factory ObjetivoModel.fromMap(Map<String, dynamic> map) {
    return ObjetivoModel(
      tempoDisponivel: map['tempoDisponivel'] ?? 480,
      valorAtual: (map['valorAtual'] ?? 0.0).toDouble(),
      metaValor: (map['metaValor'] ?? 200.0).toDouble(),
      dataInicio: map['dataInicio'] != null
          ? DateTime.parse(map['dataInicio'])
          : DateTime.now(),
    );
  }
  
  /// Cria uma cópia com modificações específicas
  ObjetivoModel copyWith({
    int? tempoDisponivel,
    double? valorAtual,
    double? metaValor,
    DateTime? dataInicio,
  }) {
    return ObjetivoModel(
      tempoDisponivel: tempoDisponivel ?? this.tempoDisponivel,
      valorAtual: valorAtual ?? this.valorAtual,
      metaValor: metaValor ?? this.metaValor,
      dataInicio: dataInicio ?? this.dataInicio,
    );
  }
  
  /// Override do toString para facilitar debug
  @override
  String toString() {
    return 'ObjetivoModel('
           'tempo: $tempoDisponivelFormatado, '
           'valorAtual: R\$ $valorAtual, '
           'metaValor: R\$ $metaValor, '
           'percentual: ${percentualConcluido.toStringAsFixed(1)}%)';
  }
  
  /// Override do operador == para comparação
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ObjetivoModel &&
        other.tempoDisponivel == tempoDisponivel &&
        other.valorAtual == valorAtual &&
        other.metaValor == metaValor &&
        other.dataInicio == dataInicio;
  }
  
  /// Override do hashCode
  @override
  int get hashCode {
    return tempoDisponivel.hashCode ^
        valorAtual.hashCode ^
        metaValor.hashCode ^
        dataInicio.hashCode;
  }
}