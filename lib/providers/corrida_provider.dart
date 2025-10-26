// ============================================================================
// ARQUIVO: lib/providers/corrida_provider.dart (v2.0 - SISTEMA INTELIGENTE)
// LOCALIZAÇÃO: uber_monitor/lib/providers/
// DESCRIÇÃO: Provider com sistema de análise e gestão de ciclos
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/corrida_model.dart';
import '../models/analise_result_model.dart';
import '../models/ciclo_model.dart';
import '../services/native_accessibility_service.dart';
import '../services/analise_corrida_service.dart';

class CorridaProvider with ChangeNotifier {
  // ==========================================================================
  // SERVIÇOS
  // ==========================================================================
  
  final NativeAccessibilityService _accessibilityService = NativeAccessibilityService();
  final AnaliseCorridaService _analiseService = AnaliseCorridaService();
  
  StreamSubscription<Map<String, dynamic>>? _corridaSubscription;
  
  // ==========================================================================
  // ESTADO - Permissões
  // ==========================================================================
  
  bool _permissaoConcedida = false;
  bool get permissaoConcedida => _permissaoConcedida;
  
  bool _verificandoPermissao = true;
  bool get verificandoPermissao => _verificandoPermissao;
  
  // ==========================================================================
  // ESTADO - Corrida Atual
  // ==========================================================================
  
  CorridaModel _corridaAtual = CorridaModel.vazia();
  CorridaModel get corridaAtual => _corridaAtual;
  
  final List<CorridaModel> _historicoCorridas = [];
  List<CorridaModel> get historicoCorridas => List.unmodifiable(_historicoCorridas);
  
  // ==========================================================================
  // ESTADO - Ciclo e Análise 🆕
  // ==========================================================================
  
  CicloModel? _cicloAtual;
  CicloModel? get cicloAtual => _cicloAtual;
  
  bool get temCicloAtivo => _cicloAtual != null && !_cicloAtual!.cicloTerminado;
  
  AnaliseResultModel? _ultimaAnalise;
  AnaliseResultModel? get ultimaAnalise => _ultimaAnalise;
  
  // Callback para mostrar overlay
  Function(AnaliseResultModel)? onMostrarOverlay;
  
  // Timer para atualizar UI do ciclo
  Timer? _timerCiclo;
  
  // ==========================================================================
  // ESTADO - Estatísticas
  // ==========================================================================
  
  int get totalCorridas => _historicoCorridas.length;
  
  double get totalGanhos => _historicoCorridas.fold(0.0, (sum, c) => sum + c.valor);
  
  int get corridasHoje {
    final hoje = DateTime.now();
    return _historicoCorridas.where((c) {
      return c.dataHora.year == hoje.year &&
             c.dataHora.month == hoje.month &&
             c.dataHora.day == hoje.day;
    }).length;
  }
  
  double get ganhosHoje {
    final hoje = DateTime.now();
    return _historicoCorridas.where((c) {
      return c.dataHora.year == hoje.year &&
             c.dataHora.month == hoje.month &&
             c.dataHora.day == hoje.day;
    }).fold(0.0, (sum, c) => sum + c.valor);
  }

  // Novos getters para estatísticas
  int get totalCorridasDia => corridasHoje;
  
  double get valorMedioCorridas {
    if (_historicoCorridas.isEmpty) return 0.0;
    return totalGanhos / _historicoCorridas.length;
  }
  
  // ==========================================================================
  // CONSTRUTOR
  // ==========================================================================
  
  CorridaProvider() {
    debugPrint('CorridaProvider inicializado');
    _inicializar();
  }
  
  Future<void> _inicializar() async {
    _verificandoPermissao = true;
    notifyListeners();
    
    try {
      _permissaoConcedida = await _accessibilityService.verificarPermissao();
      
      if (_permissaoConcedida) {
        _iniciarMonitoramento();
      }
    } catch (e) {
      debugPrint('Erro ao verificar permissões: $e');
      _permissaoConcedida = false;
    } finally {
      _verificandoPermissao = false;
      notifyListeners();
    }
  }
  
  // ==========================================================================
  // MÉTODOS PÚBLICOS - Permissões
  // ==========================================================================
  
