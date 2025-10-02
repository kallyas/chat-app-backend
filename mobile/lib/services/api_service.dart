import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_LoggingInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
  }

  // GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Upload file
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    T Function(dynamic)? fromJson,
    Function(int, int)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?additionalData,
      });

      final response = await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onProgress,
      );
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // Download file
  Future<ApiResponse<String>> downloadFile(
    String endpoint,
    String savePath, {
    Function(int, int)? onProgress,
  }) async {
    try {
      await _dio.download(
        endpoint,
        savePath,
        onReceiveProgress: onProgress,
      );
      return ApiResponse.success(
        message: 'File downloaded successfully',
        data: savePath,
      );
    } catch (e) {
      return _handleError<String>(e);
    }
  }

  // Response handler
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      return ApiResponse.fromJson(response.data, fromJson);
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
  }

  // Error handler
  ApiResponse<T> _handleError<T>(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiResponse.error(
            message: 'Request timeout. Please try again.',
            code: 'TIMEOUT',
          );

        case DioExceptionType.connectionError:
          return ApiResponse.error(
            message: 'Network error. Please check your connection.',
            code: 'NETWORK_ERROR',
          );

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;

          if (statusCode == 401) {
            return ApiResponse.error(
              message: 'Unauthorized access. Please login again.',
              code: 'UNAUTHORIZED',
            );
          }

          if (responseData is Map<String, dynamic>) {
            return ApiResponse.fromJson(responseData, null);
          }

          return ApiResponse.error(
            message: 'Server error (${statusCode ?? 'Unknown'})',
            code: 'SERVER_ERROR',
          );

        default:
          return ApiResponse.error(
            message: 'An unexpected error occurred.',
            code: 'UNKNOWN_ERROR',
          );
      }
    }

    return ApiResponse.error(
      message: error.toString(),
      code: 'GENERAL_ERROR',
    );
  }

  // Clear auth tokens when needed
  void clearAuthTokens() {
    // This will be handled by the AuthInterceptor
  }
}

// Authentication Interceptor
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageService.getAuthToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final responseData = err.response?.data;

      // Check if token has been invalidated (password change, etc.)
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message']?.toString().toLowerCase() ?? '';
        if (message.contains('invalidated') || message.contains('token has been')) {
          // Token was invalidated, clear everything and don't retry
          await StorageService.clearAuthTokens();
          print('⚠️ Token invalidated by server - user must login again');
          handler.next(err);
          return;
        }
      }

      // Try to refresh token
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken != null) {
        try {
          final dio = Dio(BaseOptions(
            baseUrl: ApiConfig.baseUrl,
          ));

          final response = await dio.post(
            ApiConfig.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200) {
            final newToken = response.data['data']['token'];
            final newRefreshToken = response.data['data']['refreshToken'];

            await StorageService.saveAuthTokens(
              token: newToken,
              refreshToken: newRefreshToken,
            );

            // Retry the original request
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await dio.request(
              err.requestOptions.path,
              options: Options(
                method: err.requestOptions.method,
                headers: err.requestOptions.headers,
              ),
              data: err.requestOptions.data,
              queryParameters: err.requestOptions.queryParameters,
            );

            handler.resolve(retryResponse);
            return;
          }
        } catch (e) {
          // Refresh failed, clear tokens
          await StorageService.clearAuthTokens();
        }
      } else {
        // No refresh token available, clear tokens
        await StorageService.clearAuthTokens();
      }
    }
    handler.next(err);
  }
}

// Logging Interceptor
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('🚀 REQUEST: ${options.method} ${options.path}');
    print('📝 Data: ${options.data}');
    print('📝 Query: ${options.queryParameters}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
    print('📄 Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ ERROR: ${err.response?.statusCode} ${err.requestOptions.path}');
    print('📄 Error Data: ${err.response?.data}');
    handler.next(err);
  }
}

// Error Interceptor
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Add any global error handling here
    handler.next(err);
  }
}