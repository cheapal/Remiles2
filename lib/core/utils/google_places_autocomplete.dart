import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

/// Address components returned from place details
class AddressComponents {
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;

  AddressComponents({this.address, this.city, this.state, this.zipCode});
}

/// Reusable Google Places Autocomplete widget
class GooglePlacesAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final String? subtext;
  final Function(String)? onPlaceSelected;
  final Function(AddressComponents)? onAddressComponents;
  final String apiKey;

  const GooglePlacesAutocomplete({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.subtext,
    this.onPlaceSelected,
    this.onAddressComponents,
    required this.apiKey,
  });

  @override
  State<GooglePlacesAutocomplete> createState() =>
      _GooglePlacesAutocompleteState();
}

class _SuggestionItem {
  final String text;
  final String placeId;

  _SuggestionItem({required this.text, required this.placeId});
}

class _GooglePlacesAutocompleteState extends State<GooglePlacesAutocomplete> {
  List<_SuggestionItem> _suggestions = [];
  bool _isLoading = false;
  bool _isSelecting = false;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && !_isSelecting) {
        // On web, clicking an item can cause focus loss before the tap is registered.
        // We add a small delay to allow the tap event to fire.
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_focusNode.hasFocus && !_isSelecting) {
            setState(() {
              _suggestions = [];
            });
            _removeOverlay();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeOverlay();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    if (_suggestions.isEmpty) {
      _removeOverlay();
      return;
    }

    // Remove existing overlay if it exists
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }

    final RenderBox? renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: renderBox.size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, renderBox.size.height + 5),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(108, 167, 138, 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return Listener(
                    onPointerDown: (_) => _isSelecting = true,
                    child: InkWell(
                      onTap: () async {
                        // Cancel any pending debounce timer immediately
                        _debounceTimer?.cancel();

                        // Set selecting flag immediately to prevent any new fetches
                        _isSelecting = true;

                        // Remove listener to prevent text change triggers
                        widget.controller.removeListener(_onTextChanged);

                        // Clear suggestions IMMEDIATELY and synchronously
                        _removeOverlay();
                        setState(() {
                          _suggestions = [];
                          _isLoading = false;
                        });

                        // Unfocus to close keyboard and dropdown
                        _focusNode.unfocus();

                        // Wait a frame to ensure UI updates
                        await Future.delayed(Duration.zero);

                        // Set the selected text
                        widget.controller.text = suggestion.text;

                        // Fetch place details to get address components
                        if (widget.onAddressComponents != null) {
                          final components = await _fetchPlaceDetails(
                            suggestion.placeId,
                          );
                          if (components != null && mounted) {
                            widget.onAddressComponents!(components);
                          }
                        }

                        // Re-add listener AFTER everything is done
                        await Future.delayed(Duration.zero);
                        widget.controller.addListener(_onTextChanged);
                        _isSelecting = false;

                        if (widget.onPlaceSelected != null) {
                          widget.onPlaceSelected!(suggestion.text);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          suggestion.text,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onTextChanged() {
    if (_isSelecting) return;

    // Cancel previous timer
    _debounceTimer?.cancel();

    final query = widget.controller.text.trim();
    if (query.length > 2) {
      // Debounce: wait 500ms before fetching suggestions
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        // Only fetch if query hasn't changed and widget is still mounted
        final currentQuery = widget.controller.text.trim();
        if (mounted &&
            !_isSelecting &&
            currentQuery == query &&
            currentQuery.length > 2) {
          _fetchSuggestions(query);
        }
      });
    } else {
      // Clear suggestions immediately if query is too short
      if (mounted) {
        setState(() {
          _suggestions = [];
        });
        _removeOverlay();
      }
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    // Prevent duplicate requests for the same query
    if (_isLoading || _isSelecting) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final url = Uri.parse(
        'https://places.googleapis.com/v1/places:autocomplete',
      );

      final requestBody = {
        'input': query,
        'includedRegionCodes': ['CA'],
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': widget.apiKey,
          'X-Goog-FieldMask':
              'suggestions.placePrediction.placeId,suggestions.placePrediction.text',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted && !_isSelecting) {
          // Only update if query hasn't changed
          final currentQuery = widget.controller.text.trim();
          if (currentQuery == query) {
            final suggestions = data['suggestions'] as List<dynamic>? ?? [];
            setState(() {
              _suggestions = suggestions
                  .where((s) => s['placePrediction'] != null)
                  .map<_SuggestionItem>((s) {
                    final prediction = s['placePrediction'];
                    final text = (prediction['text']['text'] ?? '') as String;
                    final placeId = (prediction['placeId'] ?? '') as String;
                    return _SuggestionItem(text: text, placeId: placeId);
                  })
                  .where(
                    (item) => item.text.isNotEmpty && item.placeId.isNotEmpty,
                  )
                  .toList();
              _isLoading = false;
            });

            // Show/update overlay based on suggestions
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                if (_suggestions.isNotEmpty) {
                  _showOverlay();
                } else {
                  _removeOverlay();
                }
              }
            });
          } else {
            // Query changed, don't update suggestions
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              _removeOverlay();
            }
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _suggestions = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<AddressComponents?> _fetchPlaceDetails(String placeId) async {
    try {
      // Handle placeId that might already include "places/" prefix
      final cleanPlaceId = placeId.startsWith('places/')
          ? placeId.substring(7)
          : placeId;

      final url = Uri.parse(
        'https://places.googleapis.com/v1/places/$cleanPlaceId',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': widget.apiKey,
          'X-Goog-FieldMask': 'formattedAddress,addressComponents',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final formattedAddress = data['formattedAddress'] as String? ?? '';
        final addressComponents =
            data['addressComponents'] as List<dynamic>? ?? [];

        String? city;
        String? state;
        String? zipCode;

        for (var component in addressComponents) {
          final types = component['types'] as List<dynamic>? ?? [];
          // Try different field name variations for the new Places API v1
          final longName =
              component['longText'] as String? ??
              component['longName'] as String? ??
              component['shortText'] as String? ??
              component['shortName'] as String? ??
              component['text'] as String? ??
              '';

          if (longName.isEmpty) continue;

          if (types.contains('locality')) {
            city = longName;
          } else if (types.contains('administrative_area_level_1')) {
            state = longName;
          } else if (types.contains('postal_code')) {
            zipCode = longName;
          }
        }

        return AddressComponents(
          address: formattedAddress,
          city: city,
          state: state,
          zipCode: zipCode,
        );
      } else {
        print(
          'Error fetching place details: Status ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            key: _fieldKey,
            width: double.infinity,
            height: 49,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(108, 167, 138, 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 24,
                    color: const Color.fromRGBO(0, 0, 0, 0.45),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: InputBorder.none,
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          color: Color.fromRGBO(0, 0, 0, 0.45),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.fromRGBO(0, 0, 0, 0.45),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (widget.subtext != null)
          Padding(
            padding: const EdgeInsets.only(top: 5.0, left: 15.0),
            child: Text(
              widget.subtext!,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(0, 0, 0, 0.34),
              ),
            ),
          ),
      ],
    );
  }
}
