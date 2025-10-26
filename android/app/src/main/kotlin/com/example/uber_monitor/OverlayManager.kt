// ============================================================================
// ARQUIVO: android/app/src/main/kotlin/com/example/uber_monitor/OverlayManager.kt
// VERSÃO: v5.2 - CORRIGIDO: Evita pisca-pisca + controle melhor de atualização
// ============================================================================

package com.example.uber_monitor

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.abs

class OverlayManager(private val context: Context) {
    
    companion object {
        private const val TAG = "OverlayManager"
    }
    
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var isShowing = false
    private val handler = Handler(Looper.getMainLooper())
    
    // Controle para não ficar atualizando
    private var ultimoValor: Double = 0.0
    private var ultimoTempo: Long = 0
    private val INTERVALO_MINIMO_MS = 3000
    
    // Controle do timer de auto-fechar
    private var autoCloseRunnable: Runnable? = null
    
    // Evita múltiplas chamadas simultâneas
    private var isUpdating = false
    
    init {
        windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        Log.d(TAG, "✅ OverlayManager inicializado")
    }
    
    fun mostrarRecomendacao(
        deveAceitar: Boolean,
        motivo: String,
        valorCorrida: Double,
        tempoTotal: Int,
        valorPorMinuto: Double
    ) {
        handler.post {
            try {
                // ⚡ EVITA SOBREPOSIÇÃO DE CHAMADAS
                if (isUpdating) {
                    Log.d(TAG, "⏭️ Já está atualizando - ignorando chamada duplicada")
                    return@post
                }
                
                isUpdating = true
                
                val agora = System.currentTimeMillis()
                
                // ✅ MELHOR CONTROLE: Só ignora se for EXATAMENTE a mesma corrida
                if (isShowing && 
                    abs(valorCorrida - ultimoValor) < 0.1 &&  // Tolerância menor
                    (agora - ultimoTempo) < INTERVALO_MINIMO_MS) {
                    Log.d(TAG, "⏭️ Ignorando atualização (mesma corrida)")
                    isUpdating = false
                    return@post
                }
                
                ultimoValor = valorCorrida
                ultimoTempo = agora
                
                Log.d(TAG, "╔══════════════════════════════════════════════════╗")
                Log.d(TAG, "║ 🎨 MOSTRANDO OVERLAY COMPACTO                   ║")
                Log.d(TAG, "║ Valor: R$ %.2f | Tempo: %dmin".format(valorCorrida, tempoTotal))
                Log.d(TAG, "╚══════════════════════════════════════════════════╝")
                
                // ⚡ ATUALIZA EM VEZ DE RECRIAR (se já está mostrando)
                if (isShowing && overlayView != null) {
                    atualizarOverlayExistente(deveAceitar, valorCorrida, tempoTotal, valorPorMinuto)
                } else {
                    criarNovoOverlay(deveAceitar, valorCorrida, tempoTotal, valorPorMinuto)
                }
                
                isUpdating = false
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ ERRO: ${e.message}", e)
                isUpdating = false
            }
        }
    }
    
    private fun criarNovoOverlay(
        deveAceitar: Boolean,
        valorCorrida: Double,
        tempoTotal: Int,
        valorPorMinuto: Double
    ) {
        try {
            removerOverlay()
            
            overlayView = criarOverlayCompacto(
                deveAceitar,
                valorCorrida,
                tempoTotal,
                valorPorMinuto
            )
            
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                },
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            )
            
            params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            params.y = dpToPx(80)
            
            configurarGestoArraystar(overlayView!!, params)
            
            windowManager?.addView(overlayView, params)
            isShowing = true
            
            Log.d(TAG, "✅ NOVO Overlay exibido!")
            
