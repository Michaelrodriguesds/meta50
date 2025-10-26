// ============================================================================
// ARQUIVO: lib/models/corrida_model.dart
// DESCRIÇÃO: Modelo de dados para representar uma corrida do Uber Driver
// ============================================================================

/// Classe que representa os dados de uma corrida individual
/// Contém informações como valor, tempo, data/hora e status
class CorridaModel {
  /// Valor total da corrida em reais (R$)
  final double valor;
  
  /// Duração da corrida em minutos
  final int tempoMinutos;
  
  /// Data e hora em que a corrida foi detectada/iniciada
  final DateTime dataHora;
  
  /// Indica se a corrida está em andamento (true) ou finalizada (false)
  final bool emAndamento;
  
  /// Construtor principal da classe
  /// Requer todos os parâmetros para criar uma instância válida
  CorridaModel({
    required this.valor,
    required this.tempoMinutos,
    required this.dataHora,
    required this.emAndamento,
  });
  
  /// Factory constructor para criar uma corrida vazia/inicial
  /// Usado quando ainda não há dados capturados
  factory CorridaModel.vazia() {
    return CorridaModel(
      valor: 0.0,
      tempoMinutos: 0,
      dataHora: DateTime.now(),
      emAndamento: false,
    );
  }
  
  /// Converte o objeto para um Map<String, dynamic>
  /// Útil para serialização (salvar em banco de dados ou SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'valor': valor,
      'tempoMinutos': tempoMinutos,
      'dataHora': dataHora.toIso8601String(),
      'emAndamento': emAndamento,
    };
  }
  
  /// Factory constructor para criar um objeto a partir de um Map
  /// Útil para desserialização (recuperar dados salvos)
  factory CorridaModel.fromMap(Map<String, dynamic> map) {
    return CorridaModel(
      valor: (map['valor'] ?? 0.0).toDouble(),
      tempoMinutos: map['tempoMinutos'] ?? 0,
      dataHora: map['dataHora'] != null 
          ? DateTime.parse(map['dataHora']) 
          : DateTime.now(),
      emAndamento: map['emAndamento'] ?? false,
    );
  }
  
  /// Cria uma cópia do objeto com modificações específicas
  /// Permite alterar apenas os campos necessários mantendo os demais
  CorridaModel copyWith({
    double? valor,
    int? tempoMinutos,
    DateTime? dataHora,
    bool? emAndamento,
  }) {
    return CorridaModel(
      valor: valor ?? this.valor,
      tempoMinutos: tempoMinutos ?? this.tempoMinutos,
      dataHora: dataHora ?? this.dataHora,
      emAndamento: emAndamento ?? this.emAndamento,
    );
  }
  
  /// Override do método toString para facilitar debug
  @override
  String toString() {
    return 'CorridaModel(valor: R\$ $valor, tempo: $tempoMinutos min, '
           'emAndamento: $emAndamento, dataHora: $dataHora)';
  }
  
  /// Override do operador == para comparação de objetos
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is CorridaModel &&
        other.valor == valor &&
        other.tempoMinutos == tempoMinutos &&
        other.dataHora == dataHora &&
        other.emAndamento == emAndamento;
  }
  
  /// Override do hashCode necessário quando se sobrescreve ==
  @override
  int get hashCode {
    return valor.hashCode ^
        tempoMinutos.hashCode ^
        dataHora.hashCode ^
        emAndamento.hashCode;
  }
}