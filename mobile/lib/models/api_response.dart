class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;
  final String? code;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.code,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: (json['errors'] as List<dynamic>?)?.cast<String>(),
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'errors': errors,
      'code': code,
    };
  }

  // Success response factory
  factory ApiResponse.success({
    required String message,
    T? data,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
    );
  }

  // Error response factory
  factory ApiResponse.error({
    required String message,
    List<String>? errors,
    String? code,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      errors: errors,
      code: code,
    );
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, data: $data)';
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    final total = json['total'] ?? 0;
    final limit = json['limit'] ?? 20;
    final totalPages = json['totalPages'] ?? (total / limit).ceil();
    final page = json['page'] ?? 1;

    return PaginationInfo(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNext: json['hasNext'] ?? (page < totalPages),
      hasPrev: json['hasPrev'] ?? (page > 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
      'hasNext': hasNext,
      'hasPrev': hasPrev,
    };
  }

  @override
  String toString() {
    return 'PaginationInfo(page: $page, limit: $limit, total: $total, totalPages: $totalPages)';
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final PaginationInfo pagination;

  const PaginatedResponse({
    required this.items,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
    String itemsKey,
  ) {
    final itemsJson = json[itemsKey] as List<dynamic>? ?? [];
    final items = itemsJson
        .map((item) => fromJsonT(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse<T>(
      items: items,
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }

  Map<String, dynamic> toJson(String itemsKey) {
    return {
      itemsKey: items,
      'pagination': pagination.toJson(),
    };
  }

  @override
  String toString() {
    return 'PaginatedResponse(items: ${items.length}, pagination: $pagination)';
  }
}

// Auth response models
class AuthResponse {
  final String token;
  final String refreshToken;
  final dynamic user;

  const AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      refreshToken: json['refreshToken'],
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'user': user,
    };
  }
}

class RefreshTokenResponse {
  final String token;
  final String refreshToken;

  const RefreshTokenResponse({
    required this.token,
    required this.refreshToken,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      token: json['token'],
      refreshToken: json['refreshToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
    };
  }
}

// Error response model
class ApiError implements Exception {
  final String message;
  final String? code;
  final List<String>? errors;
  final int? statusCode;

  const ApiError({
    required this.message,
    this.code,
    this.errors,
    this.statusCode,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] ?? 'An error occurred',
      code: json['code'],
      errors: (json['errors'] as List<dynamic>?)?.cast<String>(),
      statusCode: json['statusCode'],
    );
  }

  factory ApiError.network() {
    return const ApiError(
      message: 'Network error. Please check your connection.',
      code: 'NETWORK_ERROR',
    );
  }

  factory ApiError.timeout() {
    return const ApiError(
      message: 'Request timeout. Please try again.',
      code: 'TIMEOUT',
    );
  }

  factory ApiError.unauthorized() {
    return const ApiError(
      message: 'Unauthorized access. Please login again.',
      code: 'UNAUTHORIZED',
      statusCode: 401,
    );
  }

  factory ApiError.server() {
    return const ApiError(
      message: 'Server error. Please try again later.',
      code: 'SERVER_ERROR',
      statusCode: 500,
    );
  }

  @override
  String toString() {
    return 'ApiError(message: $message, code: $code, statusCode: $statusCode)';
  }
}