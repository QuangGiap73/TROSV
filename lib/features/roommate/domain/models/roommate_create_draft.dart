import 'create_roommate_post_request.dart';
import 'roommate_lifestyle_traits.dart';

class RoommateCreateDraft {
  const RoommateCreateDraft({
    this.step = 0,
    this.postType = 'HAVE_ROOM',
    this.province = 'Hà Nội',
    this.district = '',
    this.ward = '',
    this.addressHint = '',
    this.budgetPerPerson = 0,
    this.totalRoomPrice = 0,
    this.depositPerPerson = 0,
    this.moveInDate,
    this.currentMembers = 1,
    this.desiredRoommates = 1,
    this.authorGender = 'ANY',
    this.genderPreference = 'ANY',
    this.contactPreference = 'BOTH',
    this.universityOrWork = '',
    this.curfew = '22:00',
    this.cleanliness = 'Gọn gàng',
    this.smoking = false,
    this.cooking = true,
    this.pets = false,
    this.guests = false,
    this.lifestyleTags = const {},
    this.mediaUrls = const [],
    this.title = '',
    this.description = '',
  });

  final int step;
  final String postType;

  final String province;
  final String district;
  final String ward;
  final String addressHint;

  final int budgetPerPerson;
  final int totalRoomPrice;
  final int depositPerPerson;
  final DateTime? moveInDate;

  final int currentMembers;
  final int desiredRoommates;

  final String authorGender;
  final String genderPreference;
  final String contactPreference;
  final String universityOrWork;

  final String curfew;
  final String cleanliness;
  final bool smoking;
  final bool cooking;
  final bool pets;
  final bool guests;

  final Set<String> lifestyleTags;
  final List<String> mediaUrls;

  final String title;
  final String description;

  RoommateCreateDraft copyWith({
    int? step,
    String? postType,
    String? province,
    String? district,
    String? ward,
    String? addressHint,
    int? budgetPerPerson,
    int? totalRoomPrice,
    int? depositPerPerson,
    DateTime? moveInDate,
    int? currentMembers,
    int? desiredRoommates,
    String? authorGender,
    String? genderPreference,
    String? contactPreference,
    String? universityOrWork,
    String? curfew,
    String? cleanliness,
    bool? smoking,
    bool? cooking,
    bool? pets,
    bool? guests,
    Set<String>? lifestyleTags,
    List<String>? mediaUrls,
    String? title,
    String? description,
  }) {
    return RoommateCreateDraft(
      step: step ?? this.step,
      postType: postType ?? this.postType,
      province: province ?? this.province,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      addressHint: addressHint ?? this.addressHint,
      budgetPerPerson: budgetPerPerson ?? this.budgetPerPerson,
      totalRoomPrice: totalRoomPrice ?? this.totalRoomPrice,
      depositPerPerson: depositPerPerson ?? this.depositPerPerson,
      moveInDate: moveInDate ?? this.moveInDate,
      currentMembers: currentMembers ?? this.currentMembers,
      desiredRoommates: desiredRoommates ?? this.desiredRoommates,
      authorGender: authorGender ?? this.authorGender,
      genderPreference: genderPreference ?? this.genderPreference,
      contactPreference: contactPreference ?? this.contactPreference,
      universityOrWork: universityOrWork ?? this.universityOrWork,
      curfew: curfew ?? this.curfew,
      cleanliness: cleanliness ?? this.cleanliness,
      smoking: smoking ?? this.smoking,
      cooking: cooking ?? this.cooking,
      pets: pets ?? this.pets,
      guests: guests ?? this.guests,
      lifestyleTags: lifestyleTags ?? this.lifestyleTags,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  CreateRoommatePostRequest toRequest() {
    return CreateRoommatePostRequest(
      postType: postType,
      title: title,
      description: description,
      province: province,
      district: district,
      ward: ward,
      addressHint: addressHint,
      budgetPerPerson: budgetPerPerson,
      totalRoomPrice: totalRoomPrice,
      depositPerPerson: depositPerPerson,
      moveInDate: moveInDate ?? DateTime.now(),
      desiredRoommates: desiredRoommates,
      currentMembers: currentMembers,
      authorGender: authorGender,
      genderPreference: genderPreference,
      contactPreference: contactPreference,
      universityOrWork: universityOrWork,
      lifestyleTags: lifestyleTags.toList(),
      lifestyleTraits: RoommateLifestyleTraits(
        curfew: curfew,
        cleanliness: cleanliness,
        smoking: smoking,
        cooking: cooking,
        pets: pets,
        guests: guests,
      ),
      mediaUrls: mediaUrls,
    );
  }
}