  Future<void> solicitarPermissao() async {
    try {
      await _accessibilityService.solicitarPermissao();
      await Future.delayed(const Duration(seconds: 2));
      
      _permissaoConcedida = await _accessibilityService.verificarPermissao();
      
      if (_permissaoConcedida) {
        _iniciarMonitoramento();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao solicitar permissão: $e');
    }
  }
  
  Future<void> reverificarPermissao() async {
    _verificandoPermissao = true;
    notifyListeners();
    
    try {
      _permissaoConcedida = await _accessibilityService.verificarPermissao();
      
      if (_permissaoConcedida) {
        _iniciarMonitoramento();
      }
    } catch (e) {
      debugPrint('Erro ao re-verificar permissão: $e');
    } finally {
      _verificandoPermissao = false;
      notifyListeners();
    }
  }
  
  // ==========================================================================
  // MONITORAMENTO
  // ==========================================================================
  
  void _iniciarMonitoramento() {
    _corridaSubscription?.cancel();
    
    _accessibilityService.iniciarMonitoramento();
    
    _corridaSubscription = _accessibilityService.corridaStream.listen(
      _processarDadosCorrida,
      onError: (error) {
        debugPrint('Erro no stream de corridas: $error');
      },
    );
    
    debugPrint('Monitoramento ativo');
  }
  
  // ==========================================================================
  // PROCESSAMENTO DE DADOS - SUBSTITUIR NO corrida_provider.dart
  // Linha ~145
  // ==========================================================================
  
  void _processarDadosCorrida(Map<String, dynamic> dados) {
    try {
      // Extrair dados
      final valor = (dados['valor'] as num?)?.toDouble();
      final tempoMinutos = dados['tempoMinutos'] as int?;
      final tempoBusca = dados['tempoBusca'] as int?;
      final tempoViagem = dados['tempoViagem'] as int?;
      final distancia = (dados['distancia'] as num?)?.toDouble();
      final tipo = dados['tipo'] as String?;
      final status = dados['status'] as String?;
      final emAndamento = dados['emAndamento'] as bool?;
      
      // ======================================================================
      // ANÁLISE INTELIGENTE 🧠
      // ======================================================================
      
      // Verificar se é uma NOVA CORRIDA sendo oferecida
      // Precisa ter: valor >= R$ 5 E tempo total > 0
      if (valor != null && valor >= 5.0 && tempoMinutos != null && tempoMinutos > 0) {
        debugPrint('');
        debugPrint('🔔 NOVA CORRIDA DETECTADA!');
        debugPrint('   Valor: R\$ $valor');
        debugPrint('   Tempo TOTAL: ${tempoMinutos}min');
        if (tempoBusca != null && tempoViagem != null) {
          debugPrint('   • Busca: ${tempoBusca}min');
          debugPrint('   • Viagem: ${tempoViagem}min');
        }
        debugPrint('   Distância: ${distancia ?? "?"}km');
        debugPrint('   Tipo: ${tipo ?? "?"}');
        
        // FAZER ANÁLISE
        _analisarNovaCorrida(
          valor: valor,
          tempoTotal: tempoMinutos,
          tempoBusca: tempoBusca,
          tempoViagem: tempoViagem,
          distancia: distancia,
          tipo: tipo,
        );
      }
      
      // ======================================================================
      // DETECTAR ACEITAÇÃO DE CORRIDA
      // ======================================================================
      
      if (emAndamento == true && _ultimaAnalise != null) {
        debugPrint('✅ Motorista ACEITOU a corrida!');
        _registrarCorridaAceita(
          valor: valor ?? _ultimaAnalise!.valorCorrida,
          tempoMinutos: tempoMinutos ?? _ultimaAnalise!.tempoTotal,
          distancia: distancia,
          tipo: tipo,
        );
      }
      
      // ======================================================================
      // DETECTAR FINALIZAÇÃO
      // ======================================================================
      
      if (status == 'finalizada' && _corridaAtual.emAndamento) {
        debugPrint('🏁 Corrida FINALIZADA!');
        _finalizarCorrida();
      }
      
    } catch (e, stack) {
      debugPrint('❌ Erro ao processar dados: $e\n$stack');
    }
  }
  
  // ==========================================================================
  // ANÁLISE INTELIGENTE 🧠 - SUBSTITUIR
  // ==========================================================================
  
  void _analisarNovaCorrida({
    required double valor,
    required int tempoTotal,
    int? tempoBusca,
    int? tempoViagem,
    double? distancia,
    String? tipo,
  }) {
    debugPrint('');
    debugPrint('╔════════════════════════════════════════════════════════╗');
    debugPrint('║ 🧠 ANÁLISE INTELIGENTE                                ║');
    debugPrint('╚════════════════════════════════════════════════════════╝');
    debugPrint('💰 Valor da corrida: R\$ ${valor.toStringAsFixed(2)}');
    debugPrint('⏱️  Tempo TOTAL: ${tempoTotal}min');
    if (tempoBusca != null && tempoViagem != null) {
      debugPrint('   • Busca passageiro: ${tempoBusca}min');
      debugPrint('   • Duração viagem: ${tempoViagem}min');
    }
    
    // Calcular valor por minuto
    final valorPorMinuto = valor / tempoTotal;
    debugPrint('💵 Valor/minuto: R\$ ${valorPorMinuto.toStringAsFixed(2)}');
    
    // REGRA: Tempo total DEVE ser menor que o valor
    // Exemplo: 15 minutos < R$ 15,00 ✅
    // Exemplo: 20 minutos > R$ 10,00 ❌
    final tempoMenorQueValor = tempoTotal < valor;
    
    debugPrint('');
    debugPrint('📊 REGRA: Tempo < Valor?');
    debugPrint('   ${tempoTotal}min < R\$ ${valor.toStringAsFixed(2)}?');
    debugPrint('   ${tempoMenorQueValor ? "✅ SIM" : "❌ NÃO"}');
    debugPrint('');
    
    // Fazer análise com o serviço
    final analise = temCicloAtivo
        ? _analiseService.analisarCorridaComCiclo(
            valorCorrida: valor,
            tempoBusca: tempoBusca ?? (tempoTotal * 0.3).round(),
            tempoCorrida: tempoViagem ?? (tempoTotal * 0.7).round(),
            cicloAtual: _cicloAtual!,
          )
        : _analiseService.analisarCorridaSemCiclo(
            valorCorrida: valor,
            tempoBusca: tempoBusca ?? (tempoTotal * 0.3).round(),
            tempoCorrida: tempoViagem ?? (tempoTotal * 0.7).round(),
          );
    
    _ultimaAnalise = analise;
    
    // MOSTRAR OVERLAY
    debugPrint('');
    debugPrint('📱 Chamando callback do overlay...');
    if (onMostrarOverlay != null) {
      debugPrint('✅ Callback existe! Mostrando overlay...');
      onMostrarOverlay!(analise);
    } else {
      debugPrint('❌ ERRO: Callback do overlay é NULL!');
      debugPrint('   O overlay NÃO vai aparecer.');
      debugPrint('   Verifique se _configurarCallbackOverlay() foi chamado no main.dart');
    }
    
    notifyListeners();
  }
  
  // ==========================================================================
  // GESTÃO DE CICLO 🔄
  // ==========================================================================
  
  void _registrarCorridaAceita({
    required double valor,
    required int tempoMinutos,
    double? distancia,
    String? tipo,
  }) {
    debugPrint('');
    debugPrint('✅ CORRIDA ACEITA PELO MOTORISTA!');
    debugPrint('   Valor: R\$ $valor');
    debugPrint('   Tempo: ${tempoMinutos}min');
    
    // Se não tem ciclo ativo, INICIAR CICLO
    if (!temCicloAtivo) {
      _iniciarCiclo();
      debugPrint('🚀 CICLO INICIADO! Meta: R\$ 50 em 60min');
    }
    
    // Atualizar corrida atual
    _corridaAtual = CorridaModel(
      valor: valor,
      tempoMinutos: tempoMinutos,
      dataHora: DateTime.now(),
      emAndamento: true,
    );
    
    notifyListeners();
  }
  
  void _iniciarCiclo() {
    _cicloAtual = CicloModel(
      inicio: DateTime.now(),
      metaValor: 50.0,
      duracaoMinutos: 60,
    );
    
    // Timer para atualizar UI a cada segundo
    _timerCiclo?.cancel();
    _timerCiclo = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cicloAtual != null) {
        // Se ciclo terminou, cancelar timer
        if (_cicloAtual!.cicloTerminado) {
          timer.cancel();
          _finalizarCiclo();
        }
        notifyListeners(); // Atualizar cronômetro na UI
      }
    });
    
    notifyListeners();
  }
  
  void _finalizarCorrida() {
    debugPrint('🏁 CORRIDA FINALIZADA!');
    
    if (!_corridaAtual.emAndamento) return;
    
    // Adicionar ao histórico
    _historicoCorridas.insert(0, _corridaAtual);
    
    // Atualizar ciclo
    if (_cicloAtual != null) {
      _cicloAtual = _cicloAtual!.copyWith(
        valorAcumulado: _cicloAtual!.valorAcumulado + _corridaAtual.valor,
        corridas: [
          ..._cicloAtual!.corridas,
          CorridaResumida(
            valor: _corridaAtual.valor,
            tempoMinutos: _corridaAtual.tempoMinutos,
            inicio: _corridaAtual.dataHora,
          ),
        ],
      );
      
      debugPrint('💰 Ciclo: R\$ ${_cicloAtual!.valorAcumulado} / R\$ ${_cicloAtual!.metaValor}');
      
      // Verificar se atingiu meta
      if (_cicloAtual!.metaAtingida && !_corridaAtual.emAndamento) {
        debugPrint('🎉 META ATINGIDA!');
        // Aqui pode adicionar notificação ou som
      }
    }
    
    // Resetar corrida atual
    _corridaAtual = CorridaModel.vazia();
    
    notifyListeners();
  }
  
  void _finalizarCiclo() {
    debugPrint('');
    debugPrint('⏰ CICLO FINALIZADO!');
    debugPrint('   Meta: R\$ ${_cicloAtual!.metaValor}');
    debugPrint('   Atingido: R\$ ${_cicloAtual!.valorAcumulado}');
    debugPrint('   Status: ${_cicloAtual!.metaAtingida ? "✅ META ATINGIDA" : "❌ META NÃO ATINGIDA"}');
    
    _timerCiclo?.cancel();
    _cicloAtual = null;
    
    notifyListeners();
  }
  
  // ==========================================================================
  // MÉTODOS PÚBLICOS - Gestão Manual
  // ==========================================================================
  
  /// Reiniciar ciclo (caso de cancelamento)
  void reiniciarCiclo() {
    debugPrint('🔄 REINICIANDO CICLO...');
    
    _timerCiclo?.cancel();
    _cicloAtual = null;
    _corridaAtual = CorridaModel.vazia();
    _ultimaAnalise = null;
    
    notifyListeners();
  }
  
  /// Adicionar corrida manual
  void adicionarCorridaManual({
    required double valor,
    int? tempoMinutos,
  }) {
    final corrida = CorridaModel(
      valor: valor,
      tempoMinutos: tempoMinutos ?? 0,
      dataHora: DateTime.now(),
      emAndamento: false,
    );
    
    _historicoCorridas.insert(0, corrida);
    
    // Atualizar ciclo se ativo
    if (_cicloAtual != null) {
      _cicloAtual = _cicloAtual!.copyWith(
        valorAcumulado: _cicloAtual!.valorAcumulado + valor,
      );
    }
    
    notifyListeners();
  }

  /// Método para adicionar valor manual (compatibilidade)
  void adicionarValorManual(double valor) {
    adicionarCorridaManual(valor: valor);
  }
  
  /// Remover corrida do histórico
  void removerCorrida(int index) {
    if (index >= 0 && index < _historicoCorridas.length) {
      final corridaRemovida = _historicoCorridas[index];
      _historicoCorridas.removeAt(index);
      
      // Atualizar ciclo se ativo
      if (_cicloAtual != null) {
        _cicloAtual = _cicloAtual!.copyWith(
          valorAcumulado: _cicloAtual!.valorAcumulado - corridaRemovida.valor,
        );
      }
      
      notifyListeners();
    }
  }
  
  /// Limpar histórico
  void limparCorridas() {
    _historicoCorridas.clear();
    notifyListeners();
  }
  
  // ==========================================================================
  // DISPOSE
  // ==========================================================================
  
  @override
  void dispose() {
    debugPrint('Liberando recursos do provider...');
    
    _corridaSubscription?.cancel();
    _timerCiclo?.cancel();
    _accessibilityService.dispose();
    
    super.dispose();
  }
}