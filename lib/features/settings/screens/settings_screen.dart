import 'package:flutter/material.dart';
import 'package:vega_ai/core/constants/app_colors.dart';
import 'package:vega_ai/core/constants/app_dimensions.dart';
import 'package:vega_ai/shared/widgets/vega_app_bar.dart';
import 'package:vega_ai/shared/widgets/vega_card.dart';

/// Settings screen for VEGA AI voice assistant configuration.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _offlineFirst = true;
  bool _wakeWordEnabled = true;
  double _wakeSensitivity = 0.75;
  double _speechRate = 1.0;
  double _speechPitch = 1.0;
  bool _obscureApiKey = true;

  late final TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const VegaAppBar(title: 'Assistant Settings'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.md),
          children: [
            // Section 1: AI Engines
            _buildSectionHeader('AI Intelligence & Routing', isDark),
            const SizedBox(height: AppDimensions.sm),
            VegaCard(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Offline-First Routing',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Prioritize sub-100ms local rules and on-device models before calling Gemini cloud.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    activeColor: AppColors.primaryPink,
                    value: _offlineFirst,
                    onChanged: (val) => setState(() => _offlineFirst = val),
                  ),
                  const Divider(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gemini API Key (Cloud Intelligence)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Required for advanced natural language and broad questions. Key is stored locally in device keystore.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _apiKeyController,
                        obscureText: _obscureApiKey,
                        decoration: InputDecoration(
                          hintText: 'Enter your Google Gemini API key...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark.withOpacity(0.6) : Colors.grey,
                          ),
                          filled: true,
                          fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLightSubtle,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: AppDimensions.roundedSm,
                            borderSide: BorderSide(
                              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppDimensions.roundedSm,
                            borderSide: BorderSide(
                              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppDimensions.roundedSm,
                            borderSide: const BorderSide(color: AppColors.primaryPink),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                              size: 18,
                              color: AppColors.lavenderDark,
                            ),
                            onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Section 2: Voice & Wake Word
            _buildSectionHeader('Wake Word & Voice Recognition', isDark),
            const SizedBox(height: AppDimensions.sm),
            VegaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Listen for "Hey Vega"',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Continuous low-power on-device hotword listener.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    activeColor: AppColors.primaryPink,
                    value: _wakeWordEnabled,
                    onChanged: (val) => setState(() => _wakeWordEnabled = val),
                  ),
                  if (_wakeWordEnabled) ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Wake-Word Sensitivity',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          '${(_wakeSensitivity * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryPink),
                        ),
                      ],
                    ),
                    Slider(
                      value: _wakeSensitivity,
                      activeColor: AppColors.primaryPink,
                      inactiveColor: AppColors.lavender.withOpacity(0.3),
                      onChanged: (val) => setState(() => _wakeSensitivity = val),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Section 3: TTS Voice Modulation
            _buildSectionHeader('Speech Synthesis (TTS)', isDark),
            const SizedBox(height: AppDimensions.sm),
            VegaCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Speech Rate',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '${_speechRate.toStringAsFixed(1)}x',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryPink),
                      ),
                    ],
                  ),
                  Slider(
                    value: _speechRate,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    activeColor: AppColors.primaryPink,
                    inactiveColor: AppColors.lavender.withOpacity(0.3),
                    onChanged: (val) => setState(() => _speechRate = val),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Voice Pitch',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '${_speechPitch.toStringAsFixed(1)}x',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.lavenderDark),
                      ),
                    ],
                  ),
                  Slider(
                    value: _speechPitch,
                    min: 0.5,
                    max: 1.5,
                    divisions: 10,
                    activeColor: AppColors.lavenderDark,
                    inactiveColor: AppColors.lavender.withOpacity(0.3),
                    onChanged: (val) => setState(() => _speechPitch = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.lavender : AppColors.primaryPink,
        letterSpacing: 0.5,
      ),
    );
  }
}
