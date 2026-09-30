class RoommateContact {
  const RoommateContact({
    required this.authorName,
    required this.contactPreference,
    this.phone,
    this.zaloPhone,
  });

  factory RoommateContact.fromJson(Map<String, dynamic> json) {
    return RoommateContact(
      authorName: _requiredString(json['author_name'], 'author_name'),
      phone: _string(json['phone']),
      zaloPhone: _string(json['zalo_phone']),
      contactPreference: _requiredString(
        json['contact_preference'],
        'contact_preference',
      ),
    );
  }

  final String authorName;
  final String? phone;
  final String? zaloPhone;
  final String contactPreference;

  bool get hasPhone => phone != null;
  bool get hasZalo => zaloPhone != null;
}

String? _string(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

String _requiredString(dynamic value, String field) {
  final result = _string(value);
  if (result == null) {
    throw FormatException('Trường $field không hợp lệ.');
  }
  return result;
}
