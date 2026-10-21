import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/noise_provider.dart';
import '../../providers/sos_provider.dart';
import '../../theme/app_theme.dart';

class AIAcousticShieldScreen extends StatefulWidget {
  const AIAcousticShieldScreen({super.key});

  @override
  State<AIAcousticShieldScreen> createState() => _AIAcousticShieldScreenState();
}

class _AIAcousticShieldScreenState extends State<AIAcousticShieldScreen> {
  bool _silentBeaconEnabled = true;
  bool _autoAppLockOnDistress = true;

  void _triggerSimulatedSilentSOS() {
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final sosProvider = Provider.of<SOSProvider>(context, listen: false);
    final child = childrenProvider.selectedChild;

    sosProvider.createSOS(
      childId: child?.id ?? 'ch_01',
      childName: child?.name ?? 'Bé Bo (Gia Bảo)',
      parentName: 'Nguyễn Hữu Phúc',
      parentPhone: '0988776655',
      latitude: child?.latitude ?? 10.7769,
      longitude: child?.longitude ?? 106.7009,
      noiseLevel: 92.4,
      reason: 'AI Acoustic Shield: Phát hiện tiếng la hét & va chạm mạnh! Phao cứu hộ ngầm tự động kích hoạt.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppTheme.danger, size: 28),
            SizedBox(width: 10),
            Text('Đã Kích Hoạt Phao Cứu Hộ Ngầm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thiết bị đã bí mật gửi tọa độ GPS và mẫu phân tích phổ âm thanh 92.4 dB về Trung tâm Cứu hộ Staff và máy Phụ huynh.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              '⚠️ Thiết bị của bé giữ im lặng tuyệt đối để đảm bảo an toàn cho trẻ trước kẻ gian hoặc bạo lực học đường!',
              style: TextStyle(fontSize: 12, color: AppTheme.danger, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Đã Hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noise = Provider.of<NoiseProvider>(context);
    final score = noise.studyFocusScore;

    Color scoreColor = AppTheme.accent;
    if (score < 60) {
      scoreColor = AppTheme.danger;
    } else if (score < 80) {
      scoreColor = AppTheme.warning;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lá Chắn Âm Thanh AI & Phao Cứu Hộ'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.psychology_rounded, color: Colors.cyanAccent, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tính Năng Mới Độc Quyền',
                              style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'AI Acoustic Shield 3.0',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: noise.aiShieldEnabled,
                        activeColor: Colors.cyanAccent,
                        onChanged: (val) => noise.toggleAiShield(val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Công nghệ bảo vệ trẻ em chủ động thông qua phân tích âm thanh môi trường xung quanh thời gian thực. '
                    'Tự động phát hiện tiếng la hét, bạo lực học đường và gửi tín hiệu cứu hộ ngầm.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Study Focus Acoustic Score (Đánh giá không gian học tập)
            const Text(
              'Chỉ Số Không Gian Học Tập Yên Tĩnh (Acoustic Score)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: score / 100.0,
                          strokeWidth: 8,
                          backgroundColor: AppTheme.cardBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        ),
                      ),
                      Text(
                        '${score.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          score >= 80 ? 'Không gian học bài RẤT TỐT' : (score >= 60 ? 'Không gian học bài TƯƠNG ĐỐI' : 'Môi trường quá ồn ào!'),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: scoreColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          score >= 80
                              ? 'Độ ồn trung bình ${noise.currentDecibel.toStringAsFixed(0)} dB. Bé có khả năng tập trung tư duy cao nhất.'
                              : 'Độ ồn ${noise.currentDecibel.toStringAsFixed(0)} dB. Phụ huynh nên nhắc bé đóng cửa hoặc chuyển phòng học.',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Advanced Rules & Switches
            const Text(
              'Cơ Chế Phản Ứng Khẩn Cấp',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 10),
            Card(
              child: SwitchListTile(
                value: _silentBeaconEnabled,
                activeColor: AppTheme.primary,
                title: const Text('Phao Cứu Hộ Ngầm (Silent Distress Beacon)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Gửi tín hiệu cầu cứu khẩn cấp mà không phát ra bất kỳ âm thanh nào trên máy bé', style: TextStyle(fontSize: 12)),
                onChanged: (val) => setState(() => _silentBeaconEnabled = val),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                value: _autoAppLockOnDistress,
                activeColor: AppTheme.primary,
                title: const Text('Tự Động Khóa Ứng Dụng Giải Trí Khi Nguy Hiểm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Khóa màn hình game và mạng xã hội để bé chỉ có thể gọi điện cho phụ huynh', style: TextStyle(fontSize: 12)),
                onChanged: (val) => setState(() => _autoAppLockOnDistress = val),
              ),
            ),
            const SizedBox(height: 24),

            // Test Trigger Button
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.touch_app_rounded, color: AppTheme.danger, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Kiểm Thử Kích Hoạt Phao Cứu Hộ Ngầm',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.danger),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bấm nút dưới đây để mô phỏng kịch bản hệ thống phát hiện nguy hiểm và tự động gửi gói tin SOS đến phụ huynh & trung tâm trực ban:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _triggerSimulatedSilentSOS,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.campaign_rounded, size: 20),
                    label: const Text('Kích Hoạt Thử Tín Hiệu SOS Ngầm (Demo)'),
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
