// ============================================================================
// ARQUIVO: lib/screens/painel_corrida_screen.dart (v2.0 FINAL CORRIGIDO)
// DESCRIÇÃO: Tela com ciclo, cronômetro e análise inteligente
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/corrida_provider.dart';

class PainelCorridaScreen extends StatelessWidget {
  const PainelCorridaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CorridaProvider>(
      builder: (context, provider, child) {
        if (provider.verificandoPermissao) {
          return _buildTelaLoading();
        }
        
        if (!provider.permissaoConcedida) {
          return _buildTelaPermissao(context, provider);
        }
        
        return _buildPainelCorrida(context, provider);
      },
    );
  }
  
  Widget _buildTelaLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.black),
          SizedBox(height: 16),
          Text(
            'Verificando permissões...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTelaPermissao(BuildContext context, CorridaProvider provider) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.accessibility_new,
                  size: 60,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Permissão Necessária',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Text(
                'Para monitorar as corridas do Uber Driver em tempo real, '
                'este app precisa de permissão de Acessibilidade.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 12),
                          Text(
                            'Como conceder:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildPassoPermissao('1', 'Toque no botão abaixo'),
                      _buildPassoPermissao('2', 'Encontre "Uber Monitor"'),
                      _buildPassoPermissao('3', 'Ative a permissão'),
                      _buildPassoPermissao('4', 'Volte para este app'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                onPressed: () => provider.solicitarPermissao(),
                icon: const Icon(Icons.settings),
                label: const Text(
                  'Abrir Configurações',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextButton.icon(
                onPressed: () => provider.reverificarPermissao(),
                icon: const Icon(Icons.refresh),
                label: const Text('Já concedi a permissão'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPassoPermissao(String numero, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                numero,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPainelCorrida(BuildContext context, CorridaProvider provider) {
    final formatadorMoeda = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    
    return RefreshIndicator(
      onRefresh: () => provider.reverificarPermissao(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (provider.temCicloAtivo) ...[
              _buildCardCiclo(provider, formatadorMoeda),
              const SizedBox(height: 16),
            ],
            
            _buildCardCorridaAtual(provider, formatadorMoeda),
            const SizedBox(height: 16),
            
            _buildCardEstatisticas(provider, formatadorMoeda),
            const SizedBox(height: 16),
            
            _buildCardInstrucoes(),
            const SizedBox(height: 16),
            
            _buildBotoesAcao(context, provider),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCardCiclo(CorridaProvider provider, NumberFormat formatador) {
    final ciclo = provider.cicloAtual!;
    final progresso = ciclo.percentualProgresso / 100;
    
    final minutos = ciclo.minutosRestantes;
    final horas = minutos ~/ 60;
    final mins = minutos % 60;
    final tempoFormatado = horas > 0 
        ? '${horas}h ${mins}min'
        : '${mins}min';
    
    return Card(
      color: ciclo.metaAtingida ? Colors.green.shade50 : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CICLO ATIVO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ciclo.metaAtingida 
                            ? Colors.green.shade900 
                            : Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ciclo.metaAtingida ? '🎉 META ATINGIDA!' : 'Meta: R\$ 50 em 60min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 20,
                        color: minutos <= 10 ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tempoFormatado,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: minutos <= 10 ? Colors.red : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progresso,
                minHeight: 30,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  ciclo.metaAtingida ? Colors.green : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acumulado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      formatador.format(ciclo.valorAcumulado),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Falta',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      formatador.format(ciclo.valorRestante),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ciclo.metaAtingida ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Projeção Final:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    formatador.format(ciclo.projecaoFinal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCardCorridaAtual(CorridaProvider provider, NumberFormat formatador) {
    final corrida = provider.corridaAtual;
    final formatadorHora = DateFormat('HH:mm');
    
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildIndicadorStatus(corrida.emAndamento),
            const SizedBox(height: 32),
            
            _buildSecaoValor(corrida.valor, formatador),
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  icon: Icons.timer,
                  label: 'Duração',
                  valor: corrida.tempoMinutos > 0
                      ? '${corrida.tempoMinutos} min'
                      : '--',
                  cor: Colors.blue,
                ),
                _buildInfoItem(
                  icon: Icons.access_time,
                  label: 'Horário',
                  valor: formatadorHora.format(corrida.dataHora),
                  cor: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCardEstatisticas(CorridaProvider provider, NumberFormat formatador) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas de Hoje',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEstatistica(
                  'Corridas',
                  '${provider.corridasHoje}',
                  Icons.local_taxi,
                  Colors.purple,
                ),
                _buildEstatistica(
                  'Ganhos',
                  formatador.format(provider.ganhosHoje),
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildEstatistica(
                  'Média',
                  formatador.format(provider.valorMedioCorridas),
                  Icons.trending_up,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCardInstrucoes() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'O app analisa cada corrida automaticamente e mostra '
                'um overlay VERDE (aceitar) ou VERMELHO (rejeitar).',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBotoesAcao(BuildContext context, CorridaProvider provider) {
    return Column(
      children: [
        if (provider.temCicloAtivo)
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reiniciar Ciclo'),
                  content: const Text(
                    'Tem certeza que deseja reiniciar o ciclo atual? '
                    'Isso apagará o progresso.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        provider.reiniciarCiclo();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reiniciar'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reiniciar Ciclo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        const SizedBox(height: 8),
        
        OutlinedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => _buildDialogoAdicionarManual(provider),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Adicionar Corrida Manual'),
        ),
      ],
    );
  }
  
  Widget _buildDialogoAdicionarManual(CorridaProvider provider) {
    final controllerValor = TextEditingController();
    final controllerTempo = TextEditingController();
    
    return Builder(
      builder: (dialogContext) => AlertDialog(
        title: const Text('Adicionar Corrida Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controllerValor,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                hintText: '25.50',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controllerTempo,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tempo (minutos)',
                hintText: '15',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = double.tryParse(controllerValor.text);
              final tempo = int.tryParse(controllerTempo.text);
              
              if (valor != null) {
                provider.adicionarCorridaManual(
                  valor: valor,
                  tempoMinutos: tempo,
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIndicadorStatus(bool emAndamento) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: emAndamento ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: emAndamento ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emAndamento)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          if (emAndamento) const SizedBox(width: 12),
          
          Icon(
            emAndamento ? Icons.directions_car : Icons.check_circle_outline,
            color: emAndamento ? Colors.green.shade700 : Colors.grey.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          
          Text(
            emAndamento ? 'EM ANDAMENTO' : 'ÚLTIMA CORRIDA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: emAndamento ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSecaoValor(double valor, NumberFormat formatador) {
    return Column(
      children: [
        Text(
          'Valor da Corrida',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          valor > 0 ? formatador.format(valor) : 'Aguardando...',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: valor > 0 ? Colors.black : Colors.grey,
          ),
        ),
        if (valor == 0.0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Nenhuma corrida detectada ainda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String valor,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(cor.withOpacity(0.1), Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: cor),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEstatistica(
    String label,
    String valor,
    IconData icon,
    Color cor,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color.alphaBlend(cor.withOpacity(0.1), Colors.white),
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
}