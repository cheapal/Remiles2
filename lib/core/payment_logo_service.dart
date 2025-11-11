import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;

/// Service to manage payment card logos with caching
class PaymentLogoService {
  static final PaymentLogoService _instance = PaymentLogoService._internal();
  factory PaymentLogoService() => _instance;
  PaymentLogoService._internal();

  // Cache for loaded images
  final Map<String, ui.Image> _imageCache = {};
  final Map<String, Widget> _widgetCache = {};

  /// Get payment logo asset path for a card brand
  static String getLogoAssetPath(String brand) {
    final normalizedBrand = brand.toLowerCase().replaceAll('_', '').replaceAll('-', '');
    
    switch (normalizedBrand) {
      case 'visa':
        return 'assets/visa.svg';
      case 'mastercard':
      case 'mc':
        return 'assets/mastercard.svg'; // Will fallback if not available
      case 'amex':
      case 'americanexpress':
        return 'assets/amex.svg'; // Will fallback if not available
      case 'discover':
        return 'assets/discover.svg'; // Will fallback if not available
      case 'diners':
      case 'dinersclub':
        return 'assets/diners.svg'; // Will fallback if not available
      case 'jcb':
        return 'assets/jcb.svg'; // Will fallback if not available
      case 'unionpay':
        return 'assets/unionpay.svg'; // Will fallback if not available
      default:
        return 'assets/visa.svg'; // Default fallback
    }
  }

  /// Get payment logo widget with caching
  Widget getLogoWidget(String brand, {double? width, double? height}) {
    final cacheKey = '${brand}_${width ?? 60}_${height ?? 40}';
    
    // Return cached widget if available
    if (_widgetCache.containsKey(cacheKey)) {
      return _widgetCache[cacheKey]!;
    }

    final assetPath = getLogoAssetPath(brand);
    final normalizedBrand = brand.toUpperCase();

    // Create widget with error handling for SVG
    final widget = _SvgAssetWidget(
      assetPath: assetPath,
      width: width ?? 60,
      height: height ?? 40,
      fallback: _buildTextLogo(normalizedBrand, width: width, height: height),
    );

    // Cache the widget
    _widgetCache[cacheKey] = widget;
    return widget;
  }

  /// Build a text-based logo as fallback
  Widget _buildTextLogo(String brand, {double? width, double? height}) {
    // Get brand color
    Color brandColor;
    switch (brand.toUpperCase()) {
      case 'VISA':
        brandColor = const Color(0xFF1A1F71);
        break;
      case 'MASTERCARD':
      case 'MC':
        brandColor = const Color(0xFFEB001B);
        break;
      case 'AMEX':
      case 'AMERICAN EXPRESS':
        brandColor = const Color(0xFF006FCF);
        break;
      case 'DISCOVER':
        brandColor = const Color(0xFFFF6000);
        break;
      case 'DINERS':
      case 'DINERS CLUB':
        brandColor = const Color(0xFF0079BE);
        break;
      case 'JCB':
        brandColor = const Color(0xFF0B4EA2);
        break;
      default:
        brandColor = const Color(0xFF1A1F71);
    }

    return Container(
      width: width ?? 60,
      height: height ?? 40,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: brandColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          brand.length > 4 ? brand.substring(0, 4) : brand,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Clear cache (useful for memory management)
  void clearCache() {
    _imageCache.clear();
    _widgetCache.clear();
  }

  /// Preload common payment logos
  Future<void> preloadLogos() async {
    final commonBrands = ['visa', 'mastercard', 'amex', 'discover'];
    for (final brand in commonBrands) {
      try {
        final assetPath = getLogoAssetPath(brand);
        // Preload SVG asset
        await rootBundle.loadString(assetPath);
      } catch (e) {
        // Asset doesn't exist, that's okay - will use fallback
        debugPrint('Payment logo not found for $brand: $e');
      }
    }
  }
}

/// Widget to handle SVG asset loading with error fallback
class _SvgAssetWidget extends StatelessWidget {
  final String assetPath;
  final double width;
  final double height;
  final Widget fallback;

  const _SvgAssetWidget({
    required this.assetPath,
    required this.width,
    required this.height,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString(assetPath).catchError((e) => ''),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          try {
            return SvgPicture.string(
              snapshot.data!,
              width: width,
              height: height,
              fit: BoxFit.contain,
    
            );
          
          } catch (e) {
            debugPrint('Error rendering SVG: $e');
            return fallback;
          }
        }
        // If loading or error, show fallback
        return fallback;
      },
    );
  }
}

