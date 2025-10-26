// ============================================================================
// ARQUIVO: lib/services/native_accessibility_service.dart
// LOCALIZAÇÃO: uber_monitor/lib/services/
// DESCRIÇÃO: Cliente Dart para comunicação com Accessibility Service NATIVO
// ============================================================================

import 'dart:async';
import 'package:flutter/services.dart';

class NativeAccessibilityService {
  // ==========================================================================
  // SINGLETON PATTERN
  // ==========================================================================
  static final NativeAccessibilityService _instance = 
      NativeAccessibilityService._internal();
  
  factory NativeAccessibilityService() => _instance;
  NativeAccessibilityService._internal();

  // ==========================================================================
  // CONSTANTES
  // ==========================================================================
  static const String _methodChannelName = 'com.example.uber_monitor/accessibility';
  static const String _eventChannelName = 'com.example.uber_monitor/accessibility_events';

  // ==========================================================================
  // CHANNELS
  // ==========================================================================
  final MethodChannel _methodChannel = const MethodChannel(_methodChannelName);
  final EventChannel _eventChannel = const EventChannel(_eventChannelName);

  // ==========================================================================
  // STREAMS E CONTROLLERS
  // ==========================================================================
  final _corridaController = StreamController<Map<String, dynamic>>.broadcast();
  
  /// Stream pública para escutar eventos de corridas
  Stream<Map<String, dynamic>> get corridaStream => _corridaController.stream;

  StreamSubscription? _eventSubscription;
  bool _isMonitoring = false;

  // Contadores para estatísticas
  int _eventCount = 0;
  int _corridasDetectadas = 0;

  // ==========================================================================
  // MÉTODOS PÚBLICOS
  // ==========================================================================

  /// Verifica se a permissão de acessibilidade está concedida
  Future<bool> verificarPermissao() async {
    try {
      final result = await _methodChannel.invokeMethod('checkPermission');
      
      print('╔════════════════════════════════════════════════════════╗');
      print('║ 🔐 VERIFICAÇÃO DE PERMISSÃO (NATIVO)                   ║');
      print('║ Status: ${result ? "✅ CONCEDIDA" : "❌ NEGADA"}                                ║');
      print('╚════════════════════════════════════════════════════════╝');
      
      return result as bool;
    } catch (e) {
      print('❌ Erro ao verificar permissão: $e');
      return false;
    }
  }

  /// Solicita permissão (abre configurações de acessibilidade)
  Future<void> solicitarPermissao() async {
    try {
      print('🔓 Abrindo configurações de acessibilidade...');
      await _methodChannel.invokeMethod('requestPermission');
    } catch (e) {
      print('❌ Erro ao solicitar permissão: $e');
      rethrow;
    }
  }

  /// Inicia o monitoramento de eventos
  Future<void> iniciarMonitoramento() async {
    if (_isMonitoring) {
      print('⚠️ Monitoramento já está ativo');
      return;
    }

    print('');
    print('╔════════════════════════════════════════════════════════╗');
    print('║ 🚀 INICIANDO MONITORAMENTO NATIVO                      ║');
    print('║ Packages: com.ubercab.driver, com.ubercab              ║');
    print('╚════════════════════════════════════════════════════════╝');
    print('');

    try {
      _eventSubscription = _eventChannel
          .receiveBroadcastStream()
          .listen(
            _processarEvento,
            onError: (error) {
              print('❌ Erro no stream de eventos: $error');
            },
            onDone: () {
              print('⚠️ Stream de eventos encerrado');
              _isMonitoring = false;
            },
            cancelOnError: false,
          );

      _isMonitoring = true;
      print('✅ Monitoramento ATIVO - Aguardando eventos do Uber...');
      print('');
    } catch (e) {
      print('❌ Erro ao iniciar monitoramento: $e');
      _isMonitoring = false;
      rethrow;
    }
  }

  /// Para o monitoramento de eventos
  void pararMonitoramento() {
    if (!_isMonitoring) {
      print('⚠️ Monitoramento já está inativo');
      return;
    }

    print('');
    print('╔════════════════════════════════════════════════════════╗');
    print('║ 🛑 PARANDO MONITORAMENTO                               ║');
    print('║ Eventos processados: $_eventCount                      ║');
    print('║ Corridas detectadas: $_corridasDetectadas              ║');
    print('╚════════════════════════════════════════════════════════╝');
    print('');

    _eventSubscription?.cancel();
    _eventSubscription = null;
    _isMonitoring = false;
  }

  /// Libera todos os recursos
  void dispose() {
    print('🗑️ Liberando recursos do serviço...');
    pararMonitoramento();
    _corridaController.close();
  }

  // ==========================================================================
  // MÉTODOS PRIVADOS - Processamento de eventos
  // ==========================================================================

