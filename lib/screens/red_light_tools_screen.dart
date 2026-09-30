import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/field_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';

class RedLightToolsScreen extends StatefulWidget {
  const RedLightToolsScreen({super.key});

  @override
  State<RedLightToolsScreen> createState() => _RedLightToolsScreenState();
}

class _RedLightToolsScreenState extends State<RedLightToolsScreen> {
  int _selectedTab = 0; // 0: Red Light, 1: NPF Rule, 2: Dew Point, 3: Intervalometer

  // --- Tab 1: Red Light & Flashlight ---
  double _redBrightness = 0.85; // 0.1 to 1.0
  bool _fullScreenRed = false;

  // --- Tab 2: NPF & Star Trailing Rule ---
  double _focalLengthMm = 24.0;
  double _apertureF = 2.8;
  double _pixelPitchUm = 3.76; // e.g. Sony A7R IV / modern APS-C
  double _declinationDeg = 0.0; // 0° = celestial equator (fastest motion)

  // --- Tab 3: Dew Point Calculator ---
  double _ambientTempC = 16.0;
  double _humidityPct = 78.0;

  // --- Tab 4: Intervalometer Timer ---
  int _subLengthSec = 60;
  int _gapSec = 5;
  int _totalFrames = 20;

  bool _timerRunning = false;
  int _currentFrame = 1;
  int _currentSecondsLeft = 60;
  bool _isExposing = true; // true: exposing, false: gap
  Timer? _intervalTimer;

  @override
  void initState() {
    super.initState();
    final c = Get.find<FieldController>();
    // Pre-populate focal length from equipment if set
    final eq = c.selectedEquipment;
    if (eq != null) {
      _focalLengthMm = eq.focalLength.clamp(10.0, 1200.0);
      _pixelPitchUm = eq.pixelSize.clamp(1.0, 15.0);
    }
    // Pre-populate weather if cached
    final w = c.weather.value;
    if (w != null && w.hours.isNotEmpty) {
      final nowUtc = DateTime.now().toUtc();
      final currentHour = w.hours.firstWhere(
        (h) => h.time.isAfter(nowUtc.subtract(const Duration(hours: 1))),
        orElse: () => w.hours.first,
      );
      if (currentHour.temperature != null) {
        _ambientTempC = currentHour.temperature!;
      }
      if (currentHour.humidity != null) {
        _humidityPct = currentHour.humidity!;
      }
    }
  }

  @override
  void dispose() {
    _intervalTimer?.cancel();
    super.dispose();
  }

  // --- Calculations ---

  // NPF Rule: T = (16.9 * N + 0.10 * F + 13.7 * p) / (F * cos(dec))
  double get npfRuleSeconds {
    final dRad = _declinationDeg * math.pi / 180.0;
    final cosDec = math.cos(dRad).abs();
    final effectiveCos = math.max(0.05, cosDec);
    final top = 16.9 * _apertureF + 0.10 * _focalLengthMm + 13.7 * _pixelPitchUm;
    final bottom = _focalLengthMm * effectiveCos;
    return (top / bottom).clamp(0.1, 120.0);
  }

  // 500 Rule: T = 500 / F (assuming 35mm equivalent)
  double get rule500Seconds {
    return (500.0 / _focalLengthMm).clamp(0.5, 120.0);
  }

  // 300 Rule: T = 300 / F
  double get rule300Seconds {
    return (300.0 / _focalLengthMm).clamp(0.3, 120.0);
  }

  // Magnus-Tetens Dew Point formula
  double get dewPointC {
    const a = 17.27;
    const b = 237.7;
    final rhFrac = (_humidityPct / 100.0).clamp(0.01, 1.0);
    final alpha = ((a * _ambientTempC) / (b + _ambientTempC)) + math.log(rhFrac);
    return (b * alpha) / (a - alpha);
  }

  double get dewMarginC {
    return _ambientTempC - dewPointC;
  }

