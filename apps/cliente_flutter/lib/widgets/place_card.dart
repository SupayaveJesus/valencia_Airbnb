import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/place_model.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place, this.onTap});

  final PlaceModel place;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: place.imageUrl.isEmpty
                  ? Container(
                      height: 180,
                      color: const Color(0xFFF1F1F1),
                      alignment: Alignment.center,
                      child: const Icon(Icons.home_work_outlined, size: 48),
                    )
                  : Image.network(
                      place.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        color: const Color(0xFFF1F1F1),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.city, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text(place.name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(
                    place.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(label: place.capacityLabel),
                      _InfoChip(label: '${place.beds} camas'),
                      _InfoChip(label: place.parkingLabel),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    place.priceLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
