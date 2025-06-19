import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';

class MapCard extends StatelessWidget {
  final LatLng? currentLatLng;
  final List<String> locationOptions;
  final String? selectedLocation;
  final bool isFetchingLocation;
  final bool isInteractable;
  final void Function() onRefresh;
  final void Function(String?) onLocationChanged;

  const MapCard({
    super.key,
    required this.currentLatLng,
    required this.locationOptions,
    this.selectedLocation,
    required this.isFetchingLocation,
    required this.isInteractable,
    required this.onRefresh,
    required this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validSelectedLocation = (locationOptions.isNotEmpty && locationOptions.contains(selectedLocation))
        ? selectedLocation
        : (locationOptions.isNotEmpty ? locationOptions[0] : null);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
            child: Row(
              children: [
                Expanded(child: Text('Lokasi', style: theme.textTheme.titleLarge)),
                SizedBox(
                  width: 48.0,
                  height: 48.0,
                  child: isFetchingLocation
                      ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)))
                      : IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Ambil Ulang Lokasi',
                    onPressed: isInteractable ? onRefresh : null,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: Opacity(
              opacity: isInteractable ? 1.0 : 0.6,
              child: IgnorePointer(
                ignoring: !isInteractable,
                child: Stack(
                  children: [
                    if (currentLatLng != null)
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: currentLatLng!,
                          initialZoom: 17.5,
                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                        ),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', tileProvider: CancellableNetworkTileProvider()),
                          MarkerLayer(markers: [Marker(point: currentLatLng!, width: 40, height: 40, child: Icon(Icons.location_pin, color: theme.colorScheme.error, size: 40))]),
                        ],
                      )
                    else
                      Container(color: theme.colorScheme.surfaceContainerHighest, child: const Center(child: Text('Data Peta Tidak Tersedia'))),
                    Positioned(
                      top: 10, left: 12, right: 12,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: DropdownButtonFormField<String>(
                          value: validSelectedLocation,
                          items: locationOptions.map((loc) => DropdownMenuItem<String>(value: loc, child: Text(loc, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: onLocationChanged,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.cardColor.withAlpha(240),
                            hintText: 'Pilih Lokasi Terdekat',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}