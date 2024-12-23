import 'package:flutter/material.dart';

class CustomColorPicker extends StatefulWidget {
  final Color? initialColor; // Pass the initial selected color

  const CustomColorPicker({super.key, this.initialColor});

  @override
  _CustomColorPickerState createState() => _CustomColorPickerState();
}

class _CustomColorPickerState extends State<CustomColorPicker> {
  final List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
  ];

  Color? selectedColor; // To track the currently selected color

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor; // Set the initial selected color
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text("Pick a Color"),
      children: colors.map((color) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedColor = color;
            });
            Navigator.pop(context, color); // Return the selected color
          },
          child: Container(
            height: 50,
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    selectedColor == color ? Colors.black : Colors.transparent,
                width: 3,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
