import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for calculating distances using Google Distance Matrix API
/// 
/// This service provides methods to calculate distances between locations
/// using Google's Distance Matrix API. It handles API calls, error handling,
/// and returns distances in miles.
class DistanceService {
  // Cache to avoid repeated API calls for the same routes
  static final Map<String, double> _distanceCache = {};
  
  /// Calculate distance between two addresses using Google Distance Matrix API
  /// 
  /// [origin] - Origin address as string
  /// [destination] - Destination address as string
  /// [apiKey] - Google API key
  /// 
  /// Returns distance in miles, or null if calculation fails
  static Future<double?> calculateDistance(
    String origin,
    String destination,
    String apiKey,
  ) async {
    // Check cache first
    final cacheKey = '$origin|$destination';
    if (_distanceCache.containsKey(cacheKey)) {
      return _distanceCache[cacheKey];
    }
    
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=${Uri.encodeComponent(origin)}'
        '&destinations=${Uri.encodeComponent(destination)}'
        '&units=imperial' // Get distance in miles
        '&key=$apiKey',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && 
            data['rows'] != null && 
            data['rows'].isNotEmpty) {
          final row = data['rows'][0];
          if (row['elements'] != null && row['elements'].isNotEmpty) {
            final element = row['elements'][0];
            
            if (element['status'] == 'OK' && element['distance'] != null) {
              // Distance is in meters, convert to miles
              final distanceInMeters = element['distance']['value'] as int;
              final distanceInMiles = distanceInMeters * 0.000621371;
              
              // Cache the result
              _distanceCache[cacheKey] = distanceInMiles;
              
              return distanceInMiles;
            }
          }
        }
        
        print('Distance Matrix API error: ${data['status']}');
        return null;
      } else {
        print('Distance Matrix API HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error calculating distance: $e');
      return null;
    }
  }
  
  /// Calculate distances from one origin to multiple destinations (batch)
  /// 
  /// [origin] - Origin address as string
  /// [destinations] - List of destination addresses
  /// [apiKey] - Google API key
  /// 
  /// Returns a map of destination address to distance in miles
  static Future<Map<String, double>> calculateBatchDistances(
    String origin,
    List<String> destinations,
    String apiKey,
  ) async {
    final results = <String, double>{};
    
    // Google Distance Matrix API supports up to 25 destinations per request
    const batchSize = 25;
    
    for (int i = 0; i < destinations.length; i += batchSize) {
      final batch = destinations.skip(i).take(batchSize).toList();
      final destinationsString = batch.join('|');
      
      try {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/distancematrix/json'
          '?origins=${Uri.encodeComponent(origin)}'
          '&destinations=${Uri.encodeComponent(destinationsString)}'
          '&units=imperial' // Get distance in miles
          '&key=$apiKey',
        );
        
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['status'] == 'OK' && 
              data['rows'] != null && 
              data['rows'].isNotEmpty) {
            final row = data['rows'][0];
            if (row['elements'] != null && row['elements'].isNotEmpty) {
              final elements = row['elements'] as List;
              
              for (int j = 0; j < elements.length && j < batch.length; j++) {
                final element = elements[j];
                final destination = batch[j];
                
                if (element['status'] == 'OK' && element['distance'] != null) {
                  // Distance is in meters, convert to miles
                  final distanceInMeters = element['distance']['value'] as int;
                  final distanceInMiles = distanceInMeters * 0.000621371;
                  
                  results[destination] = distanceInMiles;
                  
                  // Cache the result
                  final cacheKey = '$origin|$destination';
                  _distanceCache[cacheKey] = distanceInMiles;
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error calculating batch distances: $e');
        // Continue with next batch even if one fails
      }
    }
    
    return results;
  }
  
  /// Clear the distance cache (useful for testing or when needed)
  static void clearCache() {
    _distanceCache.clear();
  }
}

