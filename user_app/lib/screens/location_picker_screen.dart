import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.serviceType});

  final String? serviceType;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(13.0827, 80.2707); // Chennai
  LatLng? _selectedLocation;
  bool _isLocating = false;

  List<NearbyWorker> _workers = [];
  bool _loadingWorkers = false;
  String? _workerError;
  bool _isGeocoding = false;
  final TextEditingController _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _useCurrentLocation();
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied. Please enable them in settings.'),
          ),
        );
      }
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  void _useCurrentLocation() async {
    setState(() => _isLocating = true);
    final position = await _determinePosition();
    setState(() => _isLocating = false);

    if (position != null) {
      final point = LatLng(position.latitude, position.longitude);
      _mapController.move(point, 15.0);
      _updateLocation(point);
    } else {
      // Fallback to initial center if location fails
      _updateLocation(_initialCenter);
    }
  }

  Future<void> _updateLocation(LatLng point) async {
    setState(() {
      _selectedLocation = point;
      _isGeocoding = true;
      _loadingWorkers = true;
      _workerError = null;
    });

    // 1. Reverse Geocode via OpenStreetMap Nominatim
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}'
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'com.urban.service_app',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final displayName = data['display_name'] as String?;
        if (displayName != null && mounted) {
          setState(() {
            _addressCtrl.text = displayName;
          });
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }

    // 2. Fetch Nearby Workers within 10KM
    try {
      final api = context.read<ApiService>();
      final workers = await api.fetchNearbyWorkers(
        point.latitude,
        point.longitude,
        radius: 10.0,
        serviceType: widget.serviceType,
      );
      if (mounted) {
        setState(() {
          _workers = workers;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _workerError = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loadingWorkers = false);
    }
  }

  Future<void> _promptAddNewAddress(BuildContext context) async {
    final addrCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'Home');

    final newAddress = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Booking Address', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a new location address to save to your account.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 14),
            TextField(
              controller: addrCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Flat/House No, Street, Area, City',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (addrCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx, addrCtrl.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save & Select', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newAddress != null && newAddress.isNotEmpty && mounted) {
      setState(() {
        _addressCtrl.text = newAddress;
      });
      final api = context.read<ApiService>();
      await api.createAddress({
        'address': newAddress,
        'title': typeCtrl.text,
      });
      _searchAddress(newAddress);
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isGeocoding = true;
      _loadingWorkers = true;
      _workerError = null;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1'
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'com.urban.service_app',
      });

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'] as String);
          final lon = double.parse(data[0]['lon'] as String);
          final displayName = data[0]['display_name'] as String;
          final point = LatLng(lat, lon);

          setState(() {
            _selectedLocation = point;
            _addressCtrl.text = displayName;
          });

          _mapController.move(point, 15.0);

          // Now fetch nearby workers for this new point
          final api = context.read<ApiService>();
          final workers = await api.fetchNearbyWorkers(
            point.latitude,
            point.longitude,
            radius: 10.0,
            serviceType: widget.serviceType,
          );
          setState(() {
            _workers = workers;
          });
        } else {
          // Smart Fallback Search: Strip door numbers / leading digits before first comma
          List<String> parts = query.split(',');
          if (parts.length > 1) {
            String fallbackQuery = parts.sublist(1).join(',').trim();
            final fallbackUrl = Uri.parse(
              'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(fallbackQuery)}&format=json&limit=1'
            );
            final fbResp = await http.get(fallbackUrl, headers: {'User-Agent': 'com.urban.service_app'});
            if (fbResp.statusCode == 200) {
              final List fbData = jsonDecode(fbResp.body);
              if (fbData.isNotEmpty) {
                final lat = double.parse(fbData[0]['lat'] as String);
                final lon = double.parse(fbData[0]['lon'] as String);
                final point = LatLng(lat, lon);

                setState(() {
                  _selectedLocation = point;
                });
                _mapController.move(point, 15.0);

                final api = context.read<ApiService>();
                final workers = await api.fetchNearbyWorkers(
                  point.latitude,
                  point.longitude,
                  radius: 10.0,
                  serviceType: widget.serviceType,
                );
                setState(() {
                  _workers = workers;
                });
                return;
              }
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not pin exact door number, but location address saved.')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Search address error: $e');
      setState(() {
        _workerError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGeocoding = false;
          _loadingWorkers = false;
        });
      }
    }
  }

  IconData _getServiceIcon(String? serviceType) {
    if (serviceType == null) return Icons.person;
    switch (serviceType.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'electrical':
        return Icons.electrical_services;
      case 'ac service':
        return Icons.ac_unit;
      case 'others':
      default:
        return Icons.construction;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Confirm Location', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // The Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 13.0,
              onTap: (_, point) {
                _updateLocation(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.urban.service_app',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    // Selected Location Marker
                    Marker(
                      point: _selectedLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 45),
                    ),
                    // Nearby Workers Markers
                    ..._workers.map((w) {
                      if (w.latitude == null || w.longitude == null) return null;
                      return Marker(
                        point: LatLng(w.latitude!, w.longitude!),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () {
                            _mapController.move(LatLng(w.latitude!, w.longitude!), 15.0);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${w.name} (${w.serviceType ?? "General"}) is ${w.distance?.toStringAsFixed(1)} km away'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primary, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Icon(_getServiceIcon(w.serviceType), color: AppTheme.primary, size: 24),
                          ),
                        ),
                      );
                    }).whereType<Marker>().toList(),
                  ],
                ),
            ],
          ),

          // Fixed center marker if no selection is made yet
          if (_selectedLocation == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ),

          // Draggable Bottom Sheet for premium experience
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.22,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 5),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  children: [
                    // Grab handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Title & Use GPS button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Confirm Location',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5),
                        ),
                        TextButton.icon(
                          onPressed: _isLocating ? null : _useCurrentLocation,
                          icon: _isLocating
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                              : const Icon(Icons.my_location, size: 16, color: AppTheme.primary),
                          label: const Text('Use GPS', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Saved Addresses Quick Selection Chips
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final permAddr = auth.user?.address;
                        final fullAddr = auth.fullAddress;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (permAddr != null && permAddr.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    avatar: const Icon(Icons.home, size: 16, color: Colors.white),
                                    label: const Text('Permanent Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                    selected: _addressCtrl.text == permAddr,
                                    selectedColor: AppTheme.primary,
                                    backgroundColor: Colors.grey.shade800,
                                    onSelected: (sel) {
                                      if (sel) {
                                        setState(() {
                                          _addressCtrl.text = permAddr;
                                        });
                                        _searchAddress(permAddr);
                                      }
                                    },
                                  ),
                                ),
                               if (fullAddr != null && fullAddr.isNotEmpty && fullAddr != permAddr)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    avatar: const Icon(Icons.work, size: 16),
                                    label: const Text('Work / Secondary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    selected: _addressCtrl.text == fullAddr,
                                    selectedColor: AppTheme.primary,
                                    onSelected: (sel) {
                                      if (sel) {
                                        setState(() {
                                          _addressCtrl.text = fullAddr;
                                        });
                                        _searchAddress(fullAddr);
                                      }
                                    },
                                  ),
                                ),
                              ActionChip(
                                avatar: const Icon(Icons.add_location_alt_rounded, size: 16, color: AppTheme.primary),
                                label: const Text('+ Add New Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary)),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: AppTheme.primary),
                                onPressed: () => _promptAddNewAddress(context),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Address Textbox
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (val) => _searchAddress(val),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: _isGeocoding ? 'Resolving address...' : 'Enter full address...',
                          prefixIcon: _isGeocoding
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : const Icon(Icons.location_on_outlined, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, color: AppTheme.primary),
                            onPressed: () => _searchAddress(_addressCtrl.text),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Location Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(LocationPickerResult(
                          address: _addressCtrl.text,
                          workers: _workers,
                          latitude: _selectedLocation?.latitude,
                          longitude: _selectedLocation?.longitude,
                        ));
                      },
                      child: const Text('Confirm Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),

                    // Nearby Workers Title
                    Row(
                      children: [
                        const Text(
                          'Nearby Workers (within 10KM)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(width: 8),
                        if (_loadingWorkers)
                          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_workers.length}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Workers List
                    if (_loadingWorkers && _workers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                      )
                    else if (_workerError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Error fetching workers: $_workerError',
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      )
                    else if (_workers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'No active workers found near this area',
                              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _workers.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final w = _workers[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              backgroundImage: (w.photoUrl != null && w.photoUrl!.isNotEmpty)
                                  ? NetworkImage(w.photoUrl!)
                                  : null,
                              child: (w.photoUrl == null || w.photoUrl!.isEmpty)
                                  ? Icon(_getServiceIcon(w.serviceType), color: AppTheme.primary)
                                  : null,
                            ),
                            title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Text('${w.serviceType ?? "General"} • ${w.experienceYears} yrs'),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    w.rating.toStringAsFixed(1),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${w.distance?.toStringAsFixed(1) ?? "0.0"} km',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                                const Text('away', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                            onTap: () {
                              if (w.latitude != null && w.longitude != null) {
                                _mapController.move(LatLng(w.latitude!, w.longitude!), 15.0);
                              }
                            },
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
