import 'roommate_lifestyle_traits.dart';

class CreateRoommatePostRequest {
  const CreateRoommatePostRequest({
    required this.postType,
    required this.title,
    required this.description,
    required this.province,
    required this.district,
    required this.budgetPerPerson,
    required this.moveInDate,
    required this.desiredRoommates,
    required this.currentMembers,
    required this.authorGender,
    required this.genderPreference,
    required this.contactPreference,
    required this.lifestyleTraits,
    this.ward,
    this.addressHint,
    this.totalRoomPrice,
    this.depositPerPerson,
    this.universityOrWork,
    this.roomId,
    this.lifestyleTags = const [],
    this.mediaUrls = const [],
  });

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

  final String authorGender;
  final String genderPreference;
  final String contactPreference;

  final String? universityOrWork;
  final String? roomId;

  final List<String> lifestyleTags;
  final RoommateLifestyleTraits lifestyleTraits;
  final List<String> mediaUrls;

  Map<String, dynamic> toJson() {
    return {
      'post_type': postType,
      'title': title.trim(),
      'description': description.trim(),
      'province': province.trim(),
      'district': district.trim(),
      'ward': _nullIfEmpty(ward),
      'address_hint': _nullIfEmpty(addressHint),
      'budget_per_person': budgetPerPerson,
      'total_room_price': totalRoomPrice,
      'deposit_per_person': depositPerPerson ?? 0,
      'move_in_date': _formatDate(moveInDate),
      'desired_roommates': desiredRoommates,
      'current_members': currentMembers,
      'author_gender': authorGender,
      'university_or_work': _nullIfEmpty(universityOrWork),
      'gender_preference': genderPreference,
      'contact_preference': contactPreference,
      'lifestyle_tags': lifestyleTags,
      'lifestyle_traits': lifestyleTraits.toJson(),
      'media_urls': mediaUrls,
      'room_id': _nullIfEmpty(roomId),
    };
  }
}

String _formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String? _nullIfEmpty(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  return value.trim();
}
