// ============================================================================
// ARQUIVO: android/app/src/main/kotlin/com/example/uber_monitor/MainActivity.kt
// VERSÃO: v3.0 FINAL - COM OVERLAY NATIVO
// ============================================================================

package com.example.uber_monitor

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import android.util.Log
import android.net.Uri
import android.os.Build

class MainActivity: FlutterActivity() {
    
    companion object {
        private const val TAG = "MainActivity"
        private const val METHOD_CHANNEL = "com.example.uber_monitor/accessibility"
        private const val EVENT_CHANNEL = "com.example.uber_monitor/accessibility_events"
        private const val OVERLAY_CHANNEL = "com.example.uber_monitor/overlay"
        private const val OVERLAY_PERMISSION_REQUEST_CODE = 1001
    }
    
    private var overlayManager: OverlayManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Inicializa o OverlayManager
        overlayManager = OverlayManager(applicationContext)
        
        Log.d(TAG, "╔════════════════════════════════════════════════════╗")
        Log.d(TAG, "║ 🔧 Configurando Flutter Engine v3.0              ║")
        Log.d(TAG, "╚════════════════════════════════════════════════════╝")
        
        // ======================================================================
        // METHOD CHANNEL - Accessibility
        // ======================================================================
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    try {
                        val hasPermission = isAccessibilityServiceEnabled()
                        Log.d(TAG, "✅ Permissão de Acessibilidade: $hasPermission")
                        result.success(hasPermission)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Erro ao verificar permissão: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                
                "requestPermission" -> {
                    try {
                        Log.d(TAG, "🔓 Abrindo configurações de acessibilidade...")
                        openAccessibilitySettings()
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Erro ao abrir configurações: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                
                else -> {
                    Log.w(TAG, "⚠️ Método desconhecido: ${call.method}")
                    result.notImplemented()
                }
            }
        }
        
        // ======================================================================
        // EVENT CHANNEL - Stream de eventos do Accessibility Service
        // ======================================================================
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.d(TAG, "📡 Stream INICIADO")
                UberAccessibilityService.setEventSink(events)
            }

            override fun onCancel(arguments: Any?) {
                Log.d(TAG, "📡 Stream CANCELADO")
                UberAccessibilityService.setEventSink(null)
            }
        })
        
        // ======================================================================
        // METHOD CHANNEL - Overlay Nativo
        // ======================================================================
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OVERLAY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    try {
                        val hasPermission = checkOverlayPermission()
                        Log.d(TAG, "🔍 Permissão de Overlay: $hasPermission")
                        result.success(hasPermission)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Erro ao verificar overlay: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                
                "requestOverlayPermission" -> {
                    try {
                        Log.d(TAG, "🔓 Solicitando permissão de overlay...")
                        requestOverlayPermission()
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Erro ao solicitar overlay: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                
                "showNativeOverlay" -> {
                    try {
                        val args = call.arguments as? Map<String, Any>
                        
                        if (args == null) {
                            Log.e(TAG, "❌ Argumentos nulos!")
                            result.error("NULL_ARGS", "Argumentos não fornecidos", null)
                            return@setMethodCallHandler
                        }
                        
                        val deveAceitar = args["deveAceitar"] as? Boolean ?: false
                        val motivo = args["motivo"] as? String ?: "Sem motivo"
                        val valorCorrida = (args["valorCorrida"] as? Number)?.toDouble() ?: 0.0
                        val tempoTotal = (args["tempoTotal"] as? Number)?.toInt() ?: 0
                        val valorPorMinuto = (args["valorPorMinuto"] as? Number)?.toDouble() ?: 0.0
                        
                        Log.d(TAG, "╔════════════════════════════════════════════════════╗")
                        Log.d(TAG, "║ 🎨 CHAMANDO OVERLAY NATIVO                        ║")
                        Log.d(TAG, "╚════════════════════════════════════════════════════╝")
                        Log.d(TAG, "   Decisão: ${if (deveAceitar) "✅ ACEITAR" else "❌ REJEITAR"}")
                        Log.d(TAG, "   Motivo: $motivo")
                        Log.d(TAG, "   Valor: R$ %.2f".format(valorCorrida))
                        Log.d(TAG, "   Tempo: $tempoTotal min")
                        Log.d(TAG, "   Valor/min: R$ %.2f".format(valorPorMinuto))
                        
                        overlayManager?.mostrarRecomendacao(
                            deveAceitar = deveAceitar,
                            motivo = motivo,
                            valorCorrida = valorCorrida,
                            tempoTotal = tempoTotal,
                            valorPorMinuto = valorPorMinuto
                        )
                        
                        result.success(true)
                        
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ ERRO ao mostrar overlay: ${e.message}", e)
                        e.printStackTrace()
                        result.error("ERROR", e.message, e.stackTraceToString())
                    }
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        Log.d(TAG, "✅ Flutter Engine configurado com sucesso")
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedService = "${packageName}/${UberAccessibilityService::class.java.canonicalName}"
        
        return try {
            val enabledServices = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: ""
            
            val accessibilityEnabled = Settings.Secure.getInt(
                contentResolver,
                Settings.Secure.ACCESSIBILITY_ENABLED,
                0
            ) == 1
            
            enabledServices.contains(expectedService) && accessibilityEnabled
            
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao verificar serviço: ${e.message}", e)
            false
        }
    }

    private fun openAccessibilitySettings() {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao abrir configurações: ${e.message}", e)
            throw e
        }
    }

    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                ).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == OVERLAY_PERMISSION_REQUEST_CODE) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (Settings.canDrawOverlays(this)) {
                    Log.d(TAG, "✅ Permissão de overlay concedida!")
                } else {
                    Log.w(TAG, "⚠️ Permissão de overlay negada")
                }
            }
        }
    }
    
    override fun onDestroy() {
        overlayManager?.removerOverlay()
        overlayManager = null
        super.onDestroy()
    }
}