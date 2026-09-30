class RoommateLifestyleTraits {
  const RoommateLifestyleTraits({
    required this.curfew,
    required this.smoking,
    required this.cooking,
    required this.pets,
    required this.guests,
    required this.cleanliness,
  });

  final String curfew;
  final bool smoking;
  final bool cooking;
  final bool pets;
  final bool guests;
  final String cleanliness;

  Map<String, dynamic> toJson() => {
    'curfew': curfew,
    'smoking': smoking,
    'cooking': cooking,
    'pets': pets,
    'guests': guests,
    'cleanliness': cleanliness,
  };

  List<String> buildTags(Iterable<String> extraTags) {
    return <String>{
      ...extraTags,
      smoking ? 'Có hút thuốc' : 'Không hút thuốc',
      cooking ? 'Có nấu ăn' : 'Ít nấu ăn',
      pets ? 'Nuôi thú cưng' : 'Không nuôi thú cưng',
      guests ? 'Thoải mái có khách' : 'Hạn chế khách',
      cleanliness,
      if (curfew.isNotEmpty) 'Giờ về trước $curfew',
    }.take(12).toList(growable: false);
  }
}
