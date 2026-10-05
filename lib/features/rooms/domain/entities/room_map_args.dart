import 'room_search_query.dart';

class RoomMapArgs {
  const RoomMapArgs({required this.query, this.focusLabel});

  final RoomSearchQuery query;
  final String? focusLabel;
}
