import 'dart:async';
import 'package:http/http.dart' as http;

/// Gestor centralizado de peticiones HTTP que:
/// - Limita las llamadas a 30 por minuto
/// - Usa una cola serializada para evitar concurrencia
/// - Espera 1 minuto y reintenta (máx. 4 veces) en caso de HTTP 429
/// - Expone un método público `Future<http.Response> get(Uri url)`
class RequestManager {
  static final RequestManager _instance = RequestManager._();
  factory RequestManager() => _instance;

  // Constantes para configuración
  static const int _maxRequestsPerMinute = 30;
  static const int _maxRetries = 4;

  // Cliente HTTP
  final http.Client _client = http.Client();

  // Contador de peticiones por minuto
  int _requestCount = 0;

  // Timer que reinicia el contador cada 60 segundos
  Timer? _resetTimer;

  // Future para encadenar las peticiones serialmente
  Future _lastRequest = Future.value();

  // Constructor privado que inicia el timer
  RequestManager._() {
    _startResetTimer();
  }

  /// Inicia el timer que reinicia el contador cada 60 segundos
  void _startResetTimer() {
    _resetTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _requestCount = 0;
    });
  }

  /// Realiza una petición GET con rate limiting y backoff exponencial
  Future<http.Response> get(Uri url) async {
    // Encadena la ejecución con la última petición
    _lastRequest = _lastRequest.then((_) async {
      return await _executeGet(url);
    });

    return await _lastRequest;
  }

  /// Ejecuta la petición GET con todas las validaciones
  Future<http.Response> _executeGet(Uri url) async {
    // Espera si se ha alcanzado el límite de peticiones
    while (_requestCount >= _maxRequestsPerMinute) {
      await Future.delayed(const Duration(seconds: 1));
    }

    // Realiza la petición con reintentos
    return await _performRequestWithRetry(url);
  }

  /// Realiza la petición con reintentos en caso de error 429
  Future<http.Response> _performRequestWithRetry(Uri url, {int retryCount = 0}) async {
    try {
      final response = await _client.get(url);

      // Si es exitosa, incrementa el contador
      if (response.statusCode == 200) {
        _requestCount++;
        return response;
      }

      // Si es error 429 (rate limited)
      if (response.statusCode == 429) {
        
        // Espera 1 minuto antes de reintentar
        await Future.delayed(const Duration(minutes: 1));
        
        // Reintenta la petición si no hemos excedido el límite
        if (retryCount < _maxRetries) {
          return await _performRequestWithRetry(url, retryCount: retryCount + 1);
        } else {
          return response; // Devuelve la respuesta 429 sin lanzar excepción
        }
      }

      // Si es otro error, lanza excepción
      throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');

    } catch (e) {
      rethrow;
    }
  }

  /// Dispone el cliente HTTP y el timer
  void dispose() {
    _client.close();
    _resetTimer?.cancel();
  }
}

/// Excepción personalizada para errores HTTP
class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
} 