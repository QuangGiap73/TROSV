class RoommatePost {
  const RoommatePost({
    required this.id,
    required this.postType,
    required this.title,
    required this.description,
    required this.province,
    required this.district,
    required this.budgetPerPerson,
    required this.moveInDate,
    required this.desiredRoommates,
    required this.currentMembers,
    required this.genderPreference,
    required this.contactPreference,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    this.ward,
    this.addressHint,
    this.totalRoomPrice,
    this.depositPerPerson,
    this.authorGender,
    this.universityOrWork,
    this.roomId,
    this.rejectionReason,
    this.compatibilityScore,
    this.isOwner = false,
    this.contactLocked = true,
    this.viewsCount = 0,
    this.lifestyleTags = const [],
    this.lifestyleTraits = const {},
    this.mediaUrls = const [],
    this.compatibilityHighlights = const [],
  });

  factory RoommatePost.fromJson(Map<String, dynamic> json) {
    return RoommatePost(
      id: _requiredString(json, 'id'),
      postType: _requiredString(json, 'post_type'),
      title: _requiredString(json, 'title'),
      description: _requiredString(json, 'description'),
      province: _string(json['province']) ?? 'Hà Nội',
      district: _requiredString(json, 'district'),
      ward: _string(json['ward']),
      addressHint: _string(json['address_hint']),
      budgetPerPerson: _int(json['budget_per_person']),
      totalRoomPrice: _nullableInt(json['total_room_price']),
      depositPerPerson: _nullableInt(json['deposit_per_person']),
      moveInDate: _requiredDate(json, 'move_in_date'),
      desiredRoommates: _int(json['desired_roommates']),
      currentMembers: _int(json['current_members']),
      authorGender: _string(json['author_gender']),
      universityOrWork: _string(json['university_or_work']),
      genderPreference: _string(json['gender_preference']) ?? 'ANY',
      contactPreference: _string(json['contact_preference']) ?? 'BOTH',
      lifestyleTags: _stringList(json['lifestyle_tags']),
      lifestyleTraits: _map(json['lifestyle_traits']),
      mediaUrls: _stringList(json['media_urls']),
      viewsCount: _nullableInt(json['views_count']) ?? 0,
      roomId: _string(json['room_id']),
      status: _requiredString(json, 'status'),
      expiresAt: _requiredDate(json, 'expires_at'),
      createdAt: _requiredDate(json, 'created_at'),
      updatedAt: _requiredDate(json, 'updated_at'),
      author: RoommateAuthor.fromJson(_requiredMap(json, 'author')),
      isOwner: json['is_owner'] == true,
      contactLocked: json['contact_locked'] != false,
      rejectionReason: _string(json['rejection_reason']),
      compatibilityScore: _nullableInt(json['compatibility_score']),
      compatibilityHighlights: _stringList(json['compatibility_highlights']),
    );
  }

  final String id;
  final String postType;
  final String title;
  final String description;
  final String province;
  final String district;
  final String? ward;
  final String? addressHint;

  final int budgetPerPerson;
  final int? totalRoomPrice;
  final int? depositPerPerson;

  final DateTime moveInDate;
  final int desiredRoommates;
  final int currentMembers;

  final String? authorGender;
  final String? universityOrWork;
  final String genderPreference;
  final String contactPreference;

  final List<String> lifestyleTags;
  final Map<String, dynamic> lifestyleTraits;
  final List<String> mediaUrls;

  final int viewsCount;
  final String? roomId;
  final String status;

  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  final RoommateAuthor author;
  final bool isOwner;
  final bool contactLocked;

  final String? rejectionReason;
  final int? compatibilityScore;
  final List<String> compatibilityHighlights;

  bool get isPending => status == 'PENDING_REVIEW';
  bool get isActive => status == 'ACTIVE';
  bool get isRejected => status == 'REJECTED';
  bool get isClosed => status == 'CLOSED';

  String? get thumbnailUrl {
    if (imageUrls.isEmpty) return null;
    return imageUrls.first;
  }

  List<String> get imageUrls => mediaUrls
      .where((url) => !_looksLikeVideoUrl(url))
      .toList(growable: false);

  List<String> get videoUrls =>
      mediaUrls.where(_looksLikeVideoUrl).toList(growable: false);
}

bool _looksLikeVideoUrl(String value) {
  final path = Uri.tryParse(value)?.path.toLowerCase() ?? value.toLowerCase();
  return const ['.mp4', '.m4v', '.mov', '.webm', '.3gp'].any(path.endsWith);
}

class RoommateAuthor {
  const RoommateAuthor({required this.id, required this.name, this.avatarUrl});

  factory RoommateAuthor.fromJson(Map<String, dynamic> json) {
    return RoommateAuthor(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      avatarUrl: _string(json['avatar_url']),
    );
  }

  final String id;
  final String name;
  final String? avatarUrl;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = _string(json[key]);

  if (value == null) {
    throw FormatException('Trường $key không hợp lệ.');
  }

  return value;
}

String? _string(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  return null;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  throw const FormatException('Dữ liệu số không hợp lệ.');
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  return null;
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is String) {
    final date = DateTime.tryParse(value);

    if (date != null) {
      return date;
    }
  }

  throw FormatException('Trường ngày $key không hợp lệ.');
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is Map<String, dynamic>) {
    return value;
  }

  throw FormatException('Trường $key không hợp lệ.');
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  return {};
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];

  return value
      .whereType<String>()
      .where((item) => item.trim().isNotEmpty)
      .map((item) => item.trim())
      .toList(growable: false);
}
