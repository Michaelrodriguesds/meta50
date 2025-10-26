// ============================================================================
// ARQUIVO: android/app/src/main/kotlin/com/example/uber_monitor/UberAccessibilityService.kt
// VERSÃO: v5.0 COMPLETO - Com TODOS os logs + controle de duplicatas
// ============================================================================

package com.example.uber_monitor

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.plugin.common.EventChannel
import android.util.Log
import kotlin.math.abs

class UberAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "UberAccessibility"
        
        // OverlayManager - mostra overlay direto do serviço
        private var overlayManager: OverlayManager? = null
        
        // EventSink para enviar eventos para Flutter (opcional)
        private var eventSink: EventChannel.EventSink? = null
        
        // ═════════════════════════════════════════════════════════════
        // CONTROLE PARA NÃO FICAR ATUALIZANDO A MESMA CORRIDA
        // ═════════════════════════════════════════════════════════════
        private var ultimaCorridaValor: Double = 0.0
        private var ultimaCorridaTempo: Long = 0
        private const val INTERVALO_MINIMO_MS = 5000 // 5 segundos
        
        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
            Log.d(TAG, if (sink != null) "✅ EventSink conectado" else "❌ EventSink desconectado")
        }
    }

    override fun onCreate() {
        super.onCreate()
        // Cria OverlayManager quando o serviço é criado
        overlayManager = OverlayManager(applicationContext)
        Log.d(TAG, "🚀 Serviço CRIADO - OverlayManager inicializado")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        
        Log.d(TAG, "╔══════════════════════════════════════════════════╗")
        Log.d(TAG, "║ ✅ SERVIÇO v5.0 CONECTADO                       ║")
        Log.d(TAG, "╚══════════════════════════════════════════════════╝")
        Log.d(TAG, "⚙️  Modo: MOSTRA UMA VEZ - Não fica atualizando")
        
        // Configurar o serviço
        val info = AccessibilityServiceInfo().apply {
            // Tipos de eventos que queremos capturar
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                        AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED or
                        AccessibilityEvent.TYPE_VIEW_CLICKED
            
            // Feedback
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            
            // Filtrar apenas apps Uber
            packageNames = arrayOf(
                "com.ubercab.driver",
                "com.ubercab",
                "com.ubercab.driverapp"
            )
            
            // Configurações importantes
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                   AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                   AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            
            // Delay mínimo para reduzir spam
            notificationTimeout = 100
        }
        
        serviceInfo = info
        
        Log.d(TAG, "⚙️ Configurações:")
        Log.d(TAG, "   - Packages: ${info.packageNames?.joinToString()}")
        Log.d(TAG, "   - Event Types: ${info.eventTypes}")
        Log.d(TAG, "   - Flags: ${info.flags}")
        Log.d(TAG, "   - OverlayManager: ${if (overlayManager != null) "✅ OK" else "❌ NULL"}")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        try {
            val packageName = event.packageName?.toString() ?: "unknown"
            
            Log.v(TAG, "📥 Evento: tipo=${event.eventType}, package=$packageName")
            
            // Extrair todos os textos
            val textos = mutableSetOf<String>() // Set para evitar duplicatas
            
            // 1. Texto do evento
            event.text?.forEach { text ->
                if (!text.isNullOrEmpty()) {
                    textos.add(text.toString())
                }
            }
            
            // 2. Content Description
            if (!event.contentDescription.isNullOrEmpty()) {
                textos.add(event.contentDescription.toString())
            }
            
            // 3. Extrair da hierarquia de Views (mais importante!)
            event.source?.let { rootNode ->
                extractAllText(rootNode, textos, 0)
            }
            
            // Se encontrou textos, processar
            if (textos.isNotEmpty()) {
                
                // ═════════════════════════════════════════════════════════════
                // ANÁLISE AUTOMÁTICA E OVERLAY (INDEPENDENTE DO FLUTTER)
                // ═════════════════════════════════════════════════════════════
                val analise = analisarCorrida(textos.toList())
                
                if (analise != null) {
                    
                    // ─────────────────────────────────────────────────────────
                    // VERIFICA SE É A MESMA CORRIDA (evita spam)
                    // ─────────────────────────────────────────────────────────
                    val agora = System.currentTimeMillis()
                    val mesmaCorreida = abs(analise.valor - ultimaCorridaValor) < 1.0
                    val tempoDecorrido = agora - ultimaCorridaTempo
                    
                    if (mesmaCorreida && tempoDecorrido < INTERVALO_MINIMO_MS) {
                        // É a mesma corrida e ainda não passou tempo suficiente
                        Log.v(TAG, "⏭️ Mesma corrida - ignorando atualização (${tempoDecorrido}ms)")
                        return
                    }
                    
                    // ─────────────────────────────────────────────────────────
                    // NOVA CORRIDA ou tempo suficiente passou
                    // ─────────────────────────────────────────────────────────
                    ultimaCorridaValor = analise.valor
                    ultimaCorridaTempo = agora
                    
                    Log.d(TAG, "🎯 CORRIDA DETECTADA!")
                    
                    // MOSTRA OVERLAY DIRETAMENTE (não depende do Flutter)
                    overlayManager?.mostrarRecomendacao(
                        deveAceitar = analise.deveAceitar,
                        motivo = analise.motivo,
                        valorCorrida = analise.valor,
                        tempoTotal = analise.tempo,
                        valorPorMinuto = analise.valorPorMinuto
                    )
                }
                
                // ═════════════════════════════════════════════════════════════
                // ENVIA PARA FLUTTER (SE ESTIVER CONECTADO) - OPCIONAL
                // ═════════════════════════════════════════════════════════════
                if (eventSink != null) {
                    val dados = hashMapOf<String, Any>(
                        "packageName" to packageName,
                        "eventType" to event.eventType,
                        "textos" to textos.toList(),
                        "timestamp" to System.currentTimeMillis()
                    )
                    eventSink?.success(dados)
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erro ao processar evento: ${e.message}", e)
        }
    }

    /**
     * ═══════════════════════════════════════════════════════════════════════
     * ANÁLISE SIMPLIFICADA DE CORRIDA (DIRETO NO SERVIÇO NATIVO)
     * ═══════════════════════════════════════════════════════════════════════
     * Esta análise é INDEPENDENTE do Flutter e roda sempre!
     */
    private fun analisarCorrida(textos: List<String>): AnaliseSimples? {
        try {
            // ─────────────────────────────────────────────────────────────
            // 1. PROCURA VALOR (R$ X,XX)
            // ─────────────────────────────────────────────────────────────
            val regexValor = Regex("""R\$\s*(\d+)[,.](\d+)""")
            var valor: Double? = null
            
            for (texto in textos) {
                val match = regexValor.find(texto)
                if (match != null) {
                    val reais = match.groupValues[1].toIntOrNull() ?: 0
                    val centavos = match.groupValues[2].toIntOrNull() ?: 0
                    valor = reais + (centavos / 100.0)
                    if (valor >= 5.0) break // Valor válido encontrado
                }
            }
            
            // Se não encontrou valor ou é muito baixo, não é uma corrida válida
            if (valor == null || valor < 5.0) return null
            
            // ─────────────────────────────────────────────────────────────
            // 2. PROCURA TEMPO (X min ou X minutos)
            // ─────────────────────────────────────────────────────────────
            val regexTempo = Regex("""(\d+)\s*min""")
            var tempo: Int? = null
            
            for (texto in textos) {
                val match = regexTempo.find(texto)
                if (match != null) {
                    tempo = match.groupValues[1].toIntOrNull()
                    if (tempo != null && tempo > 0 && tempo < 120) break // Tempo válido
                }
            }
            
            // Se não encontrou tempo, usa estimativa baseada no valor
            if (tempo == null || tempo == 0) {
                tempo = (valor / 0.9).toInt() // Estimativa: R$ 0.90/min
                if (tempo < 5) tempo = 15 // Mínimo 15 min
            }
            
            // ─────────────────────────────────────────────────────────────
            // 3. CALCULA VALOR POR MINUTO
            // ─────────────────────────────────────────────────────────────
            val valorPorMinuto = valor / tempo
            
            // ─────────────────────────────────────────────────────────────
            // 4. DECISÃO: ACEITAR OU REJEITAR
            // ─────────────────────────────────────────────────────────────
            // Regra simples: aceita se R$/min >= 0.80
            val deveAceitar = valorPorMinuto >= 0.80
            
            val motivo = if (deveAceitar) {
                "Boa corrida! R$ %.2f/min".format(valorPorMinuto)
            } else {
                "Valor baixo: R$ %.2f/min".format(valorPorMinuto)
            }
            
            Log.d(TAG, "╔══════════════════════════════════════════════════╗")
            Log.d(TAG, "║ 📊 ANÁLISE COMPLETA                             ║")
            Log.d(TAG, "╚══════════════════════════════════════════════════╝")
            Log.d(TAG, "💰 Valor: R$ %.2f".format(valor))
            Log.d(TAG, "⏱️ Tempo: ${tempo} min")
            Log.d(TAG, "💵 R$/min: R$ %.2f".format(valorPorMinuto))
            Log.d(TAG, "🎯 Decisão: ${if (deveAceitar) "✅ ACEITAR" else "❌ REJEITAR"}")
            Log.d(TAG, "💬 Motivo: $motivo")
            
            return AnaliseSimples(
                deveAceitar = deveAceitar,
                motivo = motivo,
                valor = valor,
                tempo = tempo,
                valorPorMinuto = valorPorMinuto
            )
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erro na análise: ${e.message}")
            return null
        }
    }

    /**
     * Classe simples para resultado da análise
     */
    data class AnaliseSimples(
        val deveAceitar: Boolean,
        val motivo: String,
        val valor: Double,
        val tempo: Int,
        val valorPorMinuto: Double
    )

    /**
     * Extrai recursivamente TODO o texto da árvore de Views
     */
    private fun extractAllText(
        node: AccessibilityNodeInfo?,
        textos: MutableSet<String>,
        depth: Int = 0
    ) {
        if (node == null || depth > 15) return // Limitar profundidade
        
        try {
            // Texto do nó
            val nodeText = node.text?.toString()
            if (!nodeText.isNullOrEmpty() && nodeText != "null") {
                textos.add(nodeText)
            }
            
            // Content Description
            val contentDesc = node.contentDescription?.toString()
            if (!contentDesc.isNullOrEmpty() && contentDesc != "null") {
                textos.add(contentDesc)
            }
            
            // Hint Text (para EditText)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val hintText = node.hintText?.toString()
                if (!hintText.isNullOrEmpty() && hintText != "null") {
                    textos.add(hintText)
                }
            }
            
            // Tooltip Text (Android P+)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                val tooltipText = node.tooltipText?.toString()
                if (!tooltipText.isNullOrEmpty() && tooltipText != "null") {
                    textos.add(tooltipText)
                }
            }
            
            // Processar filhos recursivamente
            for (i in 0 until node.childCount) {
                try {
                    val child = node.getChild(i)
                    extractAllText(child, textos, depth + 1)
                    child?.recycle() // Liberar memória
                } catch (e: Exception) {
                    Log.w(TAG, "Erro ao processar filho $i: ${e.message}")
                }
            }
            
        } catch (e: Exception) {
            Log.w(TAG, "Erro ao extrair texto do nó (depth=$depth): ${e.message}")
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "⚠️ Serviço INTERROMPIDO")
    }

    override fun onDestroy() {
        super.onDestroy()
        overlayManager?.removerOverlay()
        overlayManager = null
        eventSink = null
        Log.d(TAG, "🛑 Serviço DESTRUÍDO")
    }
}