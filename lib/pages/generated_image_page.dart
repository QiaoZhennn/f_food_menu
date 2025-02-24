import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/image_generation_service.dart';
import '../services/image_search_service.dart';

class GeneratedImagePage extends StatefulWidget {
  final FoodItem? foodItem;

  const GeneratedImagePage({
    super.key,
    this.foodItem,
  });

  @override
  State<GeneratedImagePage> createState() => _GeneratedImagePageState();
}

class _GeneratedImagePageState extends State<GeneratedImagePage> {
  String? _imageUrl;
  String? _prompt;
  List<String> _searchResults = [];
  bool _isGenerating = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchImages();
  }

  Future<void> _searchImages() async {
    if (widget.foodItem == null) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final searchQuery = widget.foodItem!.drinkFlavor.isNotEmpty
          ? 'drink image of ${widget.foodItem!.name}'
          : 'food image of ${widget.foodItem!.name}';
      final results = await ImageSearchService.searchImages(searchQuery);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching images: $e')),
        );
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _generateImage() async {
    if (widget.foodItem == null) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final result =
          await ImageGenerationService.generateImage(widget.foodItem!);
      if (mounted) {
        setState(() {
          _imageUrl = result['imageUrl'];
          _prompt = result['prompt'];
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.foodItem == null) {
      return const Center(child: Text('No food item selected'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Similar images for "${widget.foodItem!.name}":',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            const Center(child: CircularProgressIndicator())
          else if (_searchResults.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _searchResults[index],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateImage,
              child: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate AI Image'),
            ),
          ),
          if (_imageUrl != null) ...[
            const SizedBox(height: 32),
            Text(
              'Generated Image:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _imageUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ),
          ],
          if (_prompt != null) ...[
            const SizedBox(height: 16),
            Text(
              'Prompt used:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_prompt!),
          ],
        ],
      ),
    );
  }
}
