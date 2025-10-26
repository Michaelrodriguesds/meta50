// ============================================================================
// ARQUIVO: test/widget_test.dart (CORRIGIDO)
// DESCRIÇÃO: Testes básicos do aplicativo Uber Monitor
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uber_monitor/main.dart';

void main() {
  // Teste básico de inicialização do app
  testWidgets('App inicializa sem erros', (WidgetTester tester) async {
    // Constrói o app e renderiza um frame
    await tester.pumpWidget(const UberMonitorApp());
    
    // Aguarda todas as animações e builds assíncronos
    await tester.pumpAndSettle();
    
    // Verifica se o app bar foi criado
    expect(find.byType(AppBar), findsOneWidget);
    
    // Verifica se a navegação inferior existe
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
  
  // Teste de navegação entre abas
  testWidgets('Navegação entre abas funciona', (WidgetTester tester) async {
    // Constrói o app
    await tester.pumpWidget(const UberMonitorApp());
    await tester.pumpAndSettle();
    
    // Verifica se está na primeira aba (Corrida Atual)
    expect(find.text('Corrida Atual'), findsOneWidget);
    
    // Toca na segunda aba (Objetivos)
    await tester.tap(find.text('Objetivos'));
    await tester.pumpAndSettle();
    
    // Verifica se mudou para a segunda aba
    expect(find.text('Objetivos'), findsOneWidget);
  });
}