  /// Processa eventos recebidos do serviço nativo
  void _processarEvento(dynamic event) {
    _eventCount++;

    try {
      // Converter evento para Map
      final Map<String, dynamic> dados = Map<String, dynamic>.from(event as Map);
      
      final packageName = dados['packageName'] as String;
      final eventType = dados['eventType'] as int;
      final List<dynamic> textosRaw = dados['textos'] as List<dynamic>;
      final textos = textosRaw.map((e) => e.toString()).toList();
      
      print('');
      print('═══════════════════════════════════════════════════════════════');
      print('🚕 EVENTO DO UBER #$_eventCount');
      print('═══════════════════════════════════════════════════════════════');
      print('📦 Package: $packageName');
      print('🔢 Tipo de evento: $eventType');
      print('📝 Textos capturados: ${textos.length}');
      
      // Mostrar preview dos textos
      if (textos.isNotEmpty) {
        final maxPreview = textos.length > 5 ? 5 : textos.length;
        for (int i = 0; i < maxPreview; i++) {
          final texto = textos[i];
          final preview = texto.length > 80 
              ? '${texto.substring(0, 80)}...' 
              : texto;
          print('   [$i] $preview');
        }
        if (textos.length > 5) {
          print('   ... e mais ${textos.length - 5} textos');
        }
      }

      // Analisar textos para extrair dados da corrida
      print('🔎 Analisando textos...');
      final dadosCorrida = _analisarTextos(textos);
      
      if (dadosCorrida.isNotEmpty) {
        _corridasDetectadas++;
        
        print('🎉 CORRIDA DETECTADA #$_corridasDetectadas:');
        dadosCorrida.forEach((key, value) {
          print('   ✅ $key: $value');
        });
        
        // Emitir evento no stream
        _corridaController.add(dadosCorrida);
      } else {
        print('⭕ Nenhum dado relevante de corrida encontrado');
      }
      
      print('═══════════════════════════════════════════════════════════════');
      print('');

    } catch (e, stack) {
      print('❌ Erro ao processar evento: $e');
      print('Stack trace: $stack');
    }
  }

