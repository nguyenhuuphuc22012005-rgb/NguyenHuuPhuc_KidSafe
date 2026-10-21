import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/children_provider.dart';
import '../../theme/app_theme.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with SingleTickerProviderStateMixin {
  late final MobileScannerController _cameraController;
  late final AnimationController _laserController;
  late final Animation<double> _laserAnimation;

  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
    );

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        _processScannedCode(rawValue.trim());
        break;
      }
    }
  }

  void _processScannedCode(String raw) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    String deviceId = raw;
    String childName = 'Thiết Bị Điện Thoại Trẻ Em';

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('device_id')) {
          deviceId = decoded['device_id'].toString();
        }
        if (decoded.containsKey('name')) {
          childName = decoded['name'].toString();
        }
      }
    } catch (_) {
      // Plain text code
      if (raw.toUpperCase().contains('BO')) {
        childName = 'Bé Bo (Gia Bảo)';
      } else if (raw.toUpperCase().contains('BONG')) {
        childName = 'Bé Bông (Mai Anh)';
      }
    }

    _onScanSuccess(deviceId, childName);
  }

  void _onScanSuccess(String deviceId, String childName) {
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    childrenProvider.pairWithDeviceId(deviceId, childName);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 28),
            SizedBox(width: 10),
            Text('Nhận Diện Thành Công!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Camera đã quét và giải mã thành công mã QR thiết bị:',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: AppTheme.accent, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tên: $childName',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mã ID: $deviceId',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Thiết bị đã được kết nối với tài khoản phụ huynh. Bây giờ bạn có thể định vị GPS, đo âm thanh môi trường và cài đặt lịch học!',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Bắt Đầu Giám Sát'),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    final codeController = TextEditingController(text: 'DEV-KID-BO-8821');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nhập Mã Thiết Bị', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nhập mã định danh trên màn hình điện thoại của bé:',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Mã thiết bị (Device ID)',
                prefixIcon: Icon(Icons.qr_code_scanner, size: 20),
                hintText: 'VD: DEV-KID-BO-8821',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              Navigator.pop(ctx);
              if (code.isNotEmpty) {
                _processScannedCode(code);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Ghép Nối'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const scanBoxSize = 260.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quét Camera Mã QR Thật', style: TextStyle(color: Colors.white, fontSize: 17)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Nút bật / tắt Flash
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? Colors.amberAccent : Colors.white70,
            ),
            tooltip: 'Đèn Flash',
            onPressed: () async {
              await _cameraController.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          // Nút đảo camera trước / sau
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white70),
            tooltip: 'Đổi Camera',
            onPressed: () async {
              await _cameraController.switchCamera();
            },
          ),
          // Nút nhập tay
          IconButton(
            icon: const Icon(Icons.keyboard_alt_outlined, color: Colors.white70),
            tooltip: 'Nhập tay',
            onPressed: _showManualInputDialog,
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. CAMERA THỰC TẾ
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off_rounded, size: 56, color: Colors.white54),
                      const SizedBox(height: 16),
                      const Text(
                        'Không thể khởi động Camera',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vui lòng cấp quyền Camera trong Cài đặt thiết bị hoặc sử dụng tính năng nhập mã.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _showManualInputDialog,
                        icon: const Icon(Icons.keyboard, size: 16),
                        label: const Text('Nhập Mã Thủ Công'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. KHUNG NGẮM QUÉT TRONG SUỐT (VIEWFINDER OVERLAY)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Container(
                      width: scanBoxSize,
                      height: scanBoxSize,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. 4 GÓC VIỀN BO KHUNG NGẮM & TIA LASER QUÉT
          Center(
            child: SizedBox(
              width: scanBoxSize,
              height: scanBoxSize,
              child: Stack(
                children: [
                  // 4 Góc viền thẩm mỹ (Corner Markers)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF00E5FF), width: 4),
                          left: BorderSide(color: Color(0xFF00E5FF), width: 4),
                        ),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF00E5FF), width: 4),
                          right: BorderSide(color: Color(0xFF00E5FF), width: 4),
                        ),
                        borderRadius: BorderRadius.only(topRight: Radius.circular(16)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF00E5FF), width: 4),
                          left: BorderSide(color: Color(0xFF00E5FF), width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF00E5FF), width: 4),
                          right: BorderSide(color: Color(0xFF00E5FF), width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(16)),
                      ),
                    ),
                  ),

                  // Tia Laser Quét chuyển động
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _laserAnimation.value * (scanBoxSize - 10),
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.transparent, Color(0xFF00E5FF), Colors.transparent],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 4. HƯỚNG DẪN & CÔNG CỤ NHANH BÊN DƯỚI
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.center_focus_strong_rounded, color: Color(0xFF00E5FF), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hướng camera vào mã QR hiển thị trên điện thoại của bé để ghép nối',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.qr_code_2, size: 15, color: Colors.white),
                      label: const Text('Mã Bé Bo (Test nhanh)', style: TextStyle(fontSize: 11, color: Colors.white)),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      side: const BorderSide(color: Colors.white24),
                      onPressed: () => _processScannedCode('DEV-KID-BO-8821'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.qr_code_2, size: 15, color: Colors.white),
                      label: const Text('Mã Bé Bông', style: TextStyle(fontSize: 11, color: Colors.white)),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      side: const BorderSide(color: Colors.white24),
                      onPressed: () => _processScannedCode('DEV-KID-BONG-9932'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
