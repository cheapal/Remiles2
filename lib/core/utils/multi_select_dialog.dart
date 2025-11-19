import 'package:flutter/material.dart';

/// Reusable Multi-Select Dialog utility class
class MultiSelectDialog {
  static Future<List<String>?> show({
    required BuildContext context,
    required String title,
    required List<String> options,
    List<String>? initialSelection,
  }) async {
    List<String> selected = List.from(initialSelection ?? []);

    return showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = selected.contains(option);

                    return CheckboxListTile(
                      title: Text(option),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            if (!selected.contains(option)) {
                              selected.add(option);
                            }
                          } else {
                            selected.remove(option);
                          }
                        });
                      },
                      activeColor: const Color(0xFF4B744F),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(selected);
                  },
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      color: Color(0xFF4B744F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Helper widget to display selected items as a text field with tap to open dialog
class MultiSelectField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final String? subtext;
  final List<String> selectedItems;
  final String title;
  final List<String> options;
  final Function(List<String>) onSelectionChanged;

  const MultiSelectField({
    super.key,
    required this.hintText,
    required this.icon,
    this.subtext,
    required this.selectedItems,
    required this.title,
    required this.options,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            final result = await MultiSelectDialog.show(
              context: context,
              title: title,
              options: options,
              initialSelection: selectedItems,
            );

            if (result != null) {
              onSelectionChanged(result);
            }
          },
          child: Container(
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
                  Icon(icon,
                      size: 24, color: const Color.fromRGBO(0, 0, 0, 0.45)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedItems.isEmpty
                          ? hintText
                          : selectedItems.join(', '),
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedItems.isEmpty
                            ? const Color.fromRGBO(0, 0, 0, 0.45)
                            : const Color(0xFF000000),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color.fromRGBO(0, 0, 0, 0.45),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (subtext != null)
          Padding(
            padding: const EdgeInsets.only(top: 5.0, left: 15.0),
            child: Text(
              subtext!,
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

