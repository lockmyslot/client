class ApiResponse<T> {
  final T data;
  final Map<String, dynamic>? meta;

  const ApiResponse({required this.data, this.meta});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    final rawData = json['data'] ?? json;
    final metaData = json['meta'] as Map<String, dynamic>?;

    return ApiResponse<T>(data: fromJsonT(rawData), meta: metaData);
  }

  factory ApiResponse.fromListJson(
    Map<String, dynamic> json,
    T Function(List<dynamic> list) fromListT,
  ) {
    final rawData = json['data'] is List ? json['data'] : json;
    final metaData = json['meta'] as Map<String, dynamic>?;

    return ApiResponse<T>(
      data: fromListT(rawData as List<dynamic>),
      meta: metaData,
    );
  }
}
