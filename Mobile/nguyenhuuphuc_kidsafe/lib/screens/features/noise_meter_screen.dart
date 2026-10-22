import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/noise_provider.dart';
import '../../theme/app_theme.dart';

class NoiseMeterScreen extends StatefulWidget {
  const NoiseMeterScreen({super.key});

  @override
  State<NoiseMeterScreen> createState() => _NoiseMeterScreenState();
}

class _NoiseMeterScreenState extends State<NoiseMeterScreen> {
  // 0: Giám sát máy con (Từ xa theo thời gian thực), 1: Micro máy này (Cục bộ)
  int _selectedSourceIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NoiseProvider>(context, listen: false).startMonitoring();
    });
  }

  Color _getDecibelColor(double db) {
    if (db >= 85) return AppTheme.danger;
    if (db >= 68) return AppTheme.warning;
    if (db >= 45) return AppTheme.secondary;
    return AppTheme.accent;
  }

  String _getCategoryTitle(double db) {
    if (db >= 85) return 'CỰC KỲ NGUY HIỂM';
    if (db >= 68) return 'Ô NHIỄM TIẾNG ỒN';
    if (db >= 45) return 'BÌNH THƯỜNG';
    return 'YÊN TĨNH';
  }

  String _getCategoryDesc(double db) {
    if (db >= 85) {
      return 'Phát hiện tiếng la hét, va chạm mạnh hoặc tiếng ồn bất thường! Hệ thống đang kích hoạt cảnh báo khẩn cấp!';
    }
    if (db >= 68) {
      return 'Môi trường ồn ào (tiếng còi xe, đám đông lớn). Trẻ có thể bị căng thẳng nếu kéo dài.';
    }
    if (db >= 45) {
      return 'Âm thanh sinh hoạt bình thường trong phòng học hoặc gia đình.';
    }
    return 'Không gian rất yên tĩnh, lý tưởng cho việc học bài và nghỉ ngơi.';
  }

  @override
  Widget build(BuildContext context) {
    final noise = Provider.of<NoiseProvider>(context);
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    final child = childrenProvider.selectedChild;

    // Nếu chọn giám sát máy con thì lấy db của máy con, nếu không thì lấy db micro cục bộ
    final double db = _selectedSourceIndex == 0
        ? (child?.currentNoiseDb ?? noise.currentDecibel)
        : noise.currentDecibel;
    final catColor = _getDecibelColor(db);
    final threshold = noise.warningThreshold;
    final isExceedingThreshold = noise.isThresholdAlertEnabled && (db >= threshold);
    final isDanger = isExceedingThreshold || db >= 85.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đo Tiếng Ồn Môi Trường', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              noise.isMonitoring ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
              color: noise.isMonitoring ? AppTheme.warning : AppTheme.accent,
              size: 28,
            ),
            tooltip: noise.isMonitoring ? 'Tạm dừng đo' : 'Bắt đầu đo',
            onPressed: () {
              if (noise.isMonitoring) {
                noise.stopMonitoring();
              } else {
                noise.startMonitoring();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tab Switcher: Giám sát máy con (Từ xa) vs Micro máy này (Cục bộ)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedSourceIndex = 0),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedSourceIndex == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedSourceIndex == 0
                              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone_android_rounded,
                              size: 16,
                              color: _selectedSourceIndex == 0 ? AppTheme.primary : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Máy Bé (${child?.name ?? "Con"})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedSourceIndex == 0 ? AppTheme.primary : AppTheme.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedSourceIndex = 1),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedSourceIndex == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedSourceIndex == 1
                              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mic_rounded,
                              size: 16,
                              color: _selectedSourceIndex == 1 ? AppTheme.secondary : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Micro Máy Này',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedSourceIndex == 1 ? AppTheme.secondary : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Danger Alert Banner if triggered (vượt ngưỡng đã thiết lập)
            if (isDanger || noise.isAlertTriggered)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.danger, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.danger.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emergency_rounded, color: AppTheme.danger, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '⚠️ CẢNH BÁO TIẾNG ỒN VƯỢT NGƯỠNG!',
                            style: TextStyle(
                              color: AppTheme.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _selectedSourceIndex == 0
                                ? 'Phát hiện âm thanh (${db.toStringAsFixed(1)} dB) vượt ngưỡng an toàn đã đặt (${threshold.toStringAsFixed(0)} dB) bên điện thoại của bé!'
                                : (noise.alertMessage.isNotEmpty
                                    ? noise.alertMessage
                                    : 'Phát hiện tiếng ồn (${db.toStringAsFixed(1)} dB) vượt ngưỡng đã thiết lập (${threshold.toStringAsFixed(0)} dB)!'),
                            style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.danger),
                      tooltip: 'Tắt cảnh báo',
                      onPressed: () {
                        noise.dismissAlert();
                        if (_selectedSourceIndex == 0 && child != null) {
                          childrenProvider.updateChildNoise(child.id, threshold - 5.0);
                        }
                      },
                    ),
                  ],
                ),
              ),

            // Circular Speedometer-style Decibel Gauge
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: catColor.withOpacity(0.12),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
                border: Border.all(
                  color: isExceedingThreshold ? AppTheme.danger : catColor.withOpacity(0.3),
                  width: isExceedingThreshold ? 2.5 : 2,
                ),
              ),
              child: Column(
                children: [
                  // Huy hiệu nguồn âm thanh thời gian thực
                  InkWell(
                    onTap: _selectedSourceIndex == 1
                        ? () async {
                            final ok = await noise.enableRealMicrophone();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? '🟢 Đã kích hoạt Micro phần cứng thành công!'
                                      : '⚠️ Hãy cấp quyền Micro trong Cài đặt thiết bị.'),
                                  backgroundColor: ok ? AppTheme.accent : AppTheme.warning,
                                ),
                              );
                            }
                          }
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedSourceIndex == 0
                            ? const Color(0xFFEFF6FF)
                            : (noise.isRealMicrophone ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedSourceIndex == 0
                              ? const Color(0xFF3B82F6)
                              : (noise.isRealMicrophone ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedSourceIndex == 0 ? Icons.sensors_rounded : (noise.isRealMicrophone ? Icons.mic_rounded : Icons.mic_none_rounded),
                            size: 16,
                            color: _selectedSourceIndex == 0
                                ? const Color(0xFF1D4ED8)
                                : (noise.isRealMicrophone ? const Color(0xFF059669) : const Color(0xFFD97706)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedSourceIndex == 0
                                ? 'Thu Nhận Thời Gian Thực Từ Máy Bé'
                                : (noise.isRealMicrophone ? 'Micro Thật: Đang Thu Âm' : 'Chưa nhận Mic (Bấm để kích hoạt)'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedSourceIndex == 0
                                  ? const Color(0xFF1D4ED8)
                                  : (noise.isRealMicrophone ? const Color(0xFF047857) : const Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: CircularProgressIndicator(
                          value: (db / 120.0).clamp(0.0, 1.0),
                          strokeWidth: 15,
                          backgroundColor: AppTheme.cardBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(catColor),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            db.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: catColor,
                              letterSpacing: -1,
                            ),
                          ),
                          const Text(
                            'DECIBEL (dB)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMuted,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getCategoryTitle(db),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: catColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _getCategoryDesc(db),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Thẻ báo trạng thái so với ngưỡng thiết lập
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isExceedingThreshold ? const Color(0xFFFEE2E2) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isExceedingThreshold ? AppTheme.danger : const Color(0xFFBBF7D0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExceedingThreshold ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                          size: 14,
                          color: isExceedingThreshold ? AppTheme.danger : AppTheme.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isExceedingThreshold
                              ? 'VƯỢT NGƯỠNG +${(db - threshold).toStringAsFixed(1)} dB (Ngưỡng: ${threshold.toStringAsFixed(0)} dB)'
                              : 'An Toàn (Dưới ngưỡng ${(threshold - db).toStringAsFixed(1)} dB • Đặt: ${threshold.toStringAsFixed(0)} dB)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isExceedingThreshold ? AppTheme.danger : AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Card 3. Thiết lập ngưỡng cảnh báo (Yêu cầu đề tài: Cảnh báo khi vượt ngưỡng đã thiết lập)
            _buildThresholdSettingCard(noise, db),
            const SizedBox(height: 18),

            // Real-time Sound Waveform Chart (FlChart) có đường ngưỡng ngang màu đỏ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.graphic_eq_rounded, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedSourceIndex == 0
                              ? 'Biểu Đồ Sóng Âm Từ Máy Của Bé (${child?.name ?? "Con"})'
                              : 'Biểu Đồ Sóng Âm Thời Gian Thực (Micro)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 135,
                    child: LineChart(
                      LineChartData(
                        minY: 20,
                        maxY: 110,
                        titlesData: const FlTitlesData(show: false),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: threshold,
                              color: AppTheme.danger.withOpacity(0.85),
                              strokeWidth: 2,
                              dashArray: [6, 4],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                style: const TextStyle(
                                  color: AppTheme.danger,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                labelResolver: (line) => 'Ngưỡng: ${line.y.toStringAsFixed(0)} dB',
                              ),
                            ),
                          ],
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: noise.waveform.asMap().entries.map((e) {
                              return FlSpot(e.key.toDouble(), e.value);
                            }).toList(),
                            isCurved: true,
                            color: isExceedingThreshold ? AppTheme.danger : catColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: (isExceedingThreshold ? AppTheme.danger : catColor).withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Recent Noise History Logs of Child
            if (_selectedSourceIndex == 0 && child != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history_rounded, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nhật Ký Tiếng Ồn Gần Đây Bên Máy Bé',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...noise.getLogs(child.id).take(4).map((log) {
                      final logColor = _getDecibelColor(log.decibel);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: logColor.withOpacity(0.15),
                              child: Text(
                                log.decibel.toStringAsFixed(0),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: logColor),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(log.note ?? 'Ghi nhận độ ồn', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  Text(log.timestamp, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: logColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${log.decibel.toStringAsFixed(1)} dB',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: logColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            // Controls & Presentation Scenario Tests (Hiển thị khi ở chế độ Micro hoặc Test)
            if (_selectedSourceIndex == 1)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, color: AppTheme.secondary, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kịch Bản Thử Nghiệm Báo Động (Demo)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bạn có thể nói hoặc vỗ tay trước micro điện thoại, hoặc chọn nhanh các kịch bản mẫu bên dưới khi thuyết trình:',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.bed_rounded, size: 14, color: AppTheme.accent),
                          label: const Text('Phòng ngủ (32 dB)', style: TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFF0FDF4),
                          onPressed: () => noise.setScenario('quiet'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.school_rounded, size: 14, color: AppTheme.secondary),
                          label: const Text('Lớp học (52 dB)', style: TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFF0F9FF),
                          onPressed: () => noise.setScenario('normal'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.traffic_rounded, size: 14, color: AppTheme.warning),
                          label: const Text('Đường phố (76 dB)', style: TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFFFFBEB),
                          onPressed: () => noise.setScenario('loud'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.notification_important_rounded, size: 14, color: AppTheme.danger),
                          label: const Text('La hét SOS (94 dB)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.danger)),
                          backgroundColor: const Color(0xFFFEE2E2),
                          onPressed: () => noise.setScenario('danger'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Điều chỉnh Decibel thử nghiệm:', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    Slider(
                      value: db.clamp(20.0, 110.0),
                      min: 20.0,
                      max: 110.0,
                      activeColor: catColor,
                      onChanged: (val) => noise.setManualDecibel(val),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdSettingCard(NoiseProvider noise, double currentDb) {
    final threshold = noise.warningThreshold;
    final isExceeded = currentDb >= threshold;

    Color thresholdColor;
    String thresholdLabel;
    if (threshold >= 85) {
      thresholdColor = AppTheme.danger;
      thresholdLabel = 'Cực kỳ ồn (Báo động)';
    } else if (threshold >= 70) {
      thresholdColor = AppTheme.warning;
      thresholdLabel = 'Ồn ào (Đường phố)';
    } else if (threshold >= 60) {
      thresholdColor = AppTheme.secondary;
      thresholdLabel = 'Vừa phải (Phòng học)';
    } else {
      thresholdColor = AppTheme.accent;
      thresholdLabel = 'Yên tĩnh (Phòng ngủ)';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExceeded && noise.isThresholdAlertEnabled
              ? AppTheme.danger.withOpacity(0.5)
              : AppTheme.cardBorder,
          width: isExceeded && noise.isThresholdAlertEnabled ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề card + Switch bật tắt
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cài Đặt Ngưỡng Cảnh Báo (dB)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                    ),
                    Text(
                      'Cảnh báo khi âm thanh vượt mức thiết lập',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: noise.isThresholdAlertEnabled,
                activeColor: AppTheme.primary,
                onChanged: (val) => noise.toggleThresholdAlert(val),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Hiển thị giá trị ngưỡng hiện tại
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active_rounded, size: 16, color: thresholdColor),
                const SizedBox(width: 8),
                const Text('Ngưỡng Cảnh Báo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: thresholdColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${threshold.toStringAsFixed(0)} dB ($thresholdLabel)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: thresholdColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Slider điều chỉnh ngưỡng
          Row(
            children: [
              const Text('40 dB', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
              Expanded(
                child: Slider(
                  value: threshold.clamp(40.0, 100.0),
                  min: 40.0,
                  max: 100.0,
                  divisions: 60,
                  label: '${threshold.toStringAsFixed(0)} dB',
                  activeColor: thresholdColor,
                  onChanged: noise.isThresholdAlertEnabled
                      ? (val) => noise.setWarningThreshold(val)
                      : null,
                ),
              ),
              const Text('100 dB', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),

          // Các nút chọn nhanh mức ngưỡng mẫu
          const Text(
            'Chọn nhanh mức ngưỡng theo môi trường:',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildThresholdChip(noise, 50.0, '🛌 Phòng ngủ (50 dB)'),
              _buildThresholdChip(noise, 65.0, '📚 Phòng học (65 dB)'),
              _buildThresholdChip(noise, 75.0, '🏠 Tiêu chuẩn (75 dB)'),
              _buildThresholdChip(noise, 85.0, '🚨 Báo động (85 dB)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdChip(NoiseProvider noise, double targetDb, String label) {
    final isSelected = (noise.warningThreshold - targetDb).abs() < 1.0;
    return InkWell(
      onTap: () => noise.setWarningThreshold(targetDb),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textDark,
          ),
        ),
      ),
    );
  }
}
