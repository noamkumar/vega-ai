import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vega_ai/core/constants/app_colors.dart';
import 'package:vega_ai/core/constants/app_dimensions.dart';
import 'package:vega_ai/core/models/assistant_state.dart';

/// Large animated circular assistant button inspired by sci-fi AI interfaces (JARVIS).
///
/// Transitions visually based on [AssistantStatus]:
/// - Idle: Soft ambient breathing with gentle lavender/pink aura.
/// - Listening: Expanding pulsing sonic rings in vivid Primary Pink (#F73B9A).
/// - Processing: Continuous rotating orbital particle ring.
/// - Speaking: Frequency-modulated wave glow.
class VoiceOrbButton extends StatefulWidget {
  final AssistantStatus status;
  final VoidCallback onTap;
  final double size;

  const VoiceOrbButton({
    super.key,
    required this.status,
    required this.onTap,
    this.size = AppDimensions.orbSizePhone,
  });

  @override
  State<VoiceOrbButton> createState() => _VoiceOrbButtonState();
}

class _VoiceOrbButtonState extends State<VoiceOrbButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotationController;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant VoiceOrbButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      if (widget.status.isListening) {
        _pulseController.duration = const Duration(milliseconds: 900);
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.duration = const Duration(milliseconds: 1800);
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.size + 80,
        height: widget.size + 80,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _rotationController,
            _waveController,
          ]),
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Layer 1: Outermost expanding wave rings (when listening or speaking)
                if (widget.status.isListening || widget.status.isSpeaking)
                  _buildWaveRing(widget.status),

                // Layer 2: Rotating orbital boundary (when processing or active)
                if (widget.status.isProcessing)
                  _buildProcessingRing(),

                // Layer 3: Ambient Glow Halo
                _buildAmbientHalo(),

                // Layer 4: Inner Core Orb
                _buildCoreOrb(),

                // Layer 5: Dynamic Icon / Symbol
                _buildCenterSymbol(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWaveRing(AssistantStatus status) {
    final scale = 1.0 + (_waveController.value * 0.45);
    final opacity = (1.0 - _waveController.value).clamp(0.0, 1.0);
    final color = status.isListening ? AppColors.primaryPink : AppColors.speakingWave;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size + 30,
        height: widget.size + 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(opacity * 0.6),
            width: 2.5,
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingRing() {
    return Transform.rotate(
      angle: _rotationController.value * 2 * math.pi,
      child: Container(
        width: widget.size + 24,
        height: widget.size + 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.lavender,
            width: 2.0,
            style: BorderStyle.solid,
          ),
          gradient: const SweepGradient(
            colors: [
              Colors.transparent,
              AppColors.lavender,
              AppColors.primaryPink,
            ],
            stops: [0.3, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientHalo() {
    final pulse = _pulseController.value;
    final glowSpread = 16.0 + (pulse * 18.0);

    Color haloColor;
    switch (widget.status) {
      case AssistantStatus.idle:
        haloColor = AppColors.lavender.withOpacity(0.35);
        break;
      case AssistantStatus.listening:
        haloColor = AppColors.primaryPink.withOpacity(0.55);
        break;
      case AssistantStatus.processing:
        haloColor = AppColors.processingGlow.withOpacity(0.55);
        break;
      case AssistantStatus.speaking:
        haloColor = AppColors.speakingWave.withOpacity(0.55);
        break;
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: haloColor,
            blurRadius: glowSpread * 1.8,
            spreadRadius: glowSpread * 0.5,
          ),
        ],
      ),
    );
  }

  Widget _buildCoreOrb() {
    final pulseScale = 1.0 + (_pulseController.value * 0.04);

    return Transform.scale(
      scale: pulseScale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color(0xFFFF85C2),
              AppColors.primaryPink,
              Color(0xFF6B1865),
              Color(0xFF1D0A2A),
            ],
            stops: [0.0, 0.45, 0.85, 1.0],
            center: Alignment(-0.2, -0.3),
          ),
          border: Border.all(
            color: AppColors.lavenderLight.withOpacity(0.7),
            width: 1.8,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterSymbol() {
    IconData icon;
    Color iconColor = Colors.white;

    switch (widget.status) {
      case AssistantStatus.idle:
        icon = Icons.mic_none_rounded;
        break;
      case AssistantStatus.listening:
        icon = Icons.graphic_eq_rounded;
        break;
      case AssistantStatus.processing:
        icon = Icons.auto_awesome_rounded;
        break;
      case AssistantStatus.speaking:
        icon = Icons.volume_up_rounded;
        break;
    }

    return Icon(
      icon,
      size: widget.size * 0.32,
      color: iconColor,
      shadows: const [
        Shadow(
          color: Colors.black45,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }
}