  void _startTimer() {
    setState(() {
      _timerRunning = true;
      _currentFrame = 1;
      _isExposing = true;
      _currentSecondsLeft = _subLengthSec;
    });

    _intervalTimer?.cancel();
    _intervalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_currentSecondsLeft > 1) {
          _currentSecondsLeft--;
        } else {
          // Transition state
          HapticFeedback.mediumImpact();
          if (_isExposing) {
            if (_currentFrame >= _totalFrames) {
              // Finished session!
              _timerRunning = false;
              timer.cancel();
              _currentSecondsLeft = 0;
              Get.snackbar(
                'Session Complete',
                'Completed $_totalFrames subs × ${_subLengthSec}s!',
                backgroundColor: AppColors.surface2,
                colorText: AppColors.textPrimary,
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }
            // Switch to gap
            _isExposing = false;
            _currentSecondsLeft = _gapSec;
          } else {
            // Switch to next frame exposure
            _currentFrame++;
            _isExposing = true;
            _currentSecondsLeft = _subLengthSec;
          }
        }
      });
    });
  }

  void _pauseTimer() {
    _intervalTimer?.cancel();
    setState(() {
      _timerRunning = false;
    });
  }

  void _resetTimer() {
    _intervalTimer?.cancel();
    setState(() {
      _timerRunning = false;
      _currentFrame = 1;
      _isExposing = true;
      _currentSecondsLeft = _subLengthSec;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FieldController>();

    // Full-screen flashlight mode
    if (_fullScreenRed) {
      return Scaffold(
        backgroundColor: Color.lerp(
          Colors.black,
          const Color(0xFFFF0000),
          _redBrightness,
        ),
        body: GestureDetector(
          onTap: () => setState(() => _fullScreenRed = false),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'RED FLASHLIGHT',
                          style: TextStyle(
                            color: Colors.black45,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black45),
                          onPressed: () => setState(() => _fullScreenRed = false),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'TAP ANYWHERE TO EXIT',
                    style: TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Slider(
                      value: _redBrightness,
                      min: 0.1,
                      max: 1.0,
                      activeColor: Colors.black54,
                      inactiveColor: Colors.black26,
                      onChanged: (v) => setState(() => _redBrightness = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Obx(() {
      final isRedModeApp = controller.redMode.value;

      return Scaffold(
        backgroundColor: isRedModeApp ? const Color(0xFF100000) : AppColors.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              PageHeader(
                title: 'Night Tools & Red Light',
                subtitle: 'Dark adaptation, NPF star rule & dew point',
                trailing: IconButton(
                  tooltip: 'Full Red Screen',
                  icon: const Icon(
                    Icons.flashlight_on_rounded,
                    color: AppColors.danger,
                  ),
                  onPressed: () => setState(() => _fullScreenRed = true),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Tab Navigation Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _tabButton(0, Icons.flashlight_on_rounded, 'Red Flashlight'),
                          const SizedBox(width: 8),
                          _tabButton(1, Icons.timelapse_rounded, 'NPF Star Rule'),
                          const SizedBox(width: 8),
                          _tabButton(2, Icons.water_drop_outlined, 'Dew Point'),
                          const SizedBox(width: 8),
                          _tabButton(3, Icons.timer_outlined, 'Intervalometer'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_selectedTab == 0) _buildRedLightTab(controller),
                    if (_selectedTab == 1) _buildNpfRuleTab(),
                    if (_selectedTab == 2) _buildDewPointTab(controller),
                    if (_selectedTab == 3) _buildIntervalometerTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _tabButton(int index, IconData icon, String label) {
    final sel = _selectedTab == index;
    return ChoiceChip(
      selected: sel,
      avatar: Icon(
        icon,
        size: 16,
        color: sel ? AppColors.danger : AppColors.textSecondary,
      ),
      label: Text(label),
      selectedColor: AppColors.danger.withValues(alpha: 0.2),
      onSelected: (val) {
        if (val) setState(() => _selectedTab = index);
      },
    );
  }

  // --- Tab 1: Red Light Flashlight & Night Adaptation ---
  Widget _buildRedLightTab(FieldController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Giant interactive red glow lamp card
        GestureDetector(
          onTap: () => setState(() => _fullScreenRed = true),
          child: Container(
            height: 190,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF0000).withValues(alpha: _redBrightness),
                  const Color(0xFF330000).withValues(alpha: _redBrightness * 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF3333).withValues(alpha: 0.7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF0000).withValues(alpha: _redBrightness * 0.4),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flashlight_on_rounded,
                  size: 52,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap for Full-Screen Red Flashlight',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Preserves 100% dark adaptation · ${(_redBrightness * 100).round()}% Intensity',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Brightness Slider Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Red Lamp Brightness',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    '${(_redBrightness * 100).round()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _redBrightness,
                min: 0.1,
                max: 1.0,
                activeColor: AppColors.danger,
                onChanged: (v) => setState(() => _redBrightness = v),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // App-wide Red Mode toggle
        AppCard(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'App-Wide Night-Vision Theme',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            subtitle: const Text(
              'Changes all screens to monochromatic deep red for telescope field sessions.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            value: controller.redMode.value,
            activeTrackColor: AppColors.danger,
            onChanged: (val) {
              controller.redMode.value = val;
              controller.persist();
            },
          ),
        ),

        const SizedBox(height: 12),

        // Scotopic Vision Science Card
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.visibility_rounded, color: AppColors.danger, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'The Science of Scotopic Vision',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Human rod photoreceptors rely on rhodopsin ("visual purple") to detect faint nebulae and galaxies. A single flash of white light bleaches rhodopsin instantly, requiring 20 to 30 minutes in darkness to recover. Red light with wavelengths above 620nm leaves rod sensitivity almost unaffected.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Tab 2: NPF Rule & 500 Rule Calculator ---
  Widget _buildNpfRuleTab() {
    final npf = npfRuleSeconds;
    final r500 = rule500Seconds;
    final r300 = rule300Seconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary NPF Result Card
        AppCard(
          child: Column(
            children: [
              const Text(
                'RECOMMENDED PINPOINT EXPOSURE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${npf.toStringAsFixed(1)}s',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                  letterSpacing: -1.0,
                ),
              ),
              Text(
                'NPF Rule · No star trailing on fixed tripod',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: npf < 5 ? AppColors.amber : AppColors.primary,
                ),
              ),
              const Divider(height: 24, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ruleResultColumn('NPF Rule (Best)', '${npf.toStringAsFixed(1)}s', AppColors.secondary),
                  _ruleResultColumn('300 Rule', '${r300.toStringAsFixed(1)}s', AppColors.primary),
                  _ruleResultColumn('500 Rule (Legacy)', '${r500.toStringAsFixed(1)}s', AppColors.amber),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Optics Sliders Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Camera & Lens Configuration',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 10),

              // Focal length
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Focal Length:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('${_focalLengthMm.round()} mm', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              Slider(
                value: _focalLengthMm,
                min: 10,
                max: 300,
                divisions: 58,
                activeColor: AppColors.secondary,
                onChanged: (v) => setState(() => _focalLengthMm = v),
              ),

              // Aperture
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Aperture:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('f/${_apertureF.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              Slider(
                value: _apertureF,
                min: 1.2,
                max: 8.0,
                divisions: 34,
                activeColor: AppColors.secondary,
                onChanged: (v) => setState(() => _apertureF = v),
              ),

              // Sensor Pixel Pitch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sensor Pixel Pitch:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('${_pixelPitchUm.toStringAsFixed(2)} µm', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              Slider(
                value: _pixelPitchUm,
                min: 2.0,
                max: 8.5,
                divisions: 26,
                activeColor: AppColors.secondary,
                onChanged: (v) => setState(() => _pixelPitchUm = v),
              ),

              // Declination
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sky Declination (δ):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('${_declinationDeg.round()}° (${_declinationDeg == 0 ? "Equator" : "Polar"})',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              Slider(
                value: _declinationDeg,
                min: 0,
                max: 89,
                divisions: 89,
                activeColor: AppColors.secondary,
                onChanged: (v) => setState(() => _declinationDeg = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ruleResultColumn(String title, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  // --- Tab 3: Dew Point Calculator ---
  Widget _buildDewPointTab(FieldController controller) {
    final dp = dewPointC;
    final margin = dewMarginC;

    // Safety classification
    Color statusColor;
    String statusTitle;
    String statusDesc;

    if (margin <= 2.5) {
      statusColor = AppColors.danger;
      statusTitle = 'CRITICAL DEW RISK';
      statusDesc = 'Lens temperature is near saturation. Turn on active heating strips immediately!';
    } else if (margin <= 5.0) {
      statusColor = AppColors.amber;
      statusTitle = 'MODERATE DEW RISK';
      statusDesc = 'High humidity. Fit a deep dew shield hood to prevent condensation.';
    } else {
      statusColor = AppColors.primary;
      statusTitle = 'SAFE / LOW DEW RISK';
      statusDesc = 'Air is comfortably above saturation point. Standard dew shield is sufficient.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dew Margin Status Card
        AppCard(
          child: Column(
            children: [
              Text(
                statusTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _dewMetricItem('Air Temp', '${_ambientTempC.toStringAsFixed(1)}°C', AppColors.textPrimary),
                  _dewMetricItem('Dew Point', '${dp.toStringAsFixed(1)}°C', AppColors.secondary),
                  _dewMetricItem('Dew Margin', '${margin.toStringAsFixed(1)}°C', statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Sliders Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ambient Temperature', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('${_ambientTempC.toStringAsFixed(1)}°C', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              Slider(
                value: _ambientTempC,
                min: -15,
                max: 40,
                divisions: 55,
                activeColor: AppColors.secondary,
                onChanged: (v) => setState(() => _ambientTempC = v),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Relative Humidity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('${_humidityPct.round()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              Slider(
                value: _humidityPct,
                min: 10,
                max: 100,
                divisions: 90,
                activeColor: AppColors.secondary,
                onChanged: (v) => setState(() => _humidityPct = v),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Dew prevention tips
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined, color: AppColors.amber, size: 16),
                  SizedBox(width: 8),
                  Text('Field Dew Prevention Tips', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '1. Fit a dew shield with length at least 1.5× the objective lens diameter.\n'
                '2. Position USB dew heater strips just behind the objective glass cell, never directly on glass.\n'
                '3. Aim for 2°C to 4°C above ambient—excessive heat produces tube currents and softens star images.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dewMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  // --- Tab 4: Intervalometer Timer ---
  Widget _buildIntervalometerTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Timer Display Dial Card
        AppCard(
          child: Column(
            children: [
              Text(
                _isExposing ? 'EXPOSING SUB-FRAME' : 'DITHER / GAP PAUSE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: _isExposing ? AppColors.secondary : AppColors.amber,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_currentSecondsLeft}s',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: _isExposing ? AppColors.secondary : AppColors.amber,
                  letterSpacing: -1.5,
                ),
              ),
              Text(
                'Frame $_currentFrame of $_totalFrames · Total ${( _subLengthSec * _totalFrames) ~/ 60}m run',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _timerRunning ? AppColors.amber : AppColors.secondary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(_timerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(
                      _timerRunning ? 'Pause' : 'Start Intervalometer',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onPressed: _timerRunning ? _pauseTimer : _startTimer,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset'),
                    onPressed: _resetTimer,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Intervalometer Settings Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sequence Parameters',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 12),

              // Sub exposure length chips
              const Text('Sub-Exposure Length:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [15, 30, 60, 120, 180, 300].map((s) {
                  return ChoiceChip(
                    label: Text('${s}s'),
                    selected: _subLengthSec == s,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _subLengthSec = s;
                          if (!_timerRunning) _currentSecondsLeft = s;
                        });
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Dither / Pause Gap chips
              const Text('Pause / Dither Gap:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [2, 5, 10, 15].map((g) {
                  return ChoiceChip(
                    label: Text('${g}s'),
                    selected: _gapSec == g,
                    onSelected: (val) {
                      if (val) setState(() => _gapSec = g);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Total Frame Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Frames to Capture:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('$_totalFrames subs', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              Slider(
                value: _totalFrames.toDouble(),
                min: 5,
                max: 120,
                divisions: 23,
                activeColor: AppColors.secondary,
                onChanged: (v) => setState(() => _totalFrames = v.round()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
