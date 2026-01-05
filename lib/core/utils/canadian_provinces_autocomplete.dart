import 'package:flutter/material.dart';

/// Reusable Canadian Provinces Autocomplete widget
class CanadianProvincesAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final String? subtext;

  const CanadianProvincesAutocomplete({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.subtext,
  });

  @override
  State<CanadianProvincesAutocomplete> createState() =>
      _CanadianProvincesAutocompleteState();
}

class _CanadianProvincesAutocompleteState
    extends State<CanadianProvincesAutocomplete> {
  static const List<String> _provinces = [
    'Alberta',
    'British Columbia',
    'Manitoba',
    'New Brunswick',
    'Newfoundland and Labrador',
    'Northwest Territories',
    'Nova Scotia',
    'Nunavut',
    'Ontario',
    'Prince Edward Island',
    'Quebec',
    'Saskatchewan',
    'Yukon',
  ];

  List<String> _filteredProvinces = [];
  final FocusNode _focusNode = FocusNode();
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && !_isSelecting) {
        // On web, clicking an item can cause focus loss before the tap is registered.
        // We add a small delay to allow the tap event to fire.
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_focusNode.hasFocus && !_isSelecting) {
            setState(() {
              _filteredProvinces = [];
            });
          }
        });
      } else if (_focusNode.hasFocus && widget.controller.text.isEmpty) {
        setState(() {
          _filteredProvinces = List.from(_provinces);
        });
      }
    });
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _filteredProvinces = [];
      });
      return;
    }
    final query = widget.controller.text.toLowerCase();
    if (query.isNotEmpty) {
      setState(() {
        _filteredProvinces = _provinces
            .where(
              (province) =>
                  province.toLowerCase().contains(query) ||
                  province.toLowerCase().startsWith(query),
            )
            .toList();
      });
    } else {
      setState(() {
        _filteredProvinces = List.from(_provinces);
      });
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
              ],
            ),
          ),
        ),
        if (_filteredProvinces.isNotEmpty)
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
              itemCount: _filteredProvinces.length,
              itemBuilder: (context, index) {
                final province = _filteredProvinces[index];
                return Listener(
                  onPointerDown: (_) => _isSelecting = true,
                  child: InkWell(
                    onTap: () {
                      _isSelecting = true;
                      widget.controller.removeListener(_onTextChanged);
                      widget.controller.text = province;
                      widget.controller.addListener(_onTextChanged);
                      _focusNode.unfocus();
                      setState(() {
                        _filteredProvinces = [];
                        _isSelecting = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        province,
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
