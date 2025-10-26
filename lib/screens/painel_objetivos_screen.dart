// ============================================================================
// ARQUIVO: lib/screens/painel_objetivos_screen.dart
// DESCRIÇÃO: Tela para gerenciar objetivos e metas diárias
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/corrida_provider.dart';
import '../models/corrida_model.dart';

class PainelObjetivosScreen extends StatefulWidget {
  const PainelObjetivosScreen({super.key});

  @override
  State<PainelObjetivosScreen> createState() => _PainelObjetivosScreenState();
}

class _PainelObjetivosScreenState extends State<PainelObjetivosScreen> {
  final Map<String, double> _objetivos = {
    'metaDiaria': 200.0,
    'tempoDisponivel': 8.0,
    'valorPorHora': 25.0,
  };

  @override
  void initState() {
    super.initState();
    _carregarObjetivos();
  }

  Future<void> _carregarObjetivos() async {
    try {
      // Simulação de carregamento - em produção, use SharedPreferences
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Valores padrão
      setState(() {
        _objetivos['metaDiaria'] = 200.0;
        _objetivos['tempoDisponivel'] = 8.0;
        _objetivos['valorPorHora'] = 25.0;
      });
    } catch (e) {
      _log('Erro ao carregar objetivos: $e');
    }
  }

  Future<void> _salvarObjetivo(String chave, double valor) async {
    try {
      // Simulação de salvamento - em produção, use SharedPreferences
      await Future.delayed(const Duration(milliseconds: 100));
      
      setState(() {
        _objetivos[chave] = valor;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$chave atualizado para: R\$${valor.toStringAsFixed(2)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CorridaProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estatísticas do Dia',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildEstatistica(
                            'Total de Corridas',
                            '${provider.corridasHoje}',
                            Icons.local_taxi,
                            Colors.purple,
                          ),
                          _buildEstatistica(
                            'Ganhos de Hoje',
                            'R\$${provider.ganhosHoje.toStringAsFixed(2)}',
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configurações de Objetivos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildConfiguracaoObjetivo(
                        context,
                        'Meta Diária',
                        'R\$${_objetivos['metaDiaria']!.toStringAsFixed(2)}',
                        Icons.flag,
                        'metaDiaria',
                        _objetivos['metaDiaria']!,
                      ),
                      const SizedBox(height: 12),
                      _buildConfiguracaoObjetivo(
                        context,
                        'Tempo Disponível',
                        '${_objetivos['tempoDisponivel']!.toStringAsFixed(0)} horas',
                        Icons.timer,
                        'tempoDisponivel',
                        _objetivos['tempoDisponivel']!,
                      ),
                      const SizedBox(height: 12),
                      _buildConfiguracaoObjetivo(
                        context,
                        'Valor por Hora',
                        'R\$${_objetivos['valorPorHora']!.toStringAsFixed(2)}',
                        Icons.trending_up,
                        'valorPorHora',
                        _objetivos['valorPorHora']!,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Histórico Recente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: provider.historicoCorridas.isNotEmpty
                              ? ListView.builder(
                                  itemCount: provider.historicoCorridas.length,
                                  itemBuilder: (context, index) {
                                    final corrida = provider.historicoCorridas[index];
                                    return _buildItemHistorico(corrida);
                                  },
                                )
                              : const Center(
                                  child: Text(
                                    'Nenhuma corrida registrada ainda',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstatistica(String label, String valor, IconData icon, Color cor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _blendColor(cor, 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: cor),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConfiguracaoObjetivo(
    BuildContext context,
    String titulo,
    String valor,
    IconData icon,
    String chave,
    double valorAtual,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () {
              _mostrarDialogoEdicao(context, titulo, valorAtual, chave);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemHistorico(CorridaModel corrida) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _blendColor(Colors.green, 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_taxi, size: 20, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'R\$${corrida.valor.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${corrida.tempoMinutos} min',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${corrida.dataHora.hour.toString().padLeft(2, '0')}:${corrida.dataHora.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEdicao(BuildContext context, String titulo, double valorAtual, String chave) {
    final controller = TextEditingController(text: valorAtual.toStringAsFixed(2));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar $titulo'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Novo valor para $titulo',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final novoValor = double.tryParse(controller.text) ?? valorAtual;
              _salvarObjetivo(chave, novoValor);
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  /// Método auxiliar para criar cores com opacidade sem usar withOpacity
  Color _blendColor(Color color, double opacity) {
    return Color.alphaBlend(color.withOpacity(opacity), Colors.white);
  }

  void _log(String message) {
    // TODO: Implementar sistema de logging apropriado
    // ignore: avoid_print
    print(message);
  }
}