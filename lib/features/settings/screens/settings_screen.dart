import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vega_ai/core/constants/app_colors.dart';
import 'package:vega_ai/core/constants/app_dimensions.dart';
import 'package:vega_ai/features/assistant/assistant_controller.dart';
import 'package:vega_ai/services/ai/local_model_manager.dart';
import 'package:vega_ai/services/ai/online_gemini_service.dart';
import 'package:vega_ai/services/storage/storage_service.dart';
import 'package:vega_ai/shared/widgets/vega_app_bar.dart';
import 'package:vega_ai/shared/widgets/vega_card.dart';

/// Settings screen for VEGA AI voice assistant configuration.
class SettingsScreen extends StatefulWidget {
  final StorageService? storageService;
  final LocalModelManager? modelManager;
  final AssistantController? controller;
  final OnlineGeminiService? onlineService;

  const SettingsScreen({
    super.key,
    this.storageService,
    this.modelManager,
    this.controller,
    this.onlineService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final StorageService _storageService;
  late final LocalModelManager _modelManager;
  late final OnlineGeminiService _onlineService;
  StreamSubscription<ModelStatus>? _modelStatusSub;
  StreamSubscription<double>? _modelProgressSub;

  bool _offlineFirst = true;
  bool _wakeWordEnabled = true;
  double _wakeSensitivity = 0.75;
  double _speechRate = 1.0;
  double _speechPitch = 1.0;
  bool _obscureApiKey = true;
  bool _isLoading = true;
  bool _isTestingConnection = false;
  Map<String, dynamic>? _connectionTestResult;
  String _selectedModel = 'gemini-1.5-flash';

  late final TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? JsonFileStorageService();
    _modelManager = widget.modelManager ?? LocalModelManager();
    _onlineService = widget.onlineService ??
        widget.controller?.onlineService ??
        OnlineGeminiService();
    _apiKeyController = TextEditingController();
    _loadSettings();

    _modelStatusSub = _modelManager.onStatusChanged.listen((_) {
      if (mounted) setState(() {});
    });
    _modelProgressSub = _modelManager.onProgressChanged.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadSettings() async {
    final apiKey = await _storageService.getGeminiApiKey();
    final model = await _storageService.getGeminiModel();
    final offlineFirst = await _storageService.getOfflineFirst();
    final wakeEnabled = await _storageService.getWakeWordEnabled();
    final wakeSens = await _storageService.getWakeWordSensitivity();
    final rate = await _storageService.getSpeechRate();
    final pitch = await _storageService.getSpeechPitch();

    if (apiKey != null && apiKey.isNotEmpty) {
      _onlineService.updateApiKey(apiKey);
    }
    _onlineService.updateModelId(model);

    if (mounted) {
      setState(() {
        if (apiKey != null) _apiKeyController.text = apiKey;
        _selectedModel = model;
        _offlineFirst = offlineFirst;
        _wakeWordEnabled = wakeEnabled;
        _wakeSensitivity = wakeSens;
        _speechRate = rate;
        _speechPitch = pitch;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveApiKey(String key) async {
    final trimmed = key.trim();
    await _storageService.saveGeminiApiKey(trimmed);
    _onlineService.updateApiKey(trimmed);
    widget.controller?.onlineService?.updateApiKey(trimmed);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API Key saved successfully'),
          backgroundColor: AppColors.primaryPink,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveModel(String model) async {
    setState(() => _selectedModel = model);
    await _storageService.saveGeminiModel(model);
    _onlineService.updateModelId(model);
    widget.controller?.onlineService?.updateModelId(model);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gemini model updated to: $model'),
          backgroundColor: AppColors.lavenderDark,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
    });

    final res = await _onlineService.testConnection();

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _connectionTestResult = res;
      });
    }
  }

  @override
  void dispose() {
    _modelStatusSub?.cancel();
    _modelProgressSub?.cancel();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        appBar: VegaAppBar(title: 'Assistant Settings'),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPink),
        ),
      );
    }

    return Scaffold(
      appBar: const VegaAppBar(title: 'Assistant Settings'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.md),
          children: [
            // Section 1: Bundled Offline AI Model
            _buildSectionHeader('Bundled Offline AI Model (APK Package)', isDark),
            const SizedBox(height: AppDimensions.sm),
            _buildModelStatusCard(isDark),
            const SizedBox(height: AppDimensions.md),

            // Section 2: AI Intelligence & Cloud Gemini
            _buildSectionHeader('AI Intelligence & Routing', isDark),
            const SizedBox(height: AppDimensions.sm),
            VegaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Offline-First Routing',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Prioritize sub-100ms local rules and bundled on-device model before calling Gemini cloud.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    activeColor: AppColors.primaryPink,
                    value: _offlineFirst,
                    onChanged: (val) {
                      setState(() => _offlineFirst = val);
                      _storageService.saveOfflineFirst(val);
                      if (widget.controller != null) {
                        widget.controller!.aiRouter.preferOfflineFirst = val;
                      }
                    },
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Gemini Model Selection',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select the online Gemini model for high-level reasoning and conversation.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLightSubtle,
                      borderRadius: AppDimensions.roundedSm,
                      border: Border.all(
                        color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedModel,
                        isExpanded: true,
                        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                        items: const [
                          DropdownMenuItem(
                            value: 'gemini-1.5-flash',
                            child: Text(
                              'gemini-1.5-flash (Fastest • Recommended)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'gemini-1.5-pro',
                            child: Text(
                              'gemini-1.5-pro (Advanced Multi-step Reasoning)',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'gemini-2.0-flash',
                            child: Text(
                              'gemini-2.0-flash (Next-Gen Intelligence)',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) _saveModel(val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gemini API Key (Optional Cloud Intelligence)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Required for broad web reasoning. Device actions work 100% offline without any API key.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
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
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: AppDimensions.roundedSm,
                              borderSide: BorderSide(color: AppColors.primaryPink),
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
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: AppDimensions.roundedSm),
                        ),
                        onPressed: () => _saveApiKey(_apiKeyController.text),
                        child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: _isTestingConnection
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPink),
                              )
                            : const Icon(Icons.cloud_sync_rounded, size: 16),
                        label: Text(
                          _isTestingConnection ? 'Testing...' : 'Test Gemini Connection',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryPink,
                          side: const BorderSide(color: AppColors.primaryPink),
                          shape: RoundedRectangleBorder(borderRadius: AppDimensions.roundedSm),
                        ),
                        onPressed: _isTestingConnection ? null : _testConnection,
                      ),
                    ],
                  ),
                  if (_connectionTestResult != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _connectionTestResult!['success'] == true
                            ? Colors.green.withOpacity(0.15)
                            : Colors.redAccent.withOpacity(0.15),
                        borderRadius: AppDimensions.roundedSm,
                        border: Border.all(
                          color: _connectionTestResult!['success'] == true
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _connectionTestResult!['success'] == true
                                ? Icons.check_circle_outline_rounded
                                : Icons.error_outline_rounded,
                            size: 18,
                            color: _connectionTestResult!['success'] == true
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _connectionTestResult!['message']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _connectionTestResult!['success'] == true
                                    ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                                    : (isDark ? Colors.redAccent : Colors.red.shade800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Section 3: Voice & Wake Word
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
                      'Continuous on-device hotword listener (Wake words: "Hey Vega", "Vega", "Vega841").',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    activeColor: AppColors.primaryPink,
                    value: _wakeWordEnabled,
                    onChanged: (val) {
                      setState(() => _wakeWordEnabled = val);
                      _storageService.saveWakeWordEnabled(val);
                    },
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
                      onChanged: (val) {
                        setState(() => _wakeSensitivity = val);
                        _storageService.saveWakeWordSensitivity(val);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Section 4: TTS Voice Modulation
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
                    onChanged: (val) {
                      setState(() => _speechRate = val);
                      _storageService.saveSpeechRate(val);
                    },
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
                    onChanged: (val) {
                      setState(() => _speechPitch = val);
                      _storageService.saveSpeechPitch(val);
                    },
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

  Widget _buildModelStatusCard(bool isDark) {
    final status = _modelManager.status;
    final isReady = status == ModelStatus.ready;
    final isExtracting = status == ModelStatus.extracting || status == ModelStatus.verifying;

    return VegaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isReady ? Icons.check_circle_rounded : Icons.memory_rounded,
                    color: isReady ? Colors.greenAccent : AppColors.primaryPink,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    LocalModelManager.defaultModelName,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isReady
                      ? Colors.green.withOpacity(0.2)
                      : AppColors.primaryPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isReady ? 'Active / Bundled' : (isExtracting ? 'Extracting' : 'Not Ready'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isReady ? Colors.greenAccent : AppColors.primaryPink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Format: INT4 W4A16 Quantized • Size: 32 MB • License: Gemma Open Models\nIncluded directly inside APK assets. Extracted to private storage for zero-latency offline inference.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          if (isExtracting) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _modelManager.progress > 0 ? _modelManager.progress : null,
              backgroundColor: isDark ? Colors.black26 : Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryPink),
            ),
            const SizedBox(height: 4),
            Text(
              'Unpacking from APK assets: ${(_modelManager.progress * 100).toInt()}%',
              style: const TextStyle(fontSize: 11, color: AppColors.primaryPink),
            ),
          ],
          if (_modelManager.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _modelManager.errorMessage!,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Re-extract from APK', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.lavender,
                  side: const BorderSide(color: AppColors.lavender),
                  shape: RoundedRectangleBorder(borderRadius: AppDimensions.roundedSm),
                ),
                onPressed: isExtracting ? null : () => _modelManager.extractBundledModel(),
              ),
              const SizedBox(width: 8),
              if (isReady)
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                  label: const Text('Free Space', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                  onPressed: isExtracting ? null : () => _modelManager.deleteModel(),
                ),
            ],
          ),
        ],
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
