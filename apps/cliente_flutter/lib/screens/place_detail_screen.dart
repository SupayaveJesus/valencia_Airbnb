import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/place_model.dart';
import '../models/search_filters.dart';
import '../providers/auth_provider.dart';
import '../providers/places_provider.dart';
import '../widgets/minimal_card.dart';
import '../widgets/primary_button.dart';
import 'reservation_confirmation_screen.dart';

class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({
    super.key,
    required this.placePreview,
    this.filters,
  });

  final PlaceModel placePreview;
  final SearchFilters? filters;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late Future<PlaceModel> _detailFuture;
  int _selectedPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _detailFuture = context.read<PlacesProvider>().loadPlaceDetail(
      widget.placePreview.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del lugar')),
      body: FutureBuilder<PlaceModel>(
        future: _detailFuture,
        initialData: widget.placePreview,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && !snapshot.hasData) {
            return _buildError(context, snapshot.error.toString());
          }

          final place = snapshot.data ?? widget.placePreview;
          final gallery = place.galleryUrls.isEmpty ? [''] : place.galleryUrls;
          final safeIndex = _selectedPhotoIndex >= gallery.length
              ? 0
              : _selectedPhotoIndex;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHeroImage(gallery[safeIndex]),
              if (gallery.length > 1) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 78,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: gallery.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedPhotoIndex = index),
                        child: Container(
                          width: 78,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: safeIndex == index
                                  ? Colors.black
                                  : const Color(0xFFE5E5E5),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            gallery[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                place.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(place.city, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Text(
                place.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              MinimalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos del lugar',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(label: 'Anfitrión', value: place.hostName),
                    _DetailRow(label: 'Personas', value: '${place.capacity}'),
                    _DetailRow(label: 'Camas', value: '${place.beds}'),
                    _DetailRow(label: 'Baños', value: '${place.baths}'),
                    _DetailRow(label: 'Habitaciones', value: '${place.rooms}'),
                    _DetailRow(
                      label: 'Wi-Fi',
                      value: place.hasWifi ? 'Sí' : 'No',
                    ),
                    _DetailRow(label: 'Parqueo', value: place.parkingLabel),
                    _DetailRow(label: 'Precio', value: place.priceLabel),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (widget.filters != null)
                PrimaryButton(
                  label: 'Reservar este lugar',
                  icon: Icons.credit_card_outlined,
                  onPressed: () {
                    final user = context.read<AuthProvider>().currentUser;
                    if (user == null) {
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReservationConfirmationScreen(
                          place: place,
                          filters: widget.filters!,
                          user: user,
                        ),
                      ),
                    );
                  },
                )
              else
                const MinimalCard(
                  child: Text(
                    'Reserva no disponible desde esta vista.',
                  ),
                ),
              if (snapshot.hasError) ...[
                const SizedBox(height: 16),
                Text(
                  'No pudimos actualizar el detalle. ${snapshot.error.toString().replaceFirst('Exception: ', '')}',
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.home_work_outlined, size: 72),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.network(
        imageUrl,
        height: 260,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: 260,
          color: const Color(0xFFF1F1F1),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, size: 72),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String rawMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: MinimalCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                rawMessage.replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Reintentar detalle',
                onPressed: () {
                  setState(() {
                    _detailFuture = context
                        .read<PlacesProvider>()
                        .loadPlaceDetail(widget.placePreview.id);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
