import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import 'settings_screen.dart';

class Delivery {
  final String id;
  final String businessName;
  final String deliveryDate;
  final LatLng location;

  const Delivery({
    required this.id,
    required this.businessName,
    required this.deliveryDate,
    required this.location,
  });

  factory Delivery.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Delivery(
      id: doc.id,
      businessName: d['businessName'] as String? ?? '',
      deliveryDate: d['deliveryDate'] as String? ?? '',
      location: LatLng(
        (d['lat'] as num).toDouble(),
        (d['lng'] as num).toDouble(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MapController _mapController = MapController();
  final _authService = AuthService();
  int? _selectedIndex;
  String? _companyId;
  LatLng _mapCenter = const LatLng(41.0082, 28.9784);

  @override
  void initState() {
    super.initState();
    _authService.getUserData().then((data) {
      if (mounted) setState(() => _companyId = data?['companyId'] as String?);
    });
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        final loc = LatLng(pos.latitude, pos.longitude);
        setState(() => _mapCenter = loc);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _mapController.move(loc, 14.0);
        });
      }
    } catch (_) {}
  }

  void _onDeliveryTap(int index, List<Delivery> deliveries) {
    setState(() => _selectedIndex = index);
    _mapController.move(deliveries[index].location, 14.0);
  }

  void _showAddDelivery(String companyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddDeliverySheet(companyId: companyId),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final companyId = _companyId;

    return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          floatingActionButton: companyId == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(bottom: 12, right: 12),
                  child: FloatingActionButton(
                    onPressed: () => _showAddDelivery(companyId),
                    backgroundColor: const Color(0xFF3949AB),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: Column(
            children: [
              // ── AppBar ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3949AB),
                      const Color(0xFF3949AB).withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3949AB).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.map_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: companyId == null
                              ? null
                              : FirebaseFirestore.instance
                                  .collection('companies')
                                  .doc(companyId)
                                  .collection('deliveries')
                                  .snapshots(),
                          builder: (context, snap) {
                            final count = snap.data?.docs.length ?? 0;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bayi Haritası',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Text(
                                  '$count aktif teslimat',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          ),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.settings_outlined,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Harita ──────────────────────────────────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: StreamBuilder<List<Delivery>>(
                      stream: companyId == null
                          ? null
                          : FirebaseFirestore.instance
                              .collection('companies')
                              .doc(companyId)
                              .collection('deliveries')
                              .snapshots()
                              .map((s) =>
                                  s.docs.map(Delivery.fromFirestore).toList()),
                      builder: (context, snap) {
                        final deliveries = snap.data ?? [];
                        return Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _mapCenter,
                                initialZoom: 14.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.bayimap',
                                ),
                                MarkerLayer(
                                  markers: List.generate(deliveries.length,
                                      (i) {
                                    final isSelected = _selectedIndex == i;
                                    return Marker(
                                      point: deliveries[i].location,
                                      width: 44,
                                      height: 44,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _onDeliveryTap(i, deliveries),
                                        child: Icon(
                                          Icons.location_pin,
                                          color: isSelected
                                              ? Colors.redAccent
                                              : const Color(0xFF3949AB),
                                          size: isSelected ? 44 : 34,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant
                                          .withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Liste ──────────────────────────────────────────
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: StreamBuilder<List<Delivery>>(
                    stream: companyId == null
                        ? null
                        : FirebaseFirestore.instance
                            .collection('companies')
                            .doc(companyId)
                            .collection('deliveries')
                            .orderBy('createdAt', descending: false)
                            .snapshots()
                            .map((s) =>
                                s.docs.map(Delivery.fromFirestore).toList()),
                    builder: (context, snap) {
                      final deliveries = snap.data ?? [];

                      return Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDark ? 0.3 : 0.07),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 8),
                              child: Row(
                                children: [
                                  Text(
                                    'Teslimatlar',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${deliveries.length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                                height: 1,
                                color: colorScheme.outlineVariant),
                            Expanded(
                              child: deliveries.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.location_off_outlined,
                                              size: 36,
                                              color: colorScheme
                                                  .onSurfaceVariant),
                                          const SizedBox(height: 8),
                                          Text(
                                            '+ butonuyla teslimat ekle',
                                            style: TextStyle(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.only(bottom: 80),
                                      itemCount: deliveries.length,
                                      separatorBuilder: (_, __) => Divider(
                                          height: 1,
                                          indent: 72,
                                          color: colorScheme.outlineVariant),
                                      itemBuilder: (context, index) {
                                        final d = deliveries[index];
                                        final isSelected =
                                            _selectedIndex == index;
                                        return ListTile(
                                          selected: isSelected,
                                          selectedTileColor: const Color(
                                                  0xFF3949AB)
                                              .withOpacity(0.1),
                                          leading: CircleAvatar(
                                            backgroundColor: isSelected
                                                ? const Color(0xFF3949AB)
                                                : colorScheme
                                                    .primaryContainer,
                                            child: Text(
                                              d.businessName.isNotEmpty
                                                  ? d.businessName[0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : colorScheme
                                                        .onPrimaryContainer,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            d.businessName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14),
                                          ),
                                          subtitle: Row(
                                            children: [
                                              Icon(Icons.calendar_today,
                                                  size: 11,
                                                  color: const Color(
                                                          0xFF3949AB)
                                                      .withOpacity(0.7)),
                                              const SizedBox(width: 4),
                                              Text(
                                                d.deliveryDate,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                        color: colorScheme
                                                            .onSurfaceVariant),
                                              ),
                                            ],
                                          ),
                                          trailing: Icon(
                                              Icons.chevron_right,
                                              color: colorScheme
                                                  .outlineVariant),
                                          onTap: () => _onDeliveryTap(
                                              index, deliveries),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
  }
}

// ── Teslimat Ekleme Bottom Sheet ─────────────────────────────────

class _AddDeliverySheet extends StatefulWidget {
  final String companyId;
  const _AddDeliverySheet({required this.companyId});

  @override
  State<_AddDeliverySheet> createState() => _AddDeliverySheetState();
}

class _AddDeliverySheetState extends State<_AddDeliverySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final MapController _mapController = MapController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  LatLng? _pickedLocation;
  bool _pickingMode = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Haritadan konum seçiniz')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('deliveries')
          .add({
        'businessName': _nameCtrl.text.trim(),
        'deliveryDate':
            '${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}',
        'lat': _pickedLocation!.latitude,
        'lng': _pickedLocation!.longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _monthName(int m) => [
        '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ][m];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text('Yeni Teslimat',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                physics: _pickingMode ? const NeverScrollableScrollPhysics() : null,
                padding: const EdgeInsets.all(20),
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // İşletme adı
                        Text('İşletme Adı',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            hintText: 'Örn: Ahmet\'s Market',
                            prefixIcon: const Icon(Icons.store_outlined,
                                size: 20),
                            filled: true,
                            fillColor: colorScheme.surfaceContainer,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: colorScheme.outlineVariant),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFF3949AB), width: 1.5),
                            ),
                          ),
                          validator: (v) =>
                              v!.trim().isEmpty ? 'İşletme adı giriniz' : null,
                        ),
                        const SizedBox(height: 16),

                        // Teslimat tarihi
                        Text('Teslimat Tarihi',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: colorScheme.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 12),
                                Text(
                                  '${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const Spacer(),
                                Icon(Icons.edit_outlined,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Konum seçimi
                        Row(
                          children: [
                            Text('Konum',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () =>
                                  setState(() => _pickingMode = !_pickingMode),
                              icon: Icon(
                                _pickingMode
                                    ? Icons.close
                                    : Icons.touch_app_outlined,
                                size: 16,
                              ),
                              label: Text(_pickingMode
                                  ? 'İptal'
                                  : 'Haritadan seç'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF3949AB),
                              ),
                            ),
                          ],
                        ),
                        if (_pickedLocation != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3949AB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 16, color: Color(0xFF3949AB)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_pickedLocation!.latitude.toStringAsFixed(5)}, '
                                    '${_pickedLocation!.longitude.toStringAsFixed(5)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF3949AB)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_pickingMode)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Haritada konuma dokun',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 220,
                            child: Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _pickedLocation ??
                                        const LatLng(41.0082, 28.9784),
                                    initialZoom: 12.0,
                                    onTap: _pickingMode
                                        ? (_, point) {
                                            setState(() {
                                              _pickedLocation = point;
                                              _pickingMode = false;
                                            });
                                            _mapController.move(point, _mapController.camera.zoom);
                                          }
                                        : null,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.bayimap',
                                    ),
                                    if (_pickedLocation != null)
                                      MarkerLayer(markers: [
                                        Marker(
                                          point: _pickedLocation!,
                                          width: 40,
                                          height: 40,
                                          child: const Icon(
                                            Icons.location_pin,
                                            color: Color(0xFF3949AB),
                                            size: 40,
                                          ),
                                        ),
                                      ]),
                                  ],
                                ),
                                if (_pickingMode)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3949AB)
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFF3949AB),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.touch_app,
                                            color: Color(0xFF3949AB),
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3949AB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Text('Kaydet',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
