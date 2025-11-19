import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Reusable Google Places Autocomplete widget
class GooglePlacesAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final String? subtext;
  final Function(String)? onPlaceSelected;
  final String apiKey;

  const GooglePlacesAutocomplete({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.subtext,
    this.onPlaceSelected,
    required this.apiKey,
  });

  @override
  State<GooglePlacesAutocomplete> createState() =>
      _GooglePlacesAutocompleteState();
}

class _GooglePlacesAutocompleteState extends State<GooglePlacesAutocomplete> {
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _isSelecting = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _suggestions = [];
        });
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_isSelecting) return;
    final query = widget.controller.text.trim();
    if (query.length > 2) {
      _fetchSuggestions(query);
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

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
          'X-Goog-FieldMask': 'suggestions.placePrediction.placeId,suggestions.placePrediction.text',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          final suggestions = data['suggestions'] as List<dynamic>? ?? [];
          setState(() {
            _suggestions = suggestions
                .where((s) => s['placePrediction'] != null)
                .map<String>((s) {
                  final prediction = s['placePrediction'];
                  return (prediction['text']['text'] ?? '') as String;
                })
                .where((text) => text.isNotEmpty)
                .toList();
            _isLoading = false;
          });
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                Icon(widget.icon,
                    size: 24, color: const Color.fromRGBO(0, 0, 0, 0.45)),
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
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 5),
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
                return InkWell(
                  onTap: () {
                    _isSelecting = true;
                    widget.controller.removeListener(_onTextChanged);
                    widget.controller.text = suggestion;
                    widget.controller.addListener(_onTextChanged);
                    _focusNode.unfocus();
                    setState(() {
                      _suggestions = [];
                    });
                    _isSelecting = false;
                    if (widget.onPlaceSelected != null) {
                      widget.onPlaceSelected!(suggestion);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                );
              },
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
