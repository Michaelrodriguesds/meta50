// ============================================================================
// ARQUIVO: lib/services/background_service.dart
// LOCALIZAÇÃO: uber_monitor/lib/services/
// DESCRIÇÃO: Serviço básico para tarefas em segundo plano
// ============================================================================

import 'package:flutter/foundation.dart';  // Adicionado: necessário para debugPrint

class BackgroundService {
  // Singleton
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  bool _isRunning = false;

  /// Inicializa o serviço (chamado no main)
  Future<void> initialize() async {
    // Adicione inicializações aqui, ex.: workmanager
    debugPrint('BackgroundService inicializado');  // Agora funciona com o import
  }

  /// Inicia o serviço em segundo plano
  Future<void> startService() async {
    if (_isRunning) return;
    _isRunning = true;
    // Implemente lógica real aqui (ex.: workmanager ou flutter_background_service)
    debugPrint('Serviço em background iniciado');  // Agora funciona
  }

  /// Para o serviço em segundo plano
  Future<void> stopService() async {
    if (!_isRunning) return;
    _isRunning = false;
    // Implemente lógica real aqui
    debugPrint('Serviço em background parado');  // Agora funciona
  }

  /// Verifica se o serviço está rodando
  Future<bool> isServiceRunning() async {
    return _isRunning;
  }

  /// Envia dados para o serviço (ex.: para comunicação com provider)
  void sendData(Map<String, dynamic> data) {
    // Implemente envio de dados aqui
    debugPrint('Dados enviados para background: $data');  // Agora funciona
  }
}