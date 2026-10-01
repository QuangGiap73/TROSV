import 'package:flutter/material.dart';

import '../../domain/university_item.dart';

class UniversityExploreSection extends StatelessWidget {
  const UniversityExploreSection({
    required this.universities,
    required this.onUniversityTap,
    this.loadingUniversityId,
    super.key,
  });

  final List<UniversityItem> universities;
  final String? loadingUniversityId;
  final ValueChanged<UniversityItem> onUniversityTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Khám phá theo trường đại học',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 5),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Tìm phòng trọ trong bán kính 5 km quanh trường',
              style: TextStyle(fontSize: 12, color: Color(0xFF71807C)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 154,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: universities.length,
              separatorBuilder: (_, _) => const SizedBox(width: 11),
              itemBuilder: (_, index) {
                final university = universities[index];
                return _UniversityCard(
                  university: university,
                  loading: loadingUniversityId == university.id,
                  onTap: () => onUniversityTap(university),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UniversityCard extends StatelessWidget {
  const _UniversityCard({
    required this.university,
    required this.loading,
    required this.onTap,
  });

  final UniversityItem university;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cacheWidth = (142 * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(284, 568);
    return SizedBox(
      width: 142,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E9E6)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        university.imageAsset,
                        fit: BoxFit.cover,
                        cacheWidth: cacheWidth,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFFE5F5F1),
                          child: Icon(
                            Icons.school_rounded,
                            size: 42,
                            color: Color(0xFF008E79),
                          ),
                        ),
                      ),
                      if (loading)
                        const ColoredBox(
                          color: Color(0x66000000),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    university.shortName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
