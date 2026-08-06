class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message ?? 'Operación exitosa',
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    if (json['success'] == true) {
      return ApiResponse.success(
        fromJsonT(json['data']),
        message: json['message'],
      );
    } else {
      return ApiResponse.error(
        json['message'] ?? 'Error desconocido',
        statusCode: json['status_code'],
      );
    }
  }
}