// ============================================================================
// ARQUIVO: lib/widgets/overlay_decisao_widget.dart (ESTILO UBER)
// DESCRIÇÃO: Overlay com design similar ao Uber Driver
// ============================================================================

import 'package:flutter/material.dart';
import '../models/analise_result_model.dart';

class OverlayDecisaoWidget extends StatelessWidget {
  final AnaliseResultModel analise;
  final VoidCallback onDismiss;
  
  const OverlayDecisaoWidget({
    super.key,
    required this.analise,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Cores baseadas na decisão
    final corPrincipal = analise.deveAceitar 
        ? const Color(0xFF00C853)  // Verde Uber
        : const Color(0xFFE53935); // Vermelho
    
    final corFundo = analise.deveAceitar
        ? const Color(0xFF00C853).withValues(alpha: 0.95)
        : const Color(0xFFE53935).withValues(alpha: 0.95);
    
    return Material(
      color: Colors.black.withValues(alpha: 0.5), // Fundo escurecido
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header colorido (Verde ou Vermelho)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: corFundo,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Ícone grande
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          analise.deveAceitar 
                              ? Icons.check_circle 
                              : Icons.cancel,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Título
                      Text(
                        analise.deveAceitar ? 'ACEITAR!' : 'REJEITAR!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Motivo
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          analise.motivo,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Corpo branco com informações
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Linha 1: R$/Km | R$/Hora | Nota
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetrica(
                            'R\$/Km',
                            'R\$ ${(analise.valorCorrida / (analise.tempoTotal * 0.6)).toStringAsFixed(2)}',
                            corPrincipal,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          _buildMetrica(
                            'R\$/Hora',
                            'R\$ ${(analise.valorPorMinuto * 60).toStringAsFixed(2)}',
                            corPrincipal,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          _buildMetrica(
                            'Nota',
                            analise.deveAceitar ? '4.95' : '3.20',
                            Colors.amber,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // Detalhes da corrida
                      _buildDetalhe(
                        Icons.attach_money,
                        'Valor Total',
                        'R\$ ${analise.valorCorrida.toStringAsFixed(2)}',
                        corPrincipal,
                      ),
                      const SizedBox(height: 12),
                      _buildDetalhe(
                        Icons.schedule,
                        'Tempo Total',
                        '${analise.tempoTotal} min',
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildDetalhe(
                        Icons.speed,
                        'Valor/Minuto',
                        'R\$ ${analise.valorPorMinuto.toStringAsFixed(2)}',
                        Colors.purple,
                      ),
                      
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // Informações do ciclo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfoCiclo(
                                  'Tempo Restante',
                                  '${analise.tempoRestanteCiclo} min',
                                  Icons.timer,
                                ),
                                _buildInfoCiclo(
                                  'Falta p/ Meta',
                                  'R\$ ${analise.valorRestanteParaMeta.toStringAsFixed(2)}',
                                  Icons.flag,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
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
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'R\$ ${analise.projecaoFinal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: corPrincipal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Botão Fechar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onDismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corPrincipal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'ENTENDI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMetrica(String titulo, String valor, Color cor) {
    return Column(
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetalhe(IconData icone, String label, String valor, Color cor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icone, size: 20, color: cor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoCiclo(String label, String valor, IconData icone) {
    return Expanded(
      child: Column(
        children: [
          Icon(icone, size: 24, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}