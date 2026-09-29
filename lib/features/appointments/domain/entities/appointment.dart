class Appointment {
  const Appointment({
    required this.id,
    required this.roomId,
    required this.landlordId,
    required this.tenantName,
    required this.tenantPhone,
    required this.bookingDate,
    required this.timeSlot,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.tenantId,
    this.tenantZalo,
    this.tenantEmail,
    this.note,
    this.reminderSentAt,
    this.roomTitle,
    this.roomImage,
    this.roomPrice,
    this.landlordName,
    this.landlordPhone,
    this.landlordZalo,
  });
  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: _requiredString(json, 'id'),
    roomId: _requiredString(json, 'room_id'),
    landlordId: _requiredString(json, 'landlord_id'),
    tenantId: _string(json['tenant_id']),
    tenantName: _requiredString(json, 'tenant_name'),
    tenantPhone: _requiredString(json, 'tenant_phone'),
    tenantZalo: _string(json['tenant_zalo']),
    tenantEmail: _string(json['tenant_email']),
    bookingDate: _requiredDate(json, 'booking_date'),
    timeSlot: _requiredString(json, 'time_slot'),
    note: _string(json['note']),
    status: _requiredString(json, 'status'),
    reminderSentAt: _date(json['reminder_sent_at']),
    createdAt: _requiredDate(json, 'created_at'),
    updatedAt: _requiredDate(json, 'updated_at'),
    roomTitle: _string(json['room_title']),
    roomImage: _string(json['room_image']),
    roomPrice: (json['room_price'] as num?)?.toInt(),
    landlordName: _string(json['landlord_name']),
    landlordPhone: _string(json['landlord_phone']),
    landlordZalo: _string(json['landlord_zalo']),
  );
  final String id,
      roomId,
      landlordId,
      tenantName,
      tenantPhone,
      timeSlot,
      status;
  final String? tenantId, tenantZalo, tenantEmail, note;
  final DateTime bookingDate, createdAt, updatedAt;
  final DateTime? reminderSentAt;
  final String? roomTitle, roomImage, landlordName, landlordPhone, landlordZalo;
  final int? roomPrice;
  bool get canTenantChange => status == 'PENDING' || status == 'CONFIRMED';
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = _string(json[key]);
  if (value == null) throw FormatException('Trường $key không hợp lệ.');
  return value;
}

String? _string(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = _date(json[key]);
  if (value == null) throw FormatException('Trường ngày $key không hợp lệ.');
  return value;
}

DateTime? _date(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;
