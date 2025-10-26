// ============================================================================
// ARQUIVO: lib/services/analise_corrida_service.dart
// LOCALIZAÇÃO: uber_monitor/lib/services/
// DESCRIÇÃO: Motor de análise inteligente de corridas
// ============================================================================

import '../models/analise_result_model.dart';
import '../models/ciclo_model.dart';

class AnaliseCorridaService {
  // ==========================================================================
  // SINGLETON
  // ==========================================================================
  static final AnaliseCorridaService _instance = AnaliseCorridaService._internal();
  factory AnaliseCorridaService() => _instance;
  AnaliseCorridaService._internal();

  // ==========================================================================
  // CONSTANTES DE ANÁLISE
  // ==========================================================================
  
  /// Valor mínimo aceitável por minuto (R$ 0.83 = R$50/60min)
  static const double valorMinimoPorMinuto = 0.83;
  
  /// Margem de segurança (10% a mais no tempo)
  static const double margemSegurancaTempo = 1.1;
  
  /// Valor mínimo absoluto para aceitar (R$ 8.00)
  static const double valorMinimoAbsoluto = 8.0;

  // ==========================================================================
  // ANÁLISE PRINCIPAL - SEM CICLO ATIVO
  // ==========================================================================
  
  /// Analisa se deve aceitar uma corrida ANTES de iniciar o ciclo
  AnaliseResultModel analisarCorridaSemCiclo({
    required double valorCorrida,
    required int tempoBusca,
    required int tempoCorrida,
  }) {
    final tempoTotal = tempoBusca + tempoCorrida;
    final valorPorMinuto = valorCorrida / tempoTotal;
    
    _log('');
    _log('╔════════════════════════════════════════════════════════╗');
    _log('║ 🧠 ANÁLISE INTELIGENTE - SEM CICLO ATIVO              ║');
    _log('╚════════════════════════════════════════════════════════╝');
    _log('💰 Valor da corrida: R\$ ${valorCorrida.toStringAsFixed(2)}');
    _log('⏱️  Tempo de busca: ${tempoBusca}min');
    _log('🚗 Tempo da corrida: ${tempoCorrida}min');
    _log('📊 Tempo total: ${tempoTotal}min');
    _log('💵 Valor/minuto: R\$ ${valorPorMinuto.toStringAsFixed(2)}');
    _log('🎯 Mínimo exigido: R\$ ${valorMinimoPorMinuto.toStringAsFixed(2)}/min');
    
    // ========================================================================
    // LÓGICA 1: Valor por minuto deve ser >= R$ 0.83
    // ========================================================================
    if (valorPorMinuto >= valorMinimoPorMinuto) {
      _log('✅ ACEITAR: Valor/minuto está ACIMA do mínimo');
      _log('');
      
      return AnaliseResultModel(
        deveAceitar: true,
        motivo: 'Valor/minuto ÓTIMO (R\$ ${valorPorMinuto.toStringAsFixed(2)}/min)',
        valorCorrida: valorCorrida,
        tempoTotal: tempoTotal,
        valorPorMinuto: valorPorMinuto,
        tempoRestanteCiclo: 60, // Ciclo ainda não iniciado
        valorRestanteParaMeta: 50.0,
        projecaoFinal: (valorPorMinuto * 60), // Projeção se mantiver o ritmo
      );
    }
    
    // ========================================================================
    // LÓGICA 2: Valor mínimo absoluto (mesmo que valor/min seja baixo)
    // ========================================================================
    if (valorCorrida >= valorMinimoAbsoluto && tempoTotal <= 15) {
      _log('⚠️  ACEITAR: Valor bom (R\$ ${valorCorrida.toStringAsFixed(2)}) e tempo curto');
      _log('');
      
      return AnaliseResultModel(
        deveAceitar: true,
        motivo: 'Valor BOM e tempo CURTO (${tempoTotal}min)',
        valorCorrida: valorCorrida,
        tempoTotal: tempoTotal,
        valorPorMinuto: valorPorMinuto,
        tempoRestanteCiclo: 60,
        valorRestanteParaMeta: 50.0,
        projecaoFinal: (valorPorMinuto * 60),
      );
    }
    
    // ========================================================================
    // REJEITAR
    // ========================================================================
    _log('❌ REJEITAR: Valor/minuto ABAIXO do mínimo');
    _log('');
    
    return AnaliseResultModel(
      deveAceitar: false,
      motivo: 'Valor/minuto BAIXO (R\$ ${valorPorMinuto.toStringAsFixed(2)}/min)',
      valorCorrida: valorCorrida,
      tempoTotal: tempoTotal,
      valorPorMinuto: valorPorMinuto,
      tempoRestanteCiclo: 60,
      valorRestanteParaMeta: 50.0,
      projecaoFinal: 0.0,
    );
  }

