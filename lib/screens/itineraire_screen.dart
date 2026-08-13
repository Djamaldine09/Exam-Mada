import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class ItineraireScreen extends StatefulWidget {
  final String centreName;
  final String? adresse;
  final String? ville;
  final double? latitude;
  final double? longitude;

  const ItineraireScreen({
    super.key,
    required this.centreName,
    this.adresse,
    this.ville,
    this.latitude,
    this.longitude,
  });

  @override
  State<ItineraireScreen> createState() => _ItineraireScreenState();
}

class _ItineraireScreenState extends State<ItineraireScreen> {
  static const _madagascarCenter = LatLng(-18.8792, 47.5079);

  bool _isLoading = true;
  bool _hasError = false;
  String _message = 'Chargement de la localisation...';
  LatLng _location = _madagascarCenter;

  @override
  void initState() {
    super.initState();
    _prepareCentreLocation();
  }

  Future<void> _prepareCentreLocation() async {
    try {
      if (widget.latitude != null && widget.longitude != null) {
        _location = LatLng(widget.latitude!, widget.longitude!);
      } else {
        final query = _buildAddressQuery();
        if (query.isEmpty) {
          throw Exception('Adresse du centre indisponible.');
        }

        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeQueryComponent(query)}&format=json&limit=1&countrycodes=mg',
        );
        final response = await http.get(uri, headers: {'User-Agent': 'ExamGest/1.0'}).timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) {
          throw Exception('Échec du géocodage du centre.');
        }

        final body = jsonDecode(response.body);
        if (body is List && body.isNotEmpty) {
          final first = body.first;
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lon = double.tryParse(first['lon']?.toString() ?? '');
          if (lat == null || lon == null) {
            throw Exception('Coordonnées invalides reçues.');
          }
          _location = LatLng(lat, lon);
        } else {
          throw Exception('Aucune localisation trouvée pour cette adresse.');
        }
      }

      setState(() {
        _isLoading = false;
        _hasError = false;
        _message = 'Centre localisé avec succès.';
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _message = error.toString();
      });
    }
  }

  String _buildAddressQuery() {
    final parts = <String>[];
    if (widget.adresse != null && widget.adresse!.trim().isNotEmpty) {
      parts.add(widget.adresse!.trim());
    }
    if (widget.ville != null && widget.ville!.trim().isNotEmpty) {
      parts.add(widget.ville!.trim());
    }
    return parts.join(', ');
  }

  Future<void> _openDirections() async {
    final destination = _location;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir l’itinéraire.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Itinéraire vers le centre';
    final address = _buildAddressQuery();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorBody(address)
              : _buildMapBody(address),
    );
  }

  Widget _buildErrorBody(String address) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 20),
          Text(
            'Impossible de localiser le centre',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          if (address.isNotEmpty)
            Text(
              'Adresse recherchée : $address',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _prepareCentreLocation,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBody(String address) {
    final centreTitle = widget.centreName.isNotEmpty ? widget.centreName : 'Centre d’examen';

    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              center: _location,
              zoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.examgest.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _location,
                    width: 48,
                    height: 48,
                    builder: (context) => const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -2)),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                centreTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (address.isNotEmpty)
                Text(
                  address,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _openDirections,
                icon: const Icon(Icons.navigation),
                label: const Text('Ouvrir l’itinéraire Google Maps'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 12),
              Text(
                'La carte est fournie par OpenStreetMap. Vous pouvez ouvrir l’itinéraire dans Google Maps ou votre navigateur par défaut.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
