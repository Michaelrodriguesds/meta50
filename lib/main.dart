// ============================================================================
// ARQUIVO: lib/main.dart (VERSÃO FINAL v3.0)
// DESCRIÇÃO: Arquivo principal com overlay NATIVO sobre Uber
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/painel_corrida_screen.dart';
import 'screens/painel_objetivos_screen.dart';
import 'providers/corrida_provider.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  await BackgroundService().initialize();
  
  runApp(const UberMonitorApp());
}

class UberMonitorApp extends StatelessWidget {
  const UberMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CorridaProvider(),
      child: MaterialApp(
        title: 'Uber Monitor',
        debugShowCheckedModeBanner: false,
        
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            brightness: Brightness.light,
            primary: Colors.black,
            secondary: Colors.grey[800]!,
          ),
          
          useMaterial3: true,
          
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
        
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _abaAtual = 0;
  final BackgroundService _backgroundService = BackgroundService();
  bool _servicoAtivo = false;
  
  // Permissão de overlay
  static const platform = MethodChannel('com.example.uber_monitor/overlay');
  bool _overlayPermissionGranted = false;
  
  final List<Widget> _telas = const [
    PainelCorridaScreen(),
    PainelObjetivosScreen(),
  ];
  
  final List<String> _titulos = const [
    'Corrida Atual',
    'Objetivos',
  ];

  @override
  void initState() {
    super.initState();
    _iniciarServicoBackground();
    _verificarStatusServico();
    _verificarPermissaoOverlay();
    _configurarCallbackOverlay();
  }

  /// Verifica permissão de overlay
  Future<void> _verificarPermissaoOverlay() async {
    try {
      final bool hasPermission = await platform.invokeMethod('checkOverlayPermission');
      setState(() {
        _overlayPermissionGranted = hasPermission;
      });
      
      debugPrint('🔍 Permissão de overlay: $hasPermission');
      
      if (!hasPermission) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _mostrarDialogoPermissaoOverlay();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar permissão de overlay: $e');
    }
  }

  /// Solicita permissão de overlay
  Future<void> _solicitarPermissaoOverlay() async {
    try {
      await platform.invokeMethod('requestOverlayPermission');
      await Future.delayed(const Duration(seconds: 2));
      await _verificarPermissaoOverlay();
    } catch (e) {
      debugPrint('❌ Erro ao solicitar permissão de overlay: $e');
    }
  }