  /// Analisa lista de textos para extrair dados da corrida
  Map<String, dynamic> _analisarTextos(List<String> textos) {
    final dados = <String, dynamic>{};
    
    // Juntar todos os textos para análise
    final textoCompleto = textos.join(' ');
    final textoLower = textoCompleto.toLowerCase();

    // ========================================================================
    // EXTRAÇÃO DE VALOR: R$ 25,00 ou R$25,00
    // ========================================================================
    final regexValor = RegExp(r'R\$\s*(\d+)[,\.](\d{2})');
    double maiorValor = 0.0;
    
    for (final match in regexValor.allMatches(textoCompleto)) {
      try {
        final reais = int.parse(match.group(1)!);
        final centavos = int.parse(match.group(2)!);
        final valor = reais + (centavos / 100);
        
        // Filtrar valores plausíveis (entre R$ 5,00 e R$ 500,00)
        if (valor >= 5.0 && valor <= 500.0 && valor > maiorValor) {
          maiorValor = valor;
          print('   💰 Valor encontrado: R\$ ${valor.toStringAsFixed(2)}');
        }
      } catch (e) {
        // Ignorar valores inválidos
      }
    }
    
    if (maiorValor > 0) {
      dados['valor'] = maiorValor;
    }

    // ========================================================================
    // EXTRAÇÃO DE TEMPOS: BUSCA + VIAGEM = TEMPO TOTAL
    // Exemplos no texto:
    // "6 minutos (2.1 km) de distância" <- tempo de BUSCA
    // "Viagem de 9 minutos (3.5 km)" <- tempo de VIAGEM
    // ========================================================================
    
    int? tempoBusca;
    int? tempoViagem;
    
    // Padrão 1: Tempo de BUSCA (distância até o passageiro)
    // "6 minutos (2.1 km) de distância"
    // "2 minutos (0.1 km) de distância"
    final regexBusca = RegExp(r'(\d+)\s*minutos?\s*\([^)]+\)\s*de\s+dist[aâ]ncia', caseSensitive: false);
    final matchBusca = regexBusca.firstMatch(textoCompleto);
    
    if (matchBusca != null) {
      tempoBusca = int.parse(matchBusca.group(1)!);
      print('   🚶 Tempo de BUSCA: ${tempoBusca}min');
    }
    
    // Padrão 2: Tempo de VIAGEM (duração da corrida)
    // "Viagem de 9 minutos (3.5 km)"
    // "Viagem de 19 minutos (7.6 km)"
    final regexViagem = RegExp(r'viagem\s+de\s+(\d+)\s*minutos?', caseSensitive: false);
    final matchViagem = regexViagem.firstMatch(textoCompleto);
    
    if (matchViagem != null) {
      tempoViagem = int.parse(matchViagem.group(1)!);
      print('   🚗 Tempo de VIAGEM: ${tempoViagem}min');
    }
    
    // Calcular TEMPO TOTAL = BUSCA + VIAGEM
    if (tempoBusca != null && tempoViagem != null) {
      final tempoTotal = tempoBusca + tempoViagem;
      dados['tempoMinutos'] = tempoTotal;
      dados['tempoBusca'] = tempoBusca;
      dados['tempoViagem'] = tempoViagem;
      print('   ⏱️ TEMPO TOTAL: ${tempoTotal}min (${tempoBusca}min busca + ${tempoViagem}min viagem)');
    } else if (tempoViagem != null) {
      // Fallback: se só tiver viagem, usar apenas esse tempo
      dados['tempoMinutos'] = tempoViagem;
      print('   ⏱️ TEMPO (apenas viagem): ${tempoViagem}min');
    }

    // ========================================================================
    // EXTRAÇÃO DE DISTÂNCIA
    // ========================================================================
    final regexDistancia = RegExp(r'(\d+[,\.]?\d*)\s*km', caseSensitive: false);
    double maiorDistancia = 0.0;
    
    for (final match in regexDistancia.allMatches(textoCompleto)) {
      try {
        final distanciaStr = match.group(1)!.replaceAll(',', '.');
        final distancia = double.parse(distanciaStr);
        
        if (distancia > 0 && distancia <= 100 && distancia > maiorDistancia) {
          maiorDistancia = distancia;
        }
      } catch (e) {
        // Ignorar
      }
    }
    
    if (maiorDistancia > 0) {
      dados['distancia'] = maiorDistancia;
      print('   📏 Distância total: ${maiorDistancia}km');
    }

    // ========================================================================
    // DETECÇÃO DE TIPO DE CORRIDA
    // ========================================================================
    if (textoLower.contains('uberx')) {
      dados['tipo'] = 'UberX';
      print('   🚗 Tipo: UberX');
    } else if (textoLower.contains('comfort')) {
      dados['tipo'] = 'Comfort';
      print('   🚗 Tipo: Comfort');
    } else if (textoLower.contains('black')) {
      dados['tipo'] = 'Black';
      print('   🚗 Tipo: Black');
    } else if (textoLower.contains('uber') && textoLower.contains('pet')) {
      dados['tipo'] = 'Uber Pet';
      print('   🚗 Tipo: Uber Pet');
    }

    // ========================================================================
    // DETECÇÃO DE STATUS DA CORRIDA
    // ========================================================================
    final palavrasNovaCorreida = [
      'aceitar', 'nova corrida', 'nova viagem', 'solicitação',
      'aceite em', 'segundos para aceitar', 'selecionar'
    ];
    
    final palavrasEmAndamento = [
      'a caminho', 'chegando', 'indo buscar', 'em viagem',
      'destino', 'navegando', 'iniciada'
    ];
    
    final palavrasFinalizadas = [
      'finalizada', 'concluída', 'ganhos', 'você ganhou',
      'recebido', 'valor da viagem', 'pagamento', 'viagem encerrada'
    ];

    if (palavrasFinalizadas.any((p) => textoLower.contains(p))) {
      dados['emAndamento'] = false;
      dados['status'] = 'finalizada';
      print('   🏁 Status: FINALIZADA');
    } else if (palavrasEmAndamento.any((p) => textoLower.contains(p))) {
      dados['emAndamento'] = true;
      dados['status'] = 'em_andamento';
      print('   🚗 Status: EM ANDAMENTO');
    } else if (palavrasNovaCorreida.any((p) => textoLower.contains(p))) {
      dados['emAndamento'] = false;
      dados['status'] = 'disponivel';
      print('   🆕 Status: NOVA CORRIDA DISPONÍVEL');
    }

    // ========================================================================
    // ADICIONAR METADADOS
    // ========================================================================
    if (dados.isNotEmpty) {
      dados['dataHora'] = DateTime.now().toIso8601String();
      dados['textoCompleto'] = textoCompleto;
      
      // Limitar tamanho do texto completo
      if (textoCompleto.length > 1000) {
        dados['textoCompleto'] = textoCompleto.substring(0, 1000);
      }
    }

    return dados;
  }

  // ==========================================================================
  // GETTERS PÚBLICOS
  // ==========================================================================
  
  /// Retorna se o monitoramento está ativo
  bool get estaMonitorando => _isMonitoring;
  
  /// Retorna o número de eventos processados
  int get eventosProcessados => _eventCount;
  
  /// Retorna o número de corridas detectadas
  int get corridasDetectadas => _corridasDetectadas;
}