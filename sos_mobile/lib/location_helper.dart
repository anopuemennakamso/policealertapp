import 'package:geocoding/geocoding.dart';

Future<String> getAddressFromCoordinates(double lat, double lng) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      
      // Combines street, locality, and administrative area into a clear string
      String street = place.street ?? '';
      String locality = place.locality ?? place.subAdministrativeArea ?? '';
      String state = place.administrativeArea ?? '';

      return '$street, $locality, $state'.replaceAll(RegExp(r'^,\s*'), '');
    }
    return '$lat, $lng'; // Fallback to raw coordinates if no placemark found
  } catch (e) {
    return '$lat, $lng'; // Fallback on network/geocoding error
  }
}