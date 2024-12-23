import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'drawing_page.dart';
import 'dart:convert';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> _drawings = [];

  @override
  void initState() {
    super.initState();
    _fetchDrawings();
  }

  Future<void> _fetchDrawings() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception("User not signed in");

      final List<dynamic> response = await Supabase.instance.client
          .from('drawings')
          .select('id, name, created_at, drawing')
          .eq('user_id', userId);

      setState(() {
        _drawings = response.map<Map<String, dynamic>>((drawing) {
          final drawingData = drawing['drawing'] as String;
          final id = drawing['id'].toString();
          final name = drawing['name'] as String;
          final createdAt = drawing['created_at'] as String;

          try {
            final List<dynamic> decodedPoints = jsonDecode(drawingData);
            final points = decodedPoints.map<DrawingPoint?>((point) {
              if (point == null) return null;
              return DrawingPoint(
                point: Offset(
                  (point['x'] as num).toDouble(),
                  (point['y'] as num).toDouble(),
                ),
                color: Color(point['color'] as int),
                strokeWidth: (point['strokeWidth'] as num).toDouble(),
              );
            }).toList();

            return {
              'id': id,
              'name': name,
              'created_at': createdAt,
              'points': points,
            };
          } catch (e) {
            print("Error decoding drawing $id: $e");
            return {
              'id': id,
              'name': name,
              'created_at': createdAt,
              'points': <DrawingPoint?>[],
            };
          }
        }).toList();
      });
    } catch (e) {
      print("Error fetching drawings: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch drawings: $e")),
      );
    }
  }

  Future<void> _navigateToDrawingPage({
    String? id,
    String? name,
    List<DrawingPoint?>? points,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingPage(
          drawingId: id,
          initialName: name ?? "Drawing Canvas",
          initialPoints: points ?? [],
        ),
      ),
    );
    _fetchDrawings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Whiteboards")),
      body: _drawings.isEmpty
          ? Center(
              child: Text(
                "No whiteboards found. Tap + to create a new one!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _drawings.length,
              itemBuilder: (context, index) {
                final drawing = _drawings[index];
                final points = drawing['points'] as List<DrawingPoint?>;
                final id = drawing['id'] as String;
                final name = drawing['name'] as String;
                final createdAt = drawing['created_at'] as String;

                return GestureDetector(
                  onTap: () => _navigateToDrawingPage(
                    id: id,
                    name: name,
                    points: points,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              spreadRadius: 1,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final scaledPoints = points.map((point) {
                                if (point == null) return null;
                                return DrawingPoint(
                                  point: Offset(
                                    point.point.dx * constraints.maxWidth / 400,
                                    point.point.dy *
                                        constraints.maxHeight /
                                        400,
                                  ),
                                  color: point.color,
                                  strokeWidth: point.strokeWidth *
                                      (constraints.maxWidth / 400),
                                );
                              }).toList();

                              return CustomPaint(
                                painter: DrawingPainter(scaledPoints),
                                size: Size(constraints.maxWidth,
                                    constraints.maxHeight),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "Created: $createdAt",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToDrawingPage(),
        child: Icon(Icons.add),
        tooltip: "New Whiteboard",
      ),
    );
  }
}
