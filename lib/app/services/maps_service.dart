import 'dart:convert';

import 'package:clicknow_version2/app/utils/device_constants/apiConstants.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.title = '',
    this.secondaryText = '',
    this.fullAddress = '',
  });

  final String placeId;
  final String description;
  final String title;
  final String secondaryText;
  final String fullAddress;
}

class AddressSelection {
  const AddressSelection({
    required this.formattedAddress,
    required this.state,
    required this.city,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.country = '',
    this.googlePlaceId = '',
  });

  final String formattedAddress;
  final String state;
  final String city;
  final String pincode;
  final double latitude;
  final double longitude;
  final String country;
  final String googlePlaceId;
}

class MapsService {
  MapsService._();
  static final MapsService instance = MapsService._();

  final http.Client _client = http.Client();
  static const int _maxGeocodeSuggestions = 5;

  bool get isApiKeyConfigured {
    final key = ApiConstants.googleMapsApiKey.trim();
    return key.isNotEmpty && key != 'YOUR_GOOGLE_MAPS_API_KEY';
  }

  Future<List<PlaceSuggestion>> fetchPlaceSuggestions(String input) async {
    final query = input.trim();
    if (query.isEmpty || !isApiKeyConfigured) {
      return const <PlaceSuggestion>[];
    }

    try {
      final suggestions = await _fetchPlaceSuggestionsFromPlacesNew(query);
      if (suggestions.isNotEmpty) {
        return suggestions;
      }
    } catch (_) {
      // Fallback to the legacy endpoint when Places API (New) is unavailable.
    }

    try {
      final suggestions = await _fetchPlaceSuggestionsFromAutocomplete(query);
      if (suggestions.isNotEmpty) {
        return suggestions;
      }
    } catch (_) {
      // Fallback to Geocoding API when Places autocomplete is unavailable.
    }

    try {
      return await _fetchPlaceSuggestionsFromGeocode(query);
    } catch (_) {
      return const <PlaceSuggestion>[];
    }
  }

