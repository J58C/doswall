import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';

class PresenceDetailsCard extends StatelessWidget {
  final bool isActive;
  final bool isFetchingLocation;
  final bool updatingStatus;
  final LatLng? currentLatLng;
  final List<String> locationOptions;
  final String? selectedLocation;
  final Map<String, dynamic>? user;
  final ValueChanged<String?> onLocationChanged;
  final VoidCallback onRefresh;
  final ValueChanged<bool> updateStatus;

  const PresenceDetailsCard({
    super.key,
    required this.isActive,
    required this.isFetchingLocation,
    required this.updatingStatus,
    this.currentLatLng,
    required this.locationOptions,
    this.selectedLocation,
    this.user,
    required this.onLocationChanged,
    required this.onRefresh,
    required this.updateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isAvailable = user?['status'] == 1;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      shadowColor: darkTextColor.withAlpha(50),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Kehadiran',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: onRefresh,
                      tooltip: 'Muat Ulang Data Lokasi',
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: currentLatLng != null
                        ? Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: currentLatLng!,
                            initialZoom: 17.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.unnes.doswall',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: currentLatLng!,
                                  width: 80,
                                  height: 80,
                                  alignment: Alignment.topCenter,
                                  child: const Icon(
                                    Icons.location_pin,
                                    size: 60,
                                    color: errorRedColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(38),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedLocation,
                                isExpanded: false,
                                hint: const Text('Pilih Lokasi Geotag'),
                                icon:
                                const Icon(Icons.keyboard_arrow_down),
                                items:
                                locationOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value,
                                        overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: onLocationChanged,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                        : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16.0),
                      child: const Text(
                        'Lokasi tidak ditemukan.\nPastikan GPS aktif dan coba muat ulang.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 14,
                          color: isAvailable
                              ? successGreenColor
                              : accentOrangeColor,
                        ),
                        const SizedBox(width: 8),
                        const Text('Status Saat Ini:',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          isAvailable ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isAvailable
                                ? successGreenColor
                                : accentOrangeColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          height: 40,
                          child: Align(
                            alignment: Alignment.center,
                            child: updatingStatus
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5),
                            )
                                : Switch(
                              value: isAvailable,
                              onChanged: updateStatus,
                              activeColor: successGreenColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: _buildContentOverlay(
              isActive: isActive,
              isFetchingLocation: isFetchingLocation,
              context: context,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentOverlay({
    required BuildContext context,
    required bool isActive,
    required bool isFetchingLocation,
  }) {
    final bool shouldShowOverlay = !isActive || isFetchingLocation;

    return AnimatedOpacity(
      opacity: shouldShowOverlay ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !shouldShowOverlay,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Container(
            color: Theme.of(context).cardColor.withAlpha(128),
            alignment: Alignment.center,
            child: _buildOverlayContent(
              context: context,
              isFetchingLocation: isFetchingLocation,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayContent({
    required BuildContext context,
    required bool isFetchingLocation,
  }) {
    final style = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.bold);

    if (isFetchingLocation) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Memuat data lokasi...', style: style),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        'Aktifkan presensi untuk mendapatkan data lokasi',
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}