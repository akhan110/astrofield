import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';

class _ManualTopic {
  const _ManualTopic({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.accentColor,
    required this.summary,
    required this.sections,
    this.route,
    this.routeLabel,
  });

  final String id;
  final String title;
  final String category;
  final IconData icon;
  final Color accentColor;
  final String summary;
  final List<_TopicSection> sections;
  final String? route;
  final String? routeLabel;
}

class _TopicSection {
  const _TopicSection({
    required this.heading,
    required this.content,
    this.bulletPoints = const [],
  });

  final String heading;
  final String content;
  final List<String> bulletPoints;
}

class UserManualScreen extends StatefulWidget {
  const UserManualScreen({super.key});

  @override
  State<UserManualScreen> createState() => _UserManualScreenState();
}

class _UserManualScreenState extends State<UserManualScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  static const List<String> _categories = [
    'All',
    'Basics',
    'Framing & Optics',
    'Polar Alignment',
    'Planning',
    'Sensors & Night',
    'Offline & Data',
  ];

  static const List<_ManualTopic> _topics = [
    _ManualTopic(
      id: 'overview',
      title: 'AstroField Philosophy & Offline Engine',
      category: 'Basics',
      icon: Icons.auto_awesome_rounded,
      accentColor: Color(0xFF6B4EE6),
      summary:
          '100% offline-first astrophotography field companion. Zero internet required for astronomy ephemerides, twilight, and star charts.',
      sections: [
        _TopicSection(
          heading: 'Why Offline Matters',
          content:
              'The darkest skies on Earth — national parks, high-altitude plateaus, and desert reserves — rarely have cellular coverage. AstroField was engineered from the ground up to never fail in the field. All celestial calculations, twilight windows, rise/set times, and 207 catalog targets are bundled directly into the app.',
        ),
        _TopicSection(
          heading: 'Local Geometry Engine',
          content:
              'AstroField uses GeoEngine’s port of the Astronomy Engine library. Altitudes, azimuths, and sidereal times are computed mathematically on your device CPU in real time with millisecond precision.',
          bulletPoints: [
            'No server calls needed to track Moon, planets, or deep-sky targets.',
            'Times automatically format to your device timezone.',
            'Standard atmospheric refraction is applied to horizon rise and set times.',
          ],
        ),
      ],
    ),
    _ManualTopic(
      id: 'quickstart',
      title: 'Field Workflow: Quick Start Guide',
      category: 'Basics',
      icon: Icons.checklist_rounded,
      accentColor: Color(0xFF00E676),
      summary:
          'The 4 essential steps every astrophotographer should follow before and during an imaging night.',
      route: AppRoutes.location,
      routeLabel: 'Configure Observing Site',
      sections: [
        _TopicSection(
          heading: 'Step 1: Set Your Observing Site',
          content:
              'Before setting up your tripod, enter your destination site in Location & GPS. You can either tap "Use GPS to auto-fill" while connected or manually enter latitude, longitude, and elevation. AstroField remembers your site offline.',
        ),
        _TopicSection(
          heading: 'Step 2: Add Your Equipment Setup',
          content:
              'Enter your camera sensor dimensions (width, height in mm), pixel pitch (µm), and telescope effective focal length. This enables real-time field of view and arcsecond-per-pixel resolution calculation.',
        ),
        _TopicSection(
          heading: 'Step 3: Review Twilight & Moon Windows',
          content:
              'Check the Tonight Planner. The app highlights the exact astronomical darkness window (when the Sun is ≤ −18° below the horizon) and when Moon illumination or moonrise might wash out faint nebulae.',
        ),
        _TopicSection(
          heading: 'Step 4: Queue Targets & Track Live',
          content:
              'Use the Object Catalog or Session Scheduler to bookmark targets. In the field, switch to Point-to-Sky AR compass to visually aim your telescope mount toward the target.',
        ),
      ],
    ),
    _ManualTopic(
      id: 'framing',
      title: 'Framing Simulator',
      category: 'Framing & Optics',
      icon: Icons.crop_free_rounded,
      accentColor: Color(0xFF00E5FF),
      summary:
          'Simulate your camera sensor FOV rectangle over real deep-sky cutouts to plan framing, rotation, and multi-panel mosaics.',
      route: AppRoutes.framingSimulator,
      routeLabel: 'Open Framing Simulator',
      sections: [
        _TopicSection(
          heading: 'Visual Sensor Field of View',
          content:
              'The canvas displays an accurate rectangular sensor frame overlaid onto deep space. If a catalog target has a real DSS2 photographic cutout (e.g. M42, M31, M45), it is rendered at its exact angular scale relative to your sensor.',
          bulletPoints: [
            'Top arrow indicates the North orientation on your camera sensor.',
            'Cardinal axes (N, S, E, W) follow astrophotography sky convention (East is left).',
            'Rule-of-thirds grid lines assist in composing off-center nebular complexes.',
          ],
        ),
        _TopicSection(
          heading: 'Sensor Rotation & Angle Slider',
          content:
              'Rotate your camera rotator or T-ring without guessing. Move the Camera Angle slider from 0° to 360° to find the exact angle where elongated galaxies (like Andromeda) or nebulae fit inside your sensor without clipping.',
        ),
        _TopicSection(
          heading: 'Image Scale & Sampling Analysis',
          content:
              'Image scale is calculated using the standard formula: Resolution = 206.265 × Pixel Pitch (µm) / Focal Length (mm).',
          bulletPoints: [
            'Undersampled (> 2.0 "/px): Great for widefield shots; stars remain pin-sharp.',
            'Optimal (0.67 – 2.0 "/px): Ideal balance between camera resolution and typical atmospheric seeing.',
            'Oversampled (< 0.67 "/px): Atmospheric seeing limits resolution; stars may look soft or bloated.',
          ],
        ),
      ],
    ),
    _ManualTopic(
      id: 'polar',
      title: 'Polar Alignment Clock',
      category: 'Polar Alignment',
      icon: Icons.explore_rounded,
      accentColor: Color(0xFF8E72FF),
      summary:
          'Precise reticle dial showing where to place Polaris (Northern Hemisphere) or Octans (Southern Hemisphere) in your polar scope.',
      route: AppRoutes.polarAlignment,
      routeLabel: 'Open Polar Alignment Clock',
      sections: [
        _TopicSection(
          heading: 'How Polar Alignment Works',
          content:
              'Because Earth’s celestial poles do not line up exactly with Polaris (it is ~0.65° offset from the True North Celestial Pole), equatorial mounts require you to position Polaris at a specific clock angle on an etched reticle ring.',
        ),
        _TopicSection(
          heading: 'Using the Reticle Clock in the Field',
          content:
              'Look through your mount’s optical or illuminated polar scope. Rotate your mount until the 12 o’clock reticle position points straight up. Look at AstroField’s Polar Clock reticle and adjust the mount’s altitude and azimuth bolts until Polaris sits exactly inside the glowing target marker.',
          bulletPoints: [
            'Northern Hemisphere: Tracks Polaris Hour Angle based on Local Sidereal Time.',
            'Southern Hemisphere: Automatically switches to Sigma Octantis constellation pattern.',
            'Drift Error Estimation: Shows estimated tracking drift in arcseconds per minute if unguided.',
          ],
        ),
      ],
    ),
    _ManualTopic(
      id: 'scheduler',
      title: 'Session Scheduler & Timeline',
      category: 'Planning',
      icon: Icons.timeline_rounded,
      accentColor: Color(0xFF6B4EE6),
      summary:
          'Plan an entire night of multiple targets, sub-exposures, meridian flips, and dark-window timings.',
      route: AppRoutes.sessionScheduler,
      routeLabel: 'Open Session Scheduler',
      sections: [
        _TopicSection(
          heading: 'Multi-Target Queue',
          content:
              'Astrophotographers often shoot a bright nebula early in the evening and switch to a rising galaxy later. The scheduler lets you queue targets in sequence.',
          bulletPoints: [
            'Configure sub-exposure count (e.g. 40 frames) and duration (e.g. 180s).',
            'View calculated total integration time and completion timestamps.',
            'Reorder targets or delete targets with quick swipe and tap actions.',
          ],
        ),
        _TopicSection(
          heading: 'Night Timeline & Meridian Alerts',
          content:
              'The interactive timeline visualizes the full dusk-to-dawn period, highlighting astronomical darkness in midnight purple, Moon rise/set intervals, and estimated meridian crossing times where German Equatorial Mounts need a meridian flip.',
        ),
      ],
    ),
    _ManualTopic(
      id: 'compass',
      title: 'Point-to-Sky AR Compass',
      category: 'Sensors & Night',
      icon: Icons.screen_rotation_rounded,
      accentColor: Color(0xFFFFB020),
      summary:
          'Augmented reality celestial compass showing real-time target elevation, azimuth, and alignment guidance.',
      route: AppRoutes.pointToSky,
      routeLabel: 'Open Point-to-Sky',
      sections: [
        _TopicSection(
          heading: 'Calibrating Your Phone Compass',
          content:
              'Smartphone magnetometers can be influenced by metal tripod legs, counterweights, and car doors. Before aiming, wave your phone in a slow figure-8 motion for 5 seconds to calibrate the sensor.',
        ),
        _TopicSection(
          heading: 'Locking a Target & Alignment Arrows',
          content:
              'Tap on any target on the AR radar to lock onto it. AstroField displays live directional guidance arrows indicating whether to tilt your device up/down or turn left/right. When centered, the reticle turns green with haptic feedback.',
        ),
      ],
    ),
    _ManualTopic(
      id: 'redtools',
      title: 'Night Mode & Red Light Tools',
      category: 'Sensors & Night',
      icon: Icons.flashlight_on_rounded,
      accentColor: Color(0xFFFF5252),
      summary:
          'Dark adaptation screen filter, red flashlight, NPF star-trailing rule, and dew point condensation alert.',
      route: AppRoutes.redLightTools,
      routeLabel: 'Open Red Light Tools',
      sections: [
        _TopicSection(
          heading: 'Red Night Screen & Flashlight',
          content:
              'Human eyes require 20 to 30 minutes of darkness to accumulate rhodopsin for night vision. A single blast of white light resets this instantly. The Red Screen mode and Red Flashlight emit long-wavelength red photons that do not degrade your night-adapted rod cells.',
        ),
        _TopicSection(
          heading: 'NPF Rule (Star Trailing Calculator)',
          content:
              'For tripod and Milky Way astrophotography, the old "500 Rule" produces blurry, trailed stars on modern high-megapixel digital sensors. The NPF rule calculates the maximum safe exposure time based on focal length (f), aperture ratio (N), pixel pitch (p), and target declination (δ).',
        ),
        _TopicSection(
          heading: 'Dew Point Condensation Warning',
          content:
              'When ambient air temperature falls to the dew point, water vapor condenses onto cold telescope lenses and corrector plates. AstroField calculates the dew margin so you know when to turn on dew heater straps before condensation ruins your session.',
        ),
      ],
    ),
    _ManualTopic(
      id: 'catalog',
      title: '207-Object Catalog & Horizon Chart',
      category: 'Planning',
      icon: Icons.search_rounded,
      accentColor: Color(0xFF6C8FD7),
      summary:
          'Search all 110 Messier objects, brightest NGC/IC nebulae, galaxies, star clusters, planets, and solar system targets.',
      route: AppRoutes.search,
      routeLabel: 'Browse Object Catalog',
      sections: [
        _TopicSection(
          heading: 'Catalog Search & Filters',
          content:
              'Filter targets by category (Nebula, Galaxy, Cluster, Planet), constellation, minimum altitude, or magnitude. You can sort by imaging score, transit time, or altitude above horizon.',
        ),
        _TopicSection(
          heading: 'Imaging Score Heuristic',
          content:
              'Every target receives a 0–100 score based on peak altitude above atmospheric extinction, Moon angular separation, and dark window duration. A score > 80 indicates an ideal prime target for tonight.',
        ),
        _TopicSection(
          heading: 'Horizon Star Chart',
          content:
              'View all targets plotted on a 360° celestial radar. The center represents the Zenith (90° overhead), while the outer circle is the local mathematical horizon (0°).',
        ),
      ],
    ),
    _ManualTopic(
      id: 'offline',
      title: 'Offline Readiness & Weather Sync',
      category: 'Offline & Data',
      icon: Icons.download_for_offline_outlined,
      accentColor: Color(0xFF00E5FF),
      summary:
          'Verify your device is 100% prepared for off-grid travel and cache weather forecasts before losing reception.',
      route: AppRoutes.tripPack,
      routeLabel: 'Open Offline Readiness',
      sections: [
        _TopicSection(
          heading: 'Downloading Weather Forecasts',
          content:
              'While still connected to Wi-Fi or cellular data at home, tap "Download Weather Forecast" in the Sync Center. AstroField fetches hourly cloud cover, humidity, temperature, and wind speed from Open-Meteo for your saved observing site and stores it locally for offline viewing.',
        ),
        _TopicSection(
          heading: 'Airplane Mode Verification',
          content:
              'Before driving into the dark-sky site, put your phone in Airplane Mode and launch AstroField. Verify that your site, equipment profiles, favorites, and cached weather remain fully interactive.',
        ),
      ],
    ),
  ];

  List<_ManualTopic> get _filteredTopics {
    return _topics.where((t) {
      if (_selectedCategory != 'All' && t.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = t.title.toLowerCase().contains(q);
        final matchSummary = t.summary.toLowerCase().contains(q);
        final matchSections = t.sections.any((s) =>
            s.heading.toLowerCase().contains(q) ||
            s.content.toLowerCase().contains(q));
        if (!matchTitle && !matchSummary && !matchSections) return false;
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredTopics;

    return Scaffold(
      backgroundColor: const Color(0xFF070B18),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            const PageHeader(
              title: 'Field Guide & Manual',
              subtitle: 'Features walkthrough & offline guide',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xDD0D152E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF243358)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14.5),
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search_rounded,
                            color: Color(0xFF8A9BB8)),
                        hintText: 'Search guide (e.g. polar alignment, NPF, scheduler)...',
                        hintStyle: const TextStyle(color: Color(0xFF55688A), fontSize: 13.5),
                        border: InputBorder.none,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: Color(0xFF8A9BB8), size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: const Color(0x406B4EE6),
                            backgroundColor: const Color(0xCC0D152E),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF8E72FF)
                                  : const Color(0xFF243358),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF8E72FF)
                                  : const Color(0xFF8A9BB8),
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Results count
                  Text(
                    '${list.length} guide ${list.length == 1 ? "topic" : "topics"} available offline',
                    style: const TextStyle(
                      color: Color(0xFF8A9BB8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Topics List
                  for (final topic in list) _buildTopicCard(topic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(_ManualTopic topic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xDD0D152E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF243358), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: topic.accentColor.withValues(alpha: 0.15),
              border: Border.all(
                color: topic.accentColor.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: Icon(topic.icon, color: topic.accentColor, size: 22),
          ),
          title: Text(
            topic.title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              topic.summary,
              style: const TextStyle(
                color: Color(0xFF8A9BB8),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(color: Color(0xFF243358), height: 16),
                  for (final sec in topic.sections) ...[
                    Text(
                      sec.heading,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: topic.accentColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      sec.content,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB5C8E5),
                        height: 1.45,
                      ),
                    ),
                    if (sec.bulletPoints.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      for (final bp in sec.bulletPoints)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ',
                                  style: TextStyle(
                                      color: topic.accentColor,
                                      fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  bp,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF8A9BB8),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                  ],
                  if (topic.route != null) ...[
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: () => Get.toNamed(topic.route!),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text(topic.routeLabel ?? 'Open Feature'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: topic.accentColor,
                        side: BorderSide(
                          color: topic.accentColor.withValues(alpha: 0.6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