  // ==========================================================================
  // ANÁLISE AVANÇADA - COM CICLO ATIVO
  // ==========================================================================
  
  /// Analisa se deve aceitar uma corrida DURANTE o ciclo ativo
  AnaliseResultModel analisarCorridaComCiclo({
    required double valorCorrida,
    required int tempoBusca,
    required int tempoCorrida,
    required CicloModel cicloAtual,
  }) {
    final tempoTotal = (tempoBusca + tempoCorrida) * margemSegurancaTempo;
    final valorPorMinuto = valorCorrida / tempoTotal;
    
    // Calcular quanto falta para a meta
    final valorRestante = cicloAtual.valorRestante;
    final tempoRestante = cicloAtual.minutosRestantes;
    
    // Calcular valor/minuto necessário para atingir a meta
    final valorPorMinutoNecessario = tempoRestante > 0
        ? valorRestante / tempoRestante
        : 999.0; // Valor impossível se tempo esgotado
    
    _log('');
    _log('╔════════════════════════════════════════════════════════╗');
    _log('║ 🧠 ANÁLISE INTELIGENTE - CICLO ATIVO                  ║');
    _log('╚════════════════════════════════════════════════════════╝');
    _log('📊 SITUAÇÃO ATUAL DO CICLO:');
    _log('   💰 Meta: R\$ ${cicloAtual.metaValor.toStringAsFixed(2)}');
    _log('   ✅ Acumulado: R\$ ${cicloAtual.valorAcumulado.toStringAsFixed(2)}');
    _log('   📉 Restante: R\$ ${valorRestante.toStringAsFixed(2)}');
    _log('   ⏱️  Tempo restante: ${tempoRestante}min');
    _log('   🎯 Necessário: R\$ ${valorPorMinutoNecessario.toStringAsFixed(2)}/min');
    _log('');
    _log('📋 NOVA CORRIDA OFERECIDA:');
    _log('   💵 Valor: R\$ ${valorCorrida.toStringAsFixed(2)}');
    _log('   ⏱️  Tempo total: ${tempoTotal.toInt()}min');
    _log('   💰 Valor/min: R\$ ${valorPorMinuto.toStringAsFixed(2)}/min');
    
    // ========================================================================
    // LÓGICA 1: Tempo insuficiente para completar a corrida
    // ========================================================================
    if (tempoTotal > tempoRestante) {
      _log('❌ REJEITAR: Tempo insuficiente no ciclo');
      _log('');
      
      return AnaliseResultModel(
        deveAceitar: false,
        motivo: 'Tempo INSUFICIENTE (precisa ${tempoTotal.toInt()}min, tem ${tempoRestante}min)',
        valorCorrida: valorCorrida,
        tempoTotal: tempoTotal.toInt(),
        valorPorMinuto: valorPorMinuto,
        tempoRestanteCiclo: tempoRestante,
        valorRestanteParaMeta: valorRestante,
        projecaoFinal: cicloAtual.valorAcumulado,
      );
    }
    
    // ========================================================================
    // LÓGICA 2: Meta já atingida - aceitar apenas se valor/min for bom
    // ========================================================================
    if (cicloAtual.metaAtingida) {
      if (valorPorMinuto >= valorMinimoPorMinuto) {
        _log('✅ ACEITAR: Meta atingida + valor/min BOM (BÔNUS)');
        _log('');
        
        return AnaliseResultModel(
          deveAceitar: true,
          motivo: 'Meta ATINGIDA + valor/min ÓTIMO (BÔNUS)',
          valorCorrida: valorCorrida,
          tempoTotal: tempoTotal.toInt(),
          valorPorMinuto: valorPorMinuto,
          tempoRestanteCiclo: tempoRestante,
          valorRestanteParaMeta: 0.0,
          projecaoFinal: cicloAtual.valorAcumulado + valorCorrida,
        );
      } else {
        _log('⚠️  REJEITAR: Meta atingida, mas valor/min BAIXO');
        _log('');
        
        return AnaliseResultModel(
          deveAceitar: false,
          motivo: 'Meta ATINGIDA, valor/min baixo (pode descansar)',
          valorCorrida: valorCorrida,
          tempoTotal: tempoTotal.toInt(),
          valorPorMinuto: valorPorMinuto,
          tempoRestanteCiclo: tempoRestante,
          valorRestanteParaMeta: 0.0,
          projecaoFinal: cicloAtual.valorAcumulado,
        );
      }
    }
    
    // ========================================================================
    // LÓGICA 3: Corrida ajuda a atingir a meta
    // ========================================================================
    final projecaoComCorrida = cicloAtual.valorAcumulado + valorCorrida;
    final ficaProximoDaMeta = (cicloAtual.metaValor - projecaoComCorrida) <= 10.0;
    
    if (valorPorMinuto >= valorPorMinutoNecessario * 0.8) { // 80% do necessário
      _log('✅ ACEITAR: Valor/min ${valorPorMinuto >= valorPorMinutoNecessario ? "ATENDE" : "PRÓXIMO"} ao necessário');
      _log('   📈 Projeção após corrida: R\$ ${projecaoComCorrida.toStringAsFixed(2)}');
      _log('');
      
      return AnaliseResultModel(
        deveAceitar: true,
        motivo: ficaProximoDaMeta
            ? 'ACEITAR! Vai ATINGIR a meta'
            : 'Valor/min AJUDA a atingir meta',
        valorCorrida: valorCorrida,
        tempoTotal: tempoTotal.toInt(),
        valorPorMinuto: valorPorMinuto,
        tempoRestanteCiclo: tempoRestante,
        valorRestanteParaMeta: valorRestante,
        projecaoFinal: projecaoComCorrida,
      );
    }
    
    // ========================================================================
    // LÓGICA 4: Situação crítica - aceitar qualquer corrida razoável
    // ========================================================================
    if (tempoRestante <= 20 && valorRestante > 20) {
      // Tempo acabando e ainda falta muito
      if (valorCorrida >= 10.0) {
        _log('⚠️  ACEITAR: Situação CRÍTICA, qualquer valor ajuda');
        _log('');
        
        return AnaliseResultModel(
          deveAceitar: true,
          motivo: 'Situação CRÍTICA - aceitar para minimizar prejuízo',
          valorCorrida: valorCorrida,
          tempoTotal: tempoTotal.toInt(),
          valorPorMinuto: valorPorMinuto,
          tempoRestanteCiclo: tempoRestante,
          valorRestanteParaMeta: valorRestante,
          projecaoFinal: projecaoComCorrida,
        );
      }
    }
    
    // ========================================================================
    // REJEITAR
    // ========================================================================
    _log('❌ REJEITAR: Valor/min NÃO ajuda a atingir meta');
    _log('');
    
    return AnaliseResultModel(
      deveAceitar: false,
      motivo: 'Valor/min BAIXO demais (R\$ ${valorPorMinuto.toStringAsFixed(2)} vs R\$ ${valorPorMinutoNecessario.toStringAsFixed(2)})',
      valorCorrida: valorCorrida,
      tempoTotal: tempoTotal.toInt(),
      valorPorMinuto: valorPorMinuto,
      tempoRestanteCiclo: tempoRestante,
      valorRestanteParaMeta: valorRestante,
      projecaoFinal: cicloAtual.valorAcumulado,
    );
  }

  // ==========================================================================
  // MÉTODO DE LOGGING
  // ==========================================================================
  
  void _log(String message) {
    // Em produção, você pode usar um sistema de logging apropriado
    // Por enquanto, mantemos o print para debug
    // TODO: Implementar sistema de logging apropriado
    // ignore: avoid_print
    print(message);
  }
}