  /// Dialog explicando permissão de overlay
  void _mostrarDialogoPermissaoOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.layers, color: Colors.blue),
            SizedBox(width: 12),
            Text('Permissão Adicional'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para mostrar a recomendação SOBRE o Uber Driver, '
              'precisamos de uma permissão adicional.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              '✅ Com essa permissão:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• O overlay aparece sobre o Uber'),
            Text('• Você vê a recomendação em tempo real'),
            Text('• Sem precisar alternar entre apps'),
            SizedBox(height: 16),
            Text(
              '⚠️ Importante:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            Text('Esta permissão é segura e necessária.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Agora não'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _solicitarPermissaoOverlay();
            },
            child: const Text('Conceder'),
          ),
        ],
      ),
    );
  }

  /// Configura callback do overlay
  void _configurarCallbackOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CorridaProvider>(context, listen: false);
      provider.onMostrarOverlay = _mostrarOverlayNativo;
    });
  }

  /// Mostra overlay NATIVO sobre o Uber
  Future<void> _mostrarOverlayNativo(analise) async {
    if (!_overlayPermissionGranted) {
      debugPrint('⚠️ Sem permissão de overlay. Mostrando dialog.');
      _mostrarDialogDentroApp(analise);
      return;
    }
    
    try {
      debugPrint('╔════════════════════════════════════════════════════╗');
      debugPrint('║ 🎨 CHAMANDO OVERLAY NATIVO DO FLUTTER             ║');
      debugPrint('╚════════════════════════════════════════════════════╝');
      debugPrint('📊 Decisão: ${analise.deveAceitar ? "✅ ACEITAR" : "❌ REJEITAR"}');
      debugPrint('💬 Motivo: ${analise.motivo}');
      debugPrint('💰 Valor: R\$ ${analise.valorCorrida.toStringAsFixed(2)}');
      debugPrint('⏱️ Tempo: ${analise.tempoTotal} min');
      
      final resultado = await platform.invokeMethod('showNativeOverlay', {
        'deveAceitar': analise.deveAceitar,
        'motivo': analise.motivo,
        'valorCorrida': analise.valorCorrida,
        'tempoTotal': analise.tempoTotal,
        'valorPorMinuto': analise.valorPorMinuto,
      });
      
      debugPrint('✅ Overlay nativo exibido: $resultado');
      
    } catch (e) {
      debugPrint('❌ ERRO ao exibir overlay nativo: $e');
      _mostrarDialogDentroApp(analise);
    }
  }

  /// Fallback: mostra como dialog dentro do app
  void _mostrarDialogDentroApp(analise) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: analise.deveAceitar ? Colors.green[50] : Colors.red[50],
        title: Row(
          children: [
            Icon(
              analise.deveAceitar ? Icons.check_circle : Icons.cancel,
              color: analise.deveAceitar ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              analise.deveAceitar ? 'ACEITAR!' : 'REJEITAR!',
              style: TextStyle(
                color: analise.deveAceitar ? Colors.green[900] : Colors.red[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              analise.motivo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow('💰 Valor:', 'R\$ ${analise.valorCorrida.toStringAsFixed(2)}'),
            _buildInfoRow('⏱️ Tempo:', '${analise.tempoTotal} min'),
            _buildInfoRow('💵 R\$/Min:', 'R\$ ${analise.valorPorMinuto.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
    
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  Widget _buildInfoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            valor,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _iniciarServicoBackground() async {
    try {
      await _backgroundService.startService();
      debugPrint('✅ Serviço de background iniciado');
    } catch (e) {
      debugPrint('❌ Erro ao iniciar serviço: $e');
    }
  }

  Future<void> _verificarStatusServico() async {
    final status = await _backgroundService.isServiceRunning();
    setState(() {
      _servicoAtivo = status;
    });
  }

  Future<void> _toggleServicoBackground() async {
    if (_servicoAtivo) {
      await _backgroundService.stopService();
      _mostrarMensagem('Serviço parado');
    } else {
      await _backgroundService.startService();
      _mostrarMensagem('Serviço iniciado');
    }
    await _verificarStatusServico();
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_abaAtual]),
        
        actions: [
          // Indicador de permissão de overlay
          if (!_overlayPermissionGranted)
            IconButton(
              icon: const Icon(Icons.layers, color: Colors.orange),
              onPressed: _solicitarPermissaoOverlay,
              tooltip: 'Permissão de Overlay necessária',
            ),
          
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _mostrarDialogoAjuda,
            tooltip: 'Ajuda',
          ),
          
          IconButton(
            icon: Icon(
              _servicoAtivo ? Icons.visibility : Icons.visibility_off,
              color: _servicoAtivo ? Colors.green : Colors.grey,
            ),
            onPressed: _toggleServicoBackground,
            tooltip: _servicoAtivo ? 'Serviço ativo' : 'Serviço inativo',
          ),
          
          Consumer<CorridaProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.permissaoConcedida
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                ),
                onPressed: () => provider.reverificarPermissao(),
                tooltip: provider.permissaoConcedida ? 'Permissão OK' : 'Verificar',
                color: provider.permissaoConcedida ? Colors.green : Colors.orange,
              );
            },
          ),
        ],
      ),
      
      body: IndexedStack(
        index: _abaAtual,
        children: _telas,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _abaAtual,
        onTap: (index) => setState(() => _abaAtual = index),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_taxi),
            label: 'Corrida Atual',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Objetivos',
          ),
        ],
      ),
    );
  }
  
  void _mostrarDialogoAjuda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text('Como usar'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildItemAjuda(
                '1️⃣',
                'Permissão de Acessibilidade',
                'Conceda nas configurações do Android.',
              ),
              const SizedBox(height: 16),
              _buildItemAjuda(
                '2️⃣',
                'Permissão de Overlay',
                'Necessária para mostrar sobre o Uber. '
                'Clique no ícone laranja.',
              ),
              const SizedBox(height: 16),
              _buildItemAjuda(
                '3️⃣',
                'Sistema Inteligente',
                'Overlay VERDE (aceitar) ou VERMELHO (rejeitar).',
              ),
              const SizedBox(height: 16),
              _buildItemAjuda(
                '4️⃣',
                'Ciclo de 60min / R\$ 50',
                'Inicia ao aceitar a primeira corrida.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildItemAjuda(String emoji, String titulo, String descricao) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 28, top: 4),
          child: Text(
            descricao,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}