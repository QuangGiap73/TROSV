import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tenant_preference.dart';
import '../../domain/entities/university_location.dart';

enum PreferenceChatStep {
  location,
  budget,
  radius,
  roomType,
  people,
  amenities,
  extras,
  alerts,
  review,
  recommendations,
}

class PreferenceDraft {
  const PreferenceDraft({
    this.university,
    this.district,
    this.latitude,
    this.longitude,
    this.radiusKm = 5,
    this.budgetMax = 3000000,
    this.roomType,
    this.maxPeople = 1,
    this.amenities = const {},
    this.bathroomPrivate = false,
    this.hasBalcony = false,
    this.alertsEnabled = true,
  });

  factory PreferenceDraft.fromPreference(TenantPreference value) =>
      PreferenceDraft(
        university: value.university,
        district: value.district,
        latitude: value.latitude,
        longitude: value.longitude,
        radiusKm: value.radiusKm,
        budgetMax: value.budgetMax > 0 ? value.budgetMax : 3000000,
        roomType: value.roomType,
        maxPeople: value.maxPeople,
        amenities: value.amenities.toSet(),
        bathroomPrivate: value.bathroomPrivate,
        hasBalcony: value.hasBalcony,
        alertsEnabled: value.alertsEnabled,
      );

  final String? university;
  final String? district;
  final double? latitude;
  final double? longitude;
  final double radiusKm;
  final int budgetMax;
  final String? roomType;
  final int maxPeople;
  final Set<String> amenities;
  final bool bathroomPrivate;
  final bool hasBalcony;
  final bool alertsEnabled;

  PreferenceDraft copyWith({
    String? university,
    String? district,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int? budgetMax,
    String? roomType,
    bool clearRoomType = false,
    int? maxPeople,
    Set<String>? amenities,
    bool? bathroomPrivate,
    bool? hasBalcony,
    bool? alertsEnabled,
  }) => PreferenceDraft(
    university: university ?? this.university,
    district: district ?? this.district,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusKm: radiusKm ?? this.radiusKm,
    budgetMax: budgetMax ?? this.budgetMax,
    roomType: clearRoomType ? null : roomType ?? this.roomType,
    maxPeople: maxPeople ?? this.maxPeople,
    amenities: Set.unmodifiable(amenities ?? this.amenities),
    bathroomPrivate: bathroomPrivate ?? this.bathroomPrivate,
    hasBalcony: hasBalcony ?? this.hasBalcony,
    alertsEnabled: alertsEnabled ?? this.alertsEnabled,
  );

  TenantPreference toPreference() => TenantPreference(
    university: university,
    district: district,
    latitude: latitude,
    longitude: longitude,
    radiusKm: radiusKm,
    budgetMax: budgetMax,
    roomType: roomType,
    maxPeople: maxPeople,
    amenities: amenities.toList(growable: false),
    bathroomPrivate: bathroomPrivate,
    hasBalcony: hasBalcony,
    alertsEnabled: alertsEnabled,
  );
}

class PreferenceChatState {
  const PreferenceChatState({
    this.step = PreferenceChatStep.location,
    this.draft = const PreferenceDraft(),
    this.hydrated = false,
  });

  final PreferenceChatStep step;
  final PreferenceDraft draft;
  final bool hydrated;

  PreferenceChatState copyWith({
    PreferenceChatStep? step,
    PreferenceDraft? draft,
    bool? hydrated,
  }) => PreferenceChatState(
    step: step ?? this.step,
    draft: draft ?? this.draft,
    hydrated: hydrated ?? this.hydrated,
  );
}

final preferenceChatProvider =
    NotifierProvider.autoDispose<PreferenceChatController, PreferenceChatState>(
      PreferenceChatController.new,
    );

class PreferenceChatController extends Notifier<PreferenceChatState> {
  @override
  PreferenceChatState build() => const PreferenceChatState();

  void hydrate(TenantPreference? preference) {
    if (state.hydrated) return;
    state = state.copyWith(
      draft: preference == null
          ? const PreferenceDraft()
          : PreferenceDraft.fromPreference(preference),
      step: preference == null
          ? PreferenceChatStep.location
          : PreferenceChatStep.review,
      hydrated: true,
    );
  }

  void selectUniversity(UniversityLocation university) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        university: university.name,
        district: university.district,
        latitude: university.latitude,
        longitude: university.longitude,
      ),
      step: PreferenceChatStep.budget,
    );
  }

  void selectBudget(int value) => _update(
    state.draft.copyWith(budgetMax: value),
    PreferenceChatStep.radius,
  );

  void selectRadius(double value) => _update(
    state.draft.copyWith(radiusKm: value),
    PreferenceChatStep.roomType,
  );

  void selectRoomType(String? value) => _update(
    state.draft.copyWith(roomType: value, clearRoomType: value == null),
    PreferenceChatStep.people,
  );

  void selectPeople(int value) => _update(
    state.draft.copyWith(maxPeople: value),
    PreferenceChatStep.amenities,
  );

  void toggleAmenity(String code) {
    final values = state.draft.amenities.toSet();
    values.contains(code) ? values.remove(code) : values.add(code);
    state = state.copyWith(draft: state.draft.copyWith(amenities: values));
  }

  void confirmAmenities() =>
      state = state.copyWith(step: PreferenceChatStep.extras);

  void toggleBathroom() {
    state = state.copyWith(
      draft: state.draft.copyWith(
        bathroomPrivate: !state.draft.bathroomPrivate,
      ),
    );
  }

  void toggleBalcony() {
    state = state.copyWith(
      draft: state.draft.copyWith(hasBalcony: !state.draft.hasBalcony),
    );
  }

  void confirmExtras() =>
      state = state.copyWith(step: PreferenceChatStep.alerts);

  void setAlerts(bool value) => _update(
    state.draft.copyWith(alertsEnabled: value),
    PreferenceChatStep.review,
  );

  void showRecommendations() =>
      state = state.copyWith(step: PreferenceChatStep.recommendations);

  void edit(PreferenceChatStep step) => state = state.copyWith(step: step);

  void restart() => state = const PreferenceChatState(hydrated: true);

  void _update(PreferenceDraft draft, PreferenceChatStep next) {
    state = state.copyWith(draft: draft, step: next);
  }
}
