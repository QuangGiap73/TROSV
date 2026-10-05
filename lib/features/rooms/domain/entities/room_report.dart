enum RoomReportType {
  roomNotExist('ROOM_NOT_EXIST', 'Phòng không tồn tại'),
  wrongPrice('WRONG_PRICE', 'Giá phòng không chính xác'),
  wrongPhotos('WRONG_PHOTOS', 'Hình ảnh không đúng thực tế'),
  rented('RENTED', 'Phòng đã được thuê'),
  wrongLocation('WRONG_LOCATION', 'Sai vị trí hoặc địa chỉ'),
  hiddenFee('HIDDEN_FEE', 'Có chi phí phát sinh không công khai'),
  fraud('FRAUD', 'Có dấu hiệu lừa đảo'),
  other('OTHER', 'Lý do khác');

  const RoomReportType(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

class RoomReportRequest {
  const RoomReportRequest({required this.type, this.description});

  final RoomReportType type;
  final String? description;

  Map<String, dynamic> toJson() => {
    'type': type.apiValue,
    if (description?.trim().isNotEmpty == true)
      'description': description!.trim(),
  };
}

class RoomReport {
  const RoomReport({
    required this.id,
    required this.reporterId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.roomId,
    this.description,
    this.resolvedBy,
    this.resolvedAt,
  });

  factory RoomReport.fromJson(Map<String, dynamic> json) {
    return RoomReport(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      roomId: json['room_id'] as String?,
      type: json['type'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: _date(json['resolved_at']),
      createdAt: _date(json['created_at']) ?? DateTime.now(),
    );
  }

  final String id;
  final String reporterId;
  final String? roomId;
  final String type;
  final String? description;
  final String status;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  static DateTime? _date(dynamic value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}
