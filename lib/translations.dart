import 'dart:ui' as ui;

class AppText {
  static String get _lang {
    final locale = ui.PlatformDispatcher.instance.locale.languageCode;
    return ['es', 'en'].contains(locale) ? locale : 'en';
  }

  static final Map<String, Map<String, String>> _strings = {
    'es': {
      // Pantalla Principal
      'app_title': 'Videocomprime',
      'pro_active': 'Pro Activo',
      'go_pro': 'Hazte Pro',
      'loading_file': 'Cargando archivo...',
      'select_video': 'Seleccionar Video',
      'compression_level': 'Nivel de compresión deseado:',
      'high_quality': 'Alta (1080p)',
      'medium_quality': 'Media (720p)',
      'low_quality': 'Ahorro (480p)',
      'file': 'Archivo:',
      'original_size': 'Tamaño original:',
      'processing': 'Procesando:',
      'starting_compression': 'Iniciando compresión...',
      'cancel_compression': 'Cancelar compresión',
      'compress_now': 'Comprimir Ahora',
      'select_video_hint': 'Selecciona un video arriba para habilitar el procesamiento',
      'success_title': '¡Video Comprimido con Éxito!',
      'final_size': 'Tamaño final:',
      'savings': 'Ahorro:',
      'save_share': 'Guardar o Compartir',
      'error_file': 'Error al acceder al archivo.',
      'compression_cancelled': 'Compresión cancelada',
      'error_process': 'Error al procesar el video',
      'share_text': 'Video comprimido con Videocomprime',
      
      // Pantalla de Pagos (Paywall)
      'paywall_title': 'Videocomprime Pro',
      'paywall_subtitle': 'Desbloquea todo el potencial',
      'feature_ads': 'Sin anuncios publicitarios',
      'feature_1080p': 'Compresión en Alta Calidad (1080p)',
      'feature_support': 'Procesamiento ilimitado',
      'loading_plans': 'Cargando planes...',
      'no_plans': 'No hay planes disponibles por ahora.',
      'continue_btn': 'Continuar',
      'restore': 'Restaurar compras',
      'no_restore': 'No se encontraron compras previas para restaurar.',
      'success_purchase': '¡Gracias por hacerte Pro!',
      'success_restore': 'Tus compras fueron restauradas exitosamente.',
      'terms_privacy': 'Términos y Privacidad',
    },
    'en': {
      // Pantalla Principal
      'app_title': 'VideoCompress',
      'pro_active': 'Pro Active',
      'go_pro': 'Go Pro',
      'loading_file': 'Loading file...',
      'select_video': 'Select Video',
      'compression_level': 'Desired compression level:',
      'high_quality': 'High (1080p)',
      'medium_quality': 'Medium (720p)',
      'low_quality': 'Low (480p)',
      'file': 'File:',
      'original_size': 'Original size:',
      'processing': 'Processing:',
      'starting_compression': 'Starting compression...',
      'cancel_compression': 'Cancel compression',
      'compress_now': 'Compress Now',
      'select_video_hint': 'Select a video above to enable processing',
      'success_title': 'Video Compressed Successfully!',
      'final_size': 'Final size:',
      'savings': 'Savings:',
      'save_share': 'Save or Share',
      'error_file': 'Error accessing the file.',
      'compression_cancelled': 'Compression cancelled',
      'error_process': 'Error processing video',
      'share_text': 'Video compressed with VideoCompress',
      
      // Pantalla de Pagos (Paywall)
      'paywall_title': 'VideoCompress Pro',
      'paywall_subtitle': 'Unlock the full potential',
      'feature_ads': 'No more ads',
      'feature_1080p': 'High Quality Compression (1080p)',
      'feature_support': 'Unlimited processing',
      'loading_plans': 'Loading plans...',
      'no_plans': 'No plans available right now.',
      'continue_btn': 'Continue',
      'restore': 'Restore purchases',
      'no_restore': 'No past purchases found to restore.',
      'success_purchase': 'Thank you for going Pro!',
      'success_restore': 'Your purchases were successfully restored.',
      'terms_privacy': 'Terms & Privacy',
    }
  };

  static String get(String key) {
    return _strings[_lang]?[key] ?? _strings['en']![key] ?? key;
  }
}