  Future<List<PlaceSuggestion>> _fetchPlaceSuggestionsFromPlacesNew(
    String query,
  ) async {
    final uri = Uri.https(
      'places.googleapis.com',
      '/v1/places:autocomplete',
    );

    final response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': ApiConstants.googleMapsApiKey,
        'X-Goog-FieldMask':
            'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
      },
      body: jsonEncode(<String, dynamic>{
        'input': query,
        'includedRegionCodes': <String>['in'],
        'languageCode': 'en',
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Places autocomplete request failed: ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final suggestions = body['suggestions'] as List<dynamic>? ?? <dynamic>[];
    return suggestions
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final prediction =
              item['placePrediction'] as Map<String, dynamic>? ??
              <String, dynamic>{};
          final placeId = (prediction['placeId'] ?? '').toString().trim();
          final structured =
              prediction['structuredFormat'] as Map<String, dynamic>? ??
              <String, dynamic>{};
          final mainText = _newApiText(structured['mainText']);
          final secondaryText = _newApiText(structured['secondaryText']);
          final fullText = _newApiText(prediction['text']);
          final description = fullText.isNotEmpty
              ? fullText
              : [mainText, secondaryText]
                    .where((part) => part.trim().isNotEmpty)
                    .join(', ');
          if (placeId.isEmpty || description.isEmpty) {
            return null;
          }
          return PlaceSuggestion(
            placeId: placeId,
            description: description,
            title: mainText.isEmpty ? description : mainText,
            secondaryText: secondaryText,
            fullAddress: description,
          );
        })
        .whereType<PlaceSuggestion>()
        .toList(growable: false);
  }

  Future<List<PlaceSuggestion>> _fetchPlaceSuggestionsFromAutocomplete(
    String query,
  ) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      <String, String>{
        'input': query,
        'key': ApiConstants.googleMapsApiKey,
        'components': 'country:in',
        'language': 'en',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Autocomplete request failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = (body['status'] ?? '').toString();
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception('Autocomplete failed: $status');
    }

    final predictions = (body['predictions'] as List<dynamic>? ?? <dynamic>[]);
    return predictions
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final placeId = (item['place_id'] ?? '').toString();
          final description = (item['description'] ?? '').toString();
          if (placeId.isEmpty || description.isEmpty) {
            return null;
          }
          final structured =
              item['structured_formatting'] as Map<String, dynamic>? ??
              <String, dynamic>{};
          return PlaceSuggestion(
            placeId: placeId,
            description: description,
            title: (structured['main_text'] ?? '').toString().trim(),
            secondaryText: (structured['secondary_text'] ?? '')
                .toString()
                .trim(),
            fullAddress: description,
          );
        })
        .whereType<PlaceSuggestion>()
        .toList(growable: false);
  }

  Future<List<PlaceSuggestion>> _fetchPlaceSuggestionsFromGeocode(
    String query,
  ) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      <String, String>{
        'address': query,
        'key': ApiConstants.googleMapsApiKey,
        'components': 'country:IN',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Geocode suggestion request failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = (body['status'] ?? '').toString();
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception('Geocode suggestion failed: $status');
    }

    final results = (body['results'] as List<dynamic>? ?? <dynamic>[]);
    if (results.isEmpty) {
      return const <PlaceSuggestion>[];
    }

    return results
        .take(_maxGeocodeSuggestions)
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final placeId = (item['place_id'] ?? '').toString().trim();
          final description = (item['formatted_address'] ?? '')
              .toString()
              .trim();
          if (placeId.isEmpty || description.isEmpty) {
            return null;
          }
          return PlaceSuggestion(
            placeId: placeId,
            description: description,
            title: description.split(',').first.trim(),
            secondaryText: description.contains(',')
                ? description.substring(description.indexOf(',') + 1).trim()
                : '',
            fullAddress: description,
          );
        })
        .whereType<PlaceSuggestion>()
        .toList(growable: false);
  }

  Future<AddressSelection?> getPlaceDetails(String placeId) async {
    final id = placeId.trim();
    if (id.isEmpty || !isApiKeyConfigured) {
      return null;
    }

    try {
      final placeDetails = await _getPlaceDetailsFromPlacesNew(id);
      if (placeDetails != null) {
        return placeDetails;
      }
    } catch (_) {
      // Fallback to legacy details when Places API (New) is unavailable.
    }

    try {
      final placeDetails = await _getPlaceDetailsFromPlacesApi(id);
      if (placeDetails != null) {
        return placeDetails;
      }
    } catch (_) {
      // Fallback to Geocoding API by place id.
    }

    return _getPlaceDetailsFromGeocode(id);
  }

  Future<AddressSelection?> _getPlaceDetailsFromPlacesNew(
    String placeId,
  ) async {
    final uri = Uri.https('places.googleapis.com', '/v1/places/$placeId');
    final response = await _client.get(
      uri,
      headers: <String, String>{
        'X-Goog-Api-Key': ApiConstants.googleMapsApiKey,
        'X-Goog-FieldMask':
            'id,formattedAddress,location,addressComponents',
      },
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Places details request failed: ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final location =
        body['location'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final lat = (location['latitude'] as num?)?.toDouble();
    final lng = (location['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      return null;
    }

    final addressParts = _extractAddressParts(body['addressComponents']);
    return AddressSelection(
      formattedAddress: (body['formattedAddress'] ?? '').toString().trim(),
      state: addressParts['state'] ?? '',
      city: addressParts['city'] ?? '',
      country: addressParts['country'] ?? '',
      pincode: addressParts['pincode'] ?? '',
      latitude: lat,
      longitude: lng,
      googlePlaceId: (body['id'] ?? placeId).toString().trim(),
    );
  }

  Future<AddressSelection?> _getPlaceDetailsFromPlacesApi(String placeId) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      <String, String>{
        'place_id': placeId,
        'fields': 'formatted_address,geometry,address_component',
        'key': ApiConstants.googleMapsApiKey,
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Place details request failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = (body['status'] ?? '').toString();
    if (status != 'OK') {
      return null;
    }

    final result =
        (body['result'] as Map<String, dynamic>? ?? <String, dynamic>{});
    final geometry =
        (result['geometry'] as Map<String, dynamic>? ?? <String, dynamic>{});
    final location =
        (geometry['location'] as Map<String, dynamic>? ?? <String, dynamic>{});
    final lat = (location['lat'] as num?)?.toDouble();
    final lng = (location['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      return null;
    }

    final formattedAddress = (result['formatted_address'] ?? '').toString();
    final addressParts = _extractAddressParts(result['address_components']);

    return AddressSelection(
      formattedAddress: formattedAddress,
      state: addressParts['state'] ?? '',
      city: addressParts['city'] ?? '',
      country: addressParts['country'] ?? '',
      pincode: addressParts['pincode'] ?? '',
      latitude: lat,
      longitude: lng,
      googlePlaceId: placeId,
    );
  }

  Future<AddressSelection?> _getPlaceDetailsFromGeocode(String placeId) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      <String, String>{
        'place_id': placeId,
        'key': ApiConstants.googleMapsApiKey,
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Geocode place details request failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = (body['status'] ?? '').toString();
    if (status != 'OK') {
      return null;
    }

    final results = (body['results'] as List<dynamic>? ?? <dynamic>[]);
    if (results.isEmpty) {
      return null;
    }

    final firstResult = results.first as Map<String, dynamic>;
    final geometry =
        (firstResult['geometry'] as Map<String, dynamic>? ??
            <String, dynamic>{});
    final location =
        (geometry['location'] as Map<String, dynamic>? ?? <String, dynamic>{});
    final lat = (location['lat'] as num?)?.toDouble();
    final lng = (location['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      return null;
    }

    final formattedAddress = (firstResult['formatted_address'] ?? '')
        .toString();
    final addressParts = _extractAddressParts(firstResult['address_components']);

    return AddressSelection(
      formattedAddress: formattedAddress,
      state: addressParts['state'] ?? '',
      city: addressParts['city'] ?? '',
      country: addressParts['country'] ?? '',
      pincode: addressParts['pincode'] ?? '',
      latitude: lat,
      longitude: lng,
      googlePlaceId: placeId,
    );
  }

  Future<AddressSelection?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    if (!isApiKeyConfigured) {
      return _reverseGeocodeWithGeocodingPackage(
        latitude: latitude,
        longitude: longitude,
      );
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      <String, String>{
        'latlng': '$latitude,$longitude',
        'key': ApiConstants.googleMapsApiKey,
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Reverse geocode request failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = (body['status'] ?? '').toString();
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception('Reverse geocode failed: $status');
    }

    final results = (body['results'] as List<dynamic>? ?? <dynamic>[]);
    if (results.isEmpty) {
      return _reverseGeocodeWithGeocodingPackage(
        latitude: latitude,
        longitude: longitude,
      );
    }

    final firstResult = results.first as Map<String, dynamic>;
    final formattedAddress = (firstResult['formatted_address'] ?? '')
        .toString();
    final addressParts = _extractAddressParts(
      firstResult['address_components'],
    );

    return AddressSelection(
      formattedAddress: formattedAddress,
      state: addressParts['state'] ?? '',
      city: addressParts['city'] ?? '',
      country: addressParts['country'] ?? '',
      pincode: addressParts['pincode'] ?? '',
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, String> _extractAddressParts(dynamic rawComponents) {
    final components = rawComponents is List
        ? rawComponents
        : const <dynamic>[];
    final byType = <String, String>{};

    for (final component in components) {
      if (component is! Map<String, dynamic>) {
        continue;
      }
      final types = (component['types'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false);
      final longName = _extractComponentLongName(component);
      if (longName.isEmpty) {
        continue;
      }

      for (final type in types) {
        byType.putIfAbsent(type, () => longName);
      }
    }

    final state = byType['administrative_area_level_1'] ?? '';
    final country = byType['country'] ?? '';
    final pincode = byType['postal_code'] ?? '';
    final city = _extractCityFromAddressComponents(byType);

    return <String, String>{
      'state': state,
      'city': city,
      'country': country,
      'pincode': pincode,
    };
  }

  String _newApiText(dynamic value) {
    if (value is Map<String, dynamic>) {
      return (value['text'] ?? '').toString().trim();
    }
    return (value ?? '').toString().trim();
  }

  String _extractComponentLongName(Map<String, dynamic> component) {
    final legacyLongName = (component['long_name'] ?? '').toString().trim();
    if (legacyLongName.isNotEmpty) {
      return legacyLongName;
    }

    final newLongText = component['longText'];
    if (newLongText is Map<String, dynamic>) {
      final mapped = (newLongText['text'] ?? '').toString().trim();
      if (mapped.isNotEmpty) {
        return mapped;
      }
    }

    return (newLongText ?? '').toString().trim();
  }

  String _extractCityFromAddressComponents(Map<String, String> byType) {
    const preferredCityTypes = <String>[
      'locality',
      'postal_town',
      'administrative_area_level_3',
      'administrative_area_level_2',
      'administrative_area_level_1',
      'sublocality_level_1',
      'sublocality',
      'neighborhood',
    ];

    for (final type in preferredCityTypes) {
      final value = byType[type]?.trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  Future<AddressSelection?> _reverseGeocodeWithGeocodingPackage({
    required double latitude,
    required double longitude,
  }) async {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) {
      return null;
    }
    final place = placemarks.first;
    final city = place.locality?.trim().isNotEmpty == true
        ? place.locality!.trim()
        : (place.subAdministrativeArea ?? '').trim();
    final state = (place.administrativeArea ?? '').trim();
    final pincode = (place.postalCode ?? '').trim();
    final addressParts = <String>[
      place.name ?? '',
      place.street ?? '',
      city,
      state,
      pincode,
    ].where((part) => part.trim().isNotEmpty).toList(growable: false);

    return AddressSelection(
      formattedAddress: addressParts.join(', '),
      state: state,
      city: city,
      country: (place.country ?? '').trim(),
      pincode: pincode,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
