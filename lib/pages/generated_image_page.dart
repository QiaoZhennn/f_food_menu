import 'package:flutter/material.dart';

class GeneratedImagePage extends StatelessWidget {
  final String imageUrl;
  final String prompt;

  const GeneratedImagePage({
    super.key,
    required this.imageUrl,
    required this.prompt,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            imageUrl,
            width: double.infinity,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Prompt used:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(prompt),
        ],
      ),
    );
  }
}