            // Auto-fechar após 8 segundos
            autoCloseRunnable = Runnable { 
                Log.d(TAG, "⏰ Auto-fechamento após 8 segundos")
                removerOverlay() 
            }
            handler.postDelayed(autoCloseRunnable!!, 8000)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ ERRO ao criar overlay: ${e.message}", e)
        }
    }
    
    private fun atualizarOverlayExistente(
        deveAceitar: Boolean,
        valorCorrida: Double,
        tempoTotal: Int,
        valorPorMinuto: Double
    ) {
        try {
            // Cancela o auto-fechar anterior
            autoCloseRunnable?.let { handler.removeCallbacks(it) }
            
            // Atualiza o conteúdo do overlay existente
            val novoOverlay = criarOverlayCompacto(deveAceitar, valorCorrida, tempoTotal, valorPorMinuto)
            
            // Substitui a view mantendo a mesma posição
            windowManager?.removeView(overlayView)
            overlayView = novoOverlay
            
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                },
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            )
            
            params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            params.y = dpToPx(80)
            
            configurarGestoArraystar(overlayView!!, params)
            windowManager?.addView(overlayView, params)
            
            Log.d(TAG, "🔄 Overlay ATUALIZADO (sem piscar)")
            
            // Reinicia o timer de auto-fechar
            autoCloseRunnable = Runnable { 
                Log.d(TAG, "⏰ Auto-fechamento após 8 segundos")
                removerOverlay() 
            }
            handler.postDelayed(autoCloseRunnable!!, 8000)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ ERRO ao atualizar overlay: ${e.message}", e)
            // Fallback: cria novo overlay
            criarNovoOverlay(deveAceitar, valorCorrida, tempoTotal, valorPorMinuto)
        }
    }
    
    private fun configurarGestoArraystar(view: View, params: WindowManager.LayoutParams) {
        var initialX = 0f
        var initialY = 0f
        var touchX = 0f
        var touchY = 0f
        var moved = false
        
        view.setOnTouchListener { v, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    // Cancela auto-fechar quando usuário interage
                    autoCloseRunnable?.let { handler.removeCallbacks(it) }
                    
                    initialX = params.x.toFloat()
                    initialY = params.y.toFloat()
                    touchX = event.rawX
                    touchY = event.rawY
                    moved = false
                    true
                }
                
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = event.rawX - touchX
                    val deltaY = event.rawY - touchY
                    
                    // Marca que houve movimento
                    if (abs(deltaX) > 10 || abs(deltaY) > 10) {
                        moved = true
                    }
                    
                    params.x = (initialX + deltaX).toInt()
                    params.y = (initialY + deltaY).toInt()
                    
                    windowManager?.updateViewLayout(view, params)
                    true
                }
                
                MotionEvent.ACTION_UP -> {
                    val deltaX = event.rawX - touchX
                    val deltaY = event.rawY - touchY
                    
                    // Se arrastou muito pra esquerda ou direita
                    if (abs(deltaX) > 150) {
                        Log.d(TAG, "👆 Arrastou ${deltaX.toInt()}px - FECHANDO")
                        removerOverlay()
                        return@setOnTouchListener true
                    }
                    
                    // Se foi só um toque (não arrastou muito)
                    if (!moved || (abs(deltaX) < 20 && abs(deltaY) < 20)) {
                        Log.d(TAG, "👆 Toque detectado - FECHANDO")
                        removerOverlay()
                        return@setOnTouchListener true
                    }
                    
                    // Reinicia auto-fechar após interação
                    autoCloseRunnable = Runnable { 
                        Log.d(TAG, "⏰ Auto-fechamento após interação")
                        removerOverlay() 
                    }
                    handler.postDelayed(autoCloseRunnable!!, 5000) // 5 segundos após interação
                    
                    true
                }
                
                else -> false
            }
        }
    }
    
    // ... (o restante do código criarOverlayCompacto, criarMetricaCompacta permanece igual)
    private fun criarOverlayCompacto(
        deveAceitar: Boolean,
        valorCorrida: Double,
        tempoTotal: Int,
        valorPorMinuto: Double
    ): View {
        
        val corBorda = if (deveAceitar) "#00C853" else "#E53935"
        val corVerde = Color.parseColor("#00C853")
        val corAmarela = Color.parseColor("#FFC107")
        
        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(20), dpToPx(10), dpToPx(20), dpToPx(10))
        }
        
        val cardContainer = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
        }
        
        // BOTÃO X - COM CLICK LISTENER DIRETO
        val btnFechar = TextView(context).apply {
            text = "✕"
            textSize = 24f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(dpToPx(12), dpToPx(8), dpToPx(12), dpToPx(8))
            
            background = GradientDrawable().apply {
                setColor(Color.parseColor(corBorda))
                cornerRadius = dpToPx(20).toFloat()
            }
            
            // IMPORTANTE: Remove o listener de arrastar do botão X
            isClickable = true
            isFocusable = true
            
            setOnClickListener {
                Log.d(TAG, "❌ Botão X CLICADO - FECHANDO")
                removerOverlay()
            }
        }
        
        val headerContainer = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.END
            setPadding(dpToPx(4), dpToPx(4), dpToPx(4), 0)
        }
        headerContainer.addView(btnFechar)
        
        cardContainer.addView(headerContainer)
        
        // Card branco
        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(20), dpToPx(12), dpToPx(20), dpToPx(16))
            
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dpToPx(16).toFloat()
                setStroke(dpToPx(4), Color.parseColor(corBorda))
            }
            
            elevation = dpToPx(12).toFloat()
        }
        
        // Métricas
        val linhaMetricas = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(12)
            }
        }
        
        val valorPorKm = valorCorrida / (tempoTotal * 0.6)
        
        linhaMetricas.addView(criarMetricaCompacta("R\$/Km", "%.2f".format(valorPorKm), corVerde))
        linhaMetricas.addView(View(context).apply {
            layoutParams = LinearLayout.LayoutParams(dpToPx(1), dpToPx(40)).apply {
                setMargins(dpToPx(16), 0, dpToPx(16), 0)
            }
            setBackgroundColor(Color.parseColor("#E0E0E0"))
        })
        
        linhaMetricas.addView(criarMetricaCompacta("R\$/Min", "%.2f".format(valorPorMinuto), corAmarela))
        linhaMetricas.addView(View(context).apply {
            layoutParams = LinearLayout.LayoutParams(dpToPx(1), dpToPx(40)).apply {
                setMargins(dpToPx(16), 0, dpToPx(16), 0)
            }
            setBackgroundColor(Color.parseColor("#E0E0E0"))
        })
        
        linhaMetricas.addView(criarMetricaCompacta("Nota", if (deveAceitar) "4.86" else "3.20", corVerde))
        
        card.addView(linhaMetricas)
        
        // Info da viagem
        val linhaInfo = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        
        linhaInfo.addView(TextView(context).apply {
            text = "🚗"
            textSize = 16f
            setPadding(0, 0, dpToPx(8), 0)
        })
        
        linhaInfo.addView(TextView(context).apply {
            text = "${tempoTotal}min"
            textSize = 15f
            setTextColor(Color.BLACK)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        })
        
        linhaInfo.addView(TextView(context).apply {
            text = " • "
            textSize = 15f
            setTextColor(Color.parseColor("#666666"))
        })
        
        val distancia = tempoTotal * 0.6
        linhaInfo.addView(TextView(context).apply {
            text = "%.2fkm".format(distancia)
            textSize = 15f
            setTextColor(Color.BLACK)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        })
        
        card.addView(linhaInfo)
        
        cardContainer.addView(card)
        container.addView(cardContainer)
        
        return container
    }
    
    private fun criarMetricaCompacta(label: String, valor: String, cor: Int): LinearLayout {
        return LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            
            addView(TextView(context).apply {
                text = label
                textSize = 12f
                setTextColor(Color.parseColor("#999999"))
                gravity = Gravity.CENTER
            })
            
            addView(LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
                
                addView(View(context).apply {
                    layoutParams = LinearLayout.LayoutParams(dpToPx(4), dpToPx(28)).apply {
                        setMargins(0, dpToPx(4), dpToPx(6), 0)
                    }
                    setBackgroundColor(cor)
                })
                
                addView(TextView(context).apply {
                    text = valor
                    textSize = 22f
                    setTextColor(Color.BLACK)
                    typeface = android.graphics.Typeface.DEFAULT_BOLD
                    gravity = Gravity.CENTER
                })
            })
        }
    }
    
    fun removerOverlay() {
        handler.post {
            try {
                // Cancela o timer de auto-fechar
                autoCloseRunnable?.let { handler.removeCallbacks(it) }
                autoCloseRunnable = null
                
                if (isShowing && overlayView != null) {
                    windowManager?.removeView(overlayView)
                    overlayView = null
                    isShowing = false
                    isUpdating = false
                    Log.d(TAG, "🗑️ Overlay REMOVIDO")
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Erro ao remover: ${e.message}")
                isUpdating = false
            }
        }
    }
    
    private fun dpToPx(dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            context.resources.displayMetrics
        ).toInt()
    }
    
    fun isOverlayShowing(): Boolean = isShowing
}