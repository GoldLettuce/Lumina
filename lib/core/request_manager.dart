import 'dart:async';
import 'package:http/http.dart' as http;

/// Gestor centralizado de peticiones HTTP que:
/// - Limita las llamadas a 30 por minuto
/// - Usa una cola serializada para evitar concurrencia
/// - Implementa backoff exponencial al detectar errores HTTP 429
/// - Expone un método público `Future<http.Response> get(Uri url)`
class RequestManager {
  static final RequestManager _instance = RequestManager._();
  factory RequestManager() => _instance;

  // Constantes para configuración
  static const int _maxRequestsPerMinute = 30;
  static const int _maxRetries = 4;
  static const int _maxBackoffSeconds = 8;

  // Cliente HTTP
  final http.Client _client = http.Client();

  // Contador de peticiones por minuto
  int _requestCount = 0;

  // Timer que reinicia el contador cada 60 segundos
  Timer? _resetTimer;

  // Future para encadenar las peticiones serialmente
  Future _lastRequest = Future.value();

  // Delay para backoff exponencial
  int _backoffDelay = 1;

  // Constructor privado que inicia el timer
  RequestManager._() {
    _startResetTimer();
  }

  /// Inicia el timer que reinicia el contador cada 60 segundos
  void _startResetTimer() {
    _resetTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _requestCount = 0;
      _backoffDelay = 1; // Reset backoff delay
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

    // Log de la petición
    print('[HTTP][GET] $url');

    // Realiza la petición con reintentos
    return await _performRequestWithRetry(url);
  }

  /// Realiza la petición con reintentos en caso de error 429
  Future<http.Response> _performRequestWithRetry(Uri url, {int retryCount = 0}) async {
    try {
      final response = await _client.get(url);

      // Si es exitosa, resetea el backoff delay e incrementa el contador
      if (response.statusCode == 200) {
        _backoffDelay = 1;
        _requestCount++;
        return response;
      }

      // Si es error 429 (rate limited)
      if (response.statusCode == 429 && retryCount < _maxRetries) {
        // Incrementa el contador también para reintentos
        _requestCount++;
        
        final delay = _backoffDelay;
        print('[HTTP][429] Rate limited. Retrying in ${delay}s');
        
        await Future.delayed(Duration(seconds: delay));
        
        // Duplica el delay (máximo 8 segundos)
        _backoffDelay = (_backoffDelay * 2).clamp(1, _maxBackoffSeconds);
        
        // Reintenta la petición
        return await _performRequestWithRetry(url, retryCount: retryCount + 1);
      }

      // Si es otro error, lanza excepción
      throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');

    } catch (e) {
      print('[HTTP][ERROR] $e');
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