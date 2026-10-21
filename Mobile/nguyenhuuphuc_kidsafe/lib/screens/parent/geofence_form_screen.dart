import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/geofence_model.dart';
import '../../providers/children_provider.dart';
import '../../providers/geofence_provider.dart';
import '../../theme/app_theme.dart';

class GeofenceFormScreen extends StatefulWidget {
  final GeofenceModel? geofence;

  const GeofenceFormScreen({super.key, this.geofence});

  @override
  State<GeofenceFormScreen> createState() => _GeofenceFormScreenState();
}

class _GeofenceFormScreenState extends State<GeofenceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late double _radius;
  late bool _notifyOnExit;
  late bool _notifyOnEntry;

  bool get isEditing => widget.geofence != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.geofence?.name ?? '');
    _latController = TextEditingController(
      text: widget.geofence != null ? widget.geofence!.latitude.toString() : '10.7769',
    );
    _lngController = TextEditingController(
      text: widget.geofence != null ? widget.geofence!.longitude.toString() : '106.7009',
    );
    _radius = widget.geofence?.radiusMeters ?? 200.0;
    _notifyOnExit = widget.geofence?.notifyOnExit ?? true;
    _notifyOnEntry = widget.geofence?.notifyOnEntry ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _fillPreset(String name, double lat, double lng, double radius) {
    setState(() {
      _nameController.text = name;
      _latController.text = lat.toString();
      _lngController.text = lng.toString();
      _radius = radius;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final geoProvider = Provider.of<GeofenceProvider>(context, listen: false);
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final childId = childrenProvider.selectedChild?.id ?? 'ch_01';

    final lat = double.tryParse(_latController.text.trim()) ?? 10.7769;
    final lng = double.tryParse(_lngController.text.trim()) ?? 106.7009;

    if (isEditing) {
      final updated = widget.geofence!.copyWith(
        name: _nameController.text.trim(),
        latitude: lat,
        longitude: lng,
        radiusMeters: _radius,
        notifyOnExit: _notifyOnExit,
        notifyOnEntry: _notifyOnEntry,
      );
      await geoProvider.updateGeofence(updated);
    } else {
      final newGeo = GeofenceModel(
        id: '',
        childId: childId,
        name: _nameController.text.trim(),
        latitude: lat,
        longitude: lng,
        radiusMeters: _radius,
        notifyOnExit: _notifyOnExit,
        notifyOnEntry: _notifyOnEntry,
      );
      await geoProvider.addGeofence(newGeo);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Đã cập nhật vùng an toàn!' : 'Đã thêm vùng an toàn mới!'),
          backgroundColor: AppTheme.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa Vùng An Toàn' : 'Thêm Vùng An Toàn (CRUD)'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Presets quick-select
              const Text('Chọn nhanh địa điểm mẫu:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.school, size: 14, color: AppTheme.primary),
                    label: const Text('Trường Học (250m)', style: TextStyle(fontSize: 11)),
                    onPressed: () => _fillPreset('Trường Tiểu Học Nguyễn Huệ', 10.7769, 106.7009, 250.0),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.home, size: 14, color: AppTheme.accent),
                    label: const Text('Nhà Riêng (150m)', style: TextStyle(fontSize: 11)),
                    onPressed: () => _fillPreset('Nhà Riêng (Chung cư Sunview)', 10.7820, 106.6950, 150.0),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.park, size: 14, color: AppTheme.secondary),
                    label: const Text('Công Viên (300m)', style: TextStyle(fontSize: 11)),
                    onPressed: () => _fillPreset('Công Viên Tao Đàn', 10.7740, 106.6920, 300.0),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tên vùng
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên vùng an toàn *',
                  hintText: 'VD: Trường Tiểu Học, Nhà Bà Ngoại',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên địa điểm' : null,
              ),
              const SizedBox(height: 16),

              // Tọa độ
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Vĩ độ (Lat) *'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nhập vĩ độ' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Kinh độ (Lng) *'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nhập kinh độ' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Radius Slider
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bán kính an toàn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          '${_radius.toStringAsFixed(0)} mét',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16),
                        ),
                      ],
                    ),
                    Slider(
                      value: _radius,
                      min: 50.0,
                      max: 1000.0,
                      divisions: 19,
                      activeColor: AppTheme.primary,
                      onChanged: (val) => setState(() => _radius = val),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('50m (Nhà nhỏ)', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        Text('1000m (Khu vực lớn)', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notification toggles
              SwitchListTile(
                value: _notifyOnExit,
                title: const Text('Báo động khi bé RỜI KHỎI vùng này'),
                subtitle: const Text('Gửi thông báo tức thì đến điện thoại phụ huynh', style: TextStyle(fontSize: 12)),
                activeColor: AppTheme.primary,
                onChanged: (val) => setState(() => _notifyOnExit = val),
              ),
              SwitchListTile(
                value: _notifyOnEntry,
                title: const Text('Báo động khi bé ĐẾN vùng này'),
                subtitle: const Text('Ví dụ: Bé đã đến trường an toàn lúc 7:00 sáng', style: TextStyle(fontSize: 12)),
                activeColor: AppTheme.primary,
                onChanged: (val) => setState(() => _notifyOnEntry = val),
              ),
              const SizedBox(height: 28),

              // Nút Lưu
              ElevatedButton.icon(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  isEditing ? 'Cập Nhật Vùng An Toàn' : 'Tạo Vùng An Toàn Mới',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
