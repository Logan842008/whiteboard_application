import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whiteboard_application/utils/custom_color_picker.dart';

class DrawingPage extends StatefulWidget {
  final String? drawingId; // Changed to String to support UUIDs
  final List<DrawingPoint?> initialPoints;
  final String initialName;

  DrawingPage({
    this.drawingId,
    this.initialPoints = const [],
    this.initialName = "Drawing Canvas",
  });

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  Color selectedColor = Colors.black; // Default drawing color
  late List<DrawingPoint?> points; // List to hold drawing points
  List<List<DrawingPoint?>> undoStack = []; // Undo stack
  List<List<DrawingPoint?>> redoStack = []; // Redo stack
  bool isErasing = false; // Toggle eraser mode
  Color boardColor = Colors.white; // Canvas background color
  late TextEditingController nameController; // Controller for the drawing name
  bool isEditingName = false; // To track if the name is being edited

  @override
  void initState() {
    super.initState();
    points = List.from(widget.initialPoints); // Initialize points
    nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  /// Save the drawing and its name to Supabase
  Future<void> _saveDrawingToDatabase() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception("User not signed in");

      // Convert points to JSON
      final pointsJson = jsonEncode(points.map((point) {
        if (point == null) return null;
        return {
          'x': point.point.dx,
          'y': point.point.dy,
          'color': point.color.value,
          'strokeWidth': point.strokeWidth,
        };
      }).toList());

      if (widget.drawingId != null) {
        // Update existing drawing
        await Supabase.instance.client.from('drawings').update({
          'name': nameController.text,
          'drawing': pointsJson,
        }).eq('id', widget.drawingId!); // Use ! to assert non-null
      } else {
        // Insert new drawing
        await Supabase.instance.client.from('drawings').insert({
          'user_id': userId,
          'name': nameController.text,
          'drawing': pointsJson,
        });
      }

      print("Drawing saved successfully!");
    } catch (e) {
      print("Error saving drawing: $e");
    }
  }

  /// Undo the last action
  void _undo() {
    if (undoStack.isNotEmpty) {
      redoStack.add(List.from(points));
      setState(() {
        points = undoStack.removeLast();
      });
    }
  }

  /// Redo the undone action
  void _redo() {
    if (redoStack.isNotEmpty) {
      undoStack.add(List.from(points));
      setState(() {
        points = redoStack.removeLast();
      });
    }
  }

  /// Clear the canvas
  void _clearCanvas() {
    setState(() {
      undoStack.add(List.from(points));
      points.clear();
    });
  }

  Future<void> _pickColor() async {
    final Color? pickedColor = await showDialog<Color>(
      context: context,
      builder: (context) => CustomColorPicker(initialColor: selectedColor),
    );

    if (pickedColor != null) {
      setState(() {
        selectedColor = pickedColor; // Update the selected color
        isErasing = false; // Ensure we are in drawing mode
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveDrawingToDatabase(); // Save drawing on back press
        return true; // Allow navigation back
      },
      child: Scaffold(
        appBar: AppBar(
          title: isEditingName
              ? TextField(
                  controller: nameController,
                  autofocus: true,
                  onSubmitted: (_) {
                    setState(() {
                      isEditingName = false; // Stop editing on submit
                    });
                  },
                  style: const TextStyle(color: Colors.black, fontSize: 20),
                  decoration: const InputDecoration(
                    hintText: "Enter drawing name",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      isEditingName = true; // Start editing on tap
                    });
                  },
                  child: Text(
                    nameController.text,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        body: GestureDetector(
          onPanStart: (_) => setState(() => undoStack.add(List.from(points))),
          onPanUpdate: (details) {
            setState(() {
              points.add(DrawingPoint(
                point: details.localPosition,
                color: isErasing ? boardColor : selectedColor,
                strokeWidth: isErasing ? 20 : 5,
              ));
            });
          },
          onPanEnd: (_) => setState(() => points.add(null)),
          child: Container(
            color: boardColor,
            child: CustomPaint(
              painter: DrawingPainter(points),
              size: Size.infinite,
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.grey[200],
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Pen Button
                InkWell(
                  onTap: _pickColor, // Open color picker
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.pen,
                        color: selectedColor,
                        size: 28,
                      ),
                    ],
                  ),
                ),

                // Eraser Button
                InkWell(
                  onTap: () {
                    setState(() {
                      isErasing = true;
                      selectedColor =
                          boardColor; // Ensure eraser uses board color
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.eraser,
                        color: isErasing ? Colors.red : Colors.black,
                        size: 28,
                      ),
                    ],
                  ),
                ),

                // Clear Button
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.trash, color: Colors.black),
                  onPressed: _clearCanvas,
                  tooltip: "Clear Canvas",
                ),

                // Undo Button
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.rotateLeft,
                      color: Colors.black),
                  onPressed: _undo,
                  tooltip: "Undo",
                ),

                // Redo Button
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.rotateRight,
                      color: Colors.black),
                  onPressed: _redo,
                  tooltip: "Redo",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      final currentPoint = points[i];
      final nextPoint = points[i + 1];
      if (currentPoint != null && nextPoint != null) {
        final paint = Paint()
          ..color = currentPoint.color
          ..strokeWidth = currentPoint.strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(currentPoint.point, nextPoint.point, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawingPoint {
  final Offset point;
  final Color color;
  final double strokeWidth;

  DrawingPoint({
    required this.point,
    required this.color,
    required this.strokeWidth,
  });
}
