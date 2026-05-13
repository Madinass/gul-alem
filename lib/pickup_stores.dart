import 'package:latlong2/latlong.dart';

class PickupStore {
  final String id;
  final String name;
  final String address;
  final LatLng location;

  const PickupStore({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': location.latitude,
      'longitude': location.longitude,
    };
  }
}

// Placeholder coordinates. Replace these with exact coordinates from a map
// service before production release.
const List<PickupStore> pickupStores = [
  PickupStore(
    id: 'kyz-zhibek',
    name: 'Gul Alem - Kyz Zhibek',
    address: 'Kyz Zhibek Street 36, Astana',
    location: LatLng(51.1747, 71.3848),
  ),
  PickupStore(
    id: 'kerey-zhanibek-khandar',
    name: 'Gul Alem - Kerey Zhanibek Khandar',
    address: 'Kerey Zhanibek Khandar Street 17, Astana',
    location: LatLng(51.1114, 71.4201),
  ),
  PickupStore(
    id: 'dinmukhamed-konayev',
    name: 'Gul Alem - Dinmukhamed Konayev',
    address: 'Dinmukhamed Konayev Street 14, Astana',
    location: LatLng(51.1264, 71.4308),
  ),
];
