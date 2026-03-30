import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

class PhysicsCalibrationScreen extends StatefulWidget {
  const PhysicsCalibrationScreen({super.key});

  @override
  State<PhysicsCalibrationScreen> createState() =>
      _PhysicsCalibrationScreenState();
}

class _PhysicsCalibrationScreenState extends State<PhysicsCalibrationScreen> {
  int _topMotor = 75;
  int _bottomMotor = 75;
  bool _saved = false;

  int get _spinDiff => _topMotor - _bottomMotor;
  double get _trajectoryAngle => (_spinDiff / 100) * 45;

  String get _spinType {
    if (_spinDiff > 10) return 'Topspin';
    if (_spinDiff < -10) return 'Backspin';
    return 'Neutral';
  }

  void _handleSave() {
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  void _handleReset() {
    setState(() {
      _topMotor = 75;
      _bottomMotor = 75;
    });
  }

  void _applyPreset(int top, int bottom) {
    setState(() {
      _topMotor = top;
      _bottomMotor = bottom;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildTrajectoryVisualization(),
              const SizedBox(height: 24),
              _buildMotorControls(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 16),
              _buildQuickPresets(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Physics Calibration',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fine-tune spin dynamics',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTrajectoryVisualization() {
    return AppCard(
      gradient: true,
      child: Column(
        children: [
          Text(
            'Ball Trajectory',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _spinType,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Container(
            height: 256,
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: CustomPaint(
              painter: TrajectoryPainter(
                trajectoryAngle: _trajectoryAngle,
                spinDiff: _spinDiff,
              ),
              size: const Size(double.infinity, 256),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: _spinDiff * 3.6 * (math.pi / 180),
                  child: Icon(
                    Icons.rotate_right,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_spinDiff >= 0 ? '+' : ''}${_spinDiff.toStringAsFixed(0)} RPM Δ',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotorControls() {
    return AppCard(
      child: Column(
        children: [
          const Text(
            'Motor Speed Control',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMotorSlider(
                  label: 'Top Motor',
                  value: _topMotor,
                  color: AppTheme.primary,
                  onChanged: (v) => setState(() => _topMotor = v),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildMotorSlider(
                  label: 'Bottom Motor',
                  value: _bottomMotor,
                  color: AppTheme.secondary,
                  onChanged: (v) => setState(() => _bottomMotor = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMotorSlider({
    required String label,
    required int value,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '$value%',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: AppTheme.border,
                thumbColor: color,
                overlayColor: color.withOpacity(0.2),
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 100,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '0%',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const Text(
              '100%',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Reset',
            icon: Icons.refresh,
            outlined: true,
            onPressed: _handleReset,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            text: _saved ? 'Saved!' : 'Save Config',
            icon: Icons.save,
            onPressed: _handleSave,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPresets() {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Adjust',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPresetButton(
                  'Max Topspin',
                  () => _applyPreset(90, 60),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetButton(
                  'Neutral',
                  () => _applyPreset(75, 75),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetButton(
                  'Max Backspin',
                  () => _applyPreset(60, 90),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        side: const BorderSide(color: AppTheme.border),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class TrajectoryPainter extends CustomPainter {
  final double trajectoryAngle;
  final int spinDiff;

  TrajectoryPainter({required this.trajectoryAngle, required this.spinDiff});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.border.withOpacity(0.5)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        gridPaint,
      );
    }
    for (int i = 0; i <= size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        gridPaint,
      );
    }

    final launchPaint = Paint()
      ..color = AppTheme.secondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(40, size.height - 32), 8, launchPaint);

    final glowPaint = Paint()
      ..color = AppTheme.secondary.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(40, size.height - 32), 12, glowPaint);

    final pathPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(40, size.height - 32);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.5 - trajectoryAngle * 2,
      size.width - 40,
      size.height * 0.25 + trajectoryAngle,
    );

    canvas.drawPath(path, pathPaint);

    final dashPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashPath = Path();
    const dashLength = 5.0;
    const gapLength = 5.0;
    double distance = 0;
    final pathMetrics = path.computeMetrics().first;
    while (distance < pathMetrics.length) {
      final extractPath = pathMetrics.extractPath(
        distance,
        math.min(distance + dashLength, pathMetrics.length),
      );
      canvas.drawPath(extractPath, dashPaint);
      distance += dashLength + gapLength;
    }

    final ballPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final ballBorderPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      Offset(size.width - 40, size.height * 0.25 + trajectoryAngle),
      12,
      ballPaint,
    );
    canvas.drawCircle(
      Offset(size.width - 40, size.height * 0.25 + trajectoryAngle),
      12,
      ballBorderPaint,
    );

    final targetTop = math.max(20, 80 + trajectoryAngle).toDouble();
    final targetPaint = Paint()
      ..color = AppTheme.success.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final targetBorderPaint = Paint()
      ..color = AppTheme.success
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 100, targetTop, 60, 100),
        const Radius.circular(8),
      ),
      targetPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 100, targetTop, 60, 100),
        const Radius.circular(8),
      ),
      targetBorderPaint,
    );
    canvas.drawCircle(
      Offset(size.width - 70, targetTop + 50),
      6,
      Paint()..color = AppTheme.success,
    );
  }

  @override
  bool shouldRepaint(covariant TrajectoryPainter oldDelegate) {
    return oldDelegate.trajectoryAngle != trajectoryAngle ||
        oldDelegate.spinDiff != spinDiff;
  }
}
