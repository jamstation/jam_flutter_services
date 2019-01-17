import 'package:geolocator/geolocator.dart';
import 'package:jam_dart_interfaces/interfaces.dart';
import 'package:jam_dart_models/models.dart';
import 'package:rxdart/rxdart.dart';

class LocationService implements LocationInterface {
  Observable<Location> getCurrentLocation() {
    return Observable.fromFuture(Geolocator().getCurrentPosition()).map((position) => Location(
          name: position.toString(),
          geoPoint: GeoPoint(position.latitude, position.longitude),
        ));
  }
}
