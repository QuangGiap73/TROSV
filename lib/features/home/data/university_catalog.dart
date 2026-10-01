import '../domain/university_item.dart';

const universityCatalog = <UniversityItem>[
  UniversityItem(
    id: 'phenikaa',
    name: 'Đại học Phenikaa',
    shortName: 'ĐH Phenikaa',
    searchQuery: 'Đại học Phenikaa, đường Nguyễn Trác, Hà Nội',
    imageAsset: 'assets/images/universities/phenikaa.jpg',
  ),
  UniversityItem(
    id: 'hust',
    name: 'Đại học Bách khoa Hà Nội',
    shortName: 'ĐH Bách Khoa',
    searchQuery: 'Đại học Bách khoa Hà Nội, 1 Đại Cồ Việt, Hà Nội',
    imageAsset: 'assets/images/universities/hust.jpg',
  ),
  UniversityItem(
    id: 'neu',
    name: 'Đại học Kinh tế Quốc dân',
    shortName: 'ĐH Kinh Tế Quốc Dân',
    searchQuery: 'Đại học Kinh tế Quốc dân, 207 Giải Phóng, Hà Nội',
    imageAsset: 'assets/images/universities/neu.jpg',
  ),
  UniversityItem(
    id: 'ftu',
    name: 'Đại học Ngoại thương',
    shortName: 'ĐH Ngoại Thương',
    searchQuery: 'Đại học Ngoại thương, 91 Chùa Láng, Hà Nội',
    imageAsset: 'assets/images/universities/ftu.jpg',
  ),
  UniversityItem(
    id: 'tmu',
    name: 'Đại học Thương mại',
    shortName: 'ĐH Thương Mại',
    searchQuery: 'Đại học Thương mại, 79 Hồ Tùng Mậu, Hà Nội',
    imageAsset: 'assets/images/universities/tmu.jpg',
  ),
  UniversityItem(
    id: 'hvnh',
    name: 'Học viện Ngân hàng',
    shortName: 'Học Viện Ngân Hàng',
    searchQuery: 'Học viện Ngân hàng, 12 Chùa Bộc, Hà Nội',
    imageAsset: 'assets/images/universities/hvnh.jpg',
  ),
  UniversityItem(
    id: 'hanu',
    name: 'Đại học Hà Nội',
    shortName: 'ĐH Hà Nội',
    searchQuery: 'Đại học Hà Nội, Km 9 Nguyễn Trãi, Hà Nội',
    imageAsset: 'assets/images/universities/hanu.jpg',
  ),
  UniversityItem(
    id: 'hnue',
    name: 'Đại học Sư phạm Hà Nội',
    shortName: 'ĐH Sư Phạm Hà Nội',
    searchQuery: 'Đại học Sư phạm Hà Nội, 136 Xuân Thủy, Hà Nội',
    imageAsset: 'assets/images/universities/hnue.jpg',
  ),
  UniversityItem(
    id: 'vnu_cau_giay',
    name: 'Đại học Quốc gia Hà Nội - Cầu Giấy',
    shortName: 'ĐHQG Hà Nội',
    searchQuery: 'Đại học Quốc gia Hà Nội, 144 Xuân Thủy, Hà Nội',
    imageAsset: 'assets/images/universities/vnu.jpg',
  ),
  UniversityItem(
    id: 'utc',
    name: 'Đại học Giao thông Vận tải',
    shortName: 'ĐH GTVT',
    searchQuery: 'Đại học Giao thông Vận tải, 3 Cầu Giấy, Hà Nội',
    imageAsset: 'assets/images/universities/utc.jpg',
  ),
  UniversityItem(
    id: 'tlu',
    name: 'Đại học Thủy lợi',
    shortName: 'ĐH Thủy Lợi',
    searchQuery: 'Đại học Thủy lợi, 175 Tây Sơn, Hà Nội',
    imageAsset: 'assets/images/universities/tlu.jpg',
  ),
  UniversityItem(
    id: 'hau',
    name: 'Đại học Kiến trúc Hà Nội',
    shortName: 'ĐH Kiến Trúc',
    searchQuery: 'Đại học Kiến trúc Hà Nội, Nguyễn Trãi, Hà Nội',
    imageAsset: 'assets/images/universities/hau.jpg',
  ),
];

UniversityItem? universityById(String id) {
  for (final item in universityCatalog) {
    if (item.id == id) return item;
  }
  return null;
}
