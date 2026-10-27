import 'package:flutter/material.dart';

import 'drawing_screen.dart';
import 'models.dart';
import 'painter.dart';
import 'store.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final drawings = store.drawings;
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(title: const Text('SketchPad')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _open(context, null),
            icon: const Icon(Icons.add),
            label: const Text('New sketch'),
          ),
          body: !store.loaded
              ? const Center(child: CircularProgressIndicator())
              : drawings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.draw_outlined,
                            size: 72,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text('No drawings yet',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('Tap "New sketch" to start drawing.',
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: drawings.length,
                      itemBuilder: (context, index) {
                        final drawing = drawings[index];
                        return DrawingCard(
                          drawing: drawing,
                          onOpen: () => _open(context, drawing),
                          onDelete: () => store.delete(drawing.id),
                        );
                      },
                    ),
        );
      },
    );
  }

  Future<void> _open(BuildContext context, Drawing? drawing) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DrawingScreen(drawing: drawing)),
    );
  }
}

class DrawingCard extends StatelessWidget {
  const DrawingCard({
    super.key,
    required this.drawing,
    required this.onOpen,
    required this.onDelete,
  });

  final Drawing drawing;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: kCanvasColor,
                padding: const EdgeInsets.all(6),
                child: drawing.isBlank
                    ? Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                      )
                    : CustomPaint(
                        painter:
                            DrawingThumbnailPainter(strokes: drawing.strokes),
                        size: Size.infinite,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      drawing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
