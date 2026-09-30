import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/field_controller.dart';
import '../domain/field_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';

class SessionSchedulerScreen extends StatefulWidget {
  const SessionSchedulerScreen({super.key});

  @override
  State<SessionSchedulerScreen> createState() => _SessionSchedulerScreenState();
}

class _SessionSchedulerScreenState extends State<SessionSchedulerScreen> {
  // Target ID -> Allocated exposure duration in minutes
  final Map<String, int> _allocations = {};

  // Sub-exposure length in seconds (e.g. 60, 120, 180, 300)
  int _subLengthSeconds = 120;

  @override
  void initState() {
    super.initState();
    final c = Get.find<FieldController>();
    if (c.planned.isEmpty) {
      // Pre-seed with top 2 available targets tonight if none are planned
      final avail = c.targets(tonight: true);
      if (avail.isNotEmpty) {
        c.planned.add(avail.first.object.id);
        if (avail.length > 1) {
          c.planned.add(avail[1].object.id);
        }
        c.persist();
      }
    }
  }

  int _getAllocation(String id) {
    return _allocations[id] ?? 120; // default 2 hours (120 mins)
  }

  void _setAllocation(String id, int minutes) {
    setState(() {
      _allocations[id] = minutes.clamp(15, 600);
    });
  }

  void _optimizeSequence(List<TargetPlan> plans) {
    final c = Get.find<FieldController>();
    // Sort plans by transit time or peak time
    final sorted = List<TargetPlan>.from(plans);
    sorted.sort((a, b) {
      final tA = a.transit ?? a.peak.time;
      final tB = b.transit ?? b.peak.time;
      return tA.compareTo(tB);
    });

    c.planned.clear();
    for (final p in sorted) {
      c.planned.add(p.object.id);
    }
    c.persist();
    Get.snackbar(
      'Sequence Optimized',
      'Targets reordered chronologically by transit & peak altitude.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface2,
      colorText: AppColors.textPrimary,
      duration: const Duration(seconds: 3),
    );
  }

  void _copySessionPlan(List<TargetPlan> plans, DateTime? darkStart, DateTime? darkEnd) {
    if (plans.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('🔭 ASTROFIELD IMAGING SESSION PLAN');
    buffer.writeln('===================================');

    if (darkStart != null && darkEnd != null) {
      buffer.writeln(
        'Astronomical Darkness: ${_formatTime(darkStart.toLocal())} - ${_formatTime(darkEnd.toLocal())} '
        '(${darkEnd.difference(darkStart).inHours}h ${darkEnd.difference(darkStart).inMinutes % 60}m)',
      );
    }
    buffer.writeln('Sub-exposure length: ${_subLengthSeconds}s\n');

    DateTime? cursor = darkStart?.toLocal();

    for (var i = 0; i < plans.length; i++) {
      final p = plans[i];
      final mins = _getAllocation(p.object.id);
      final subs = (mins * 60) ~/ _subLengthSeconds;
      final start = cursor;
      final end = cursor?.add(Duration(minutes: mins));
      if (end != null) cursor = end;

      buffer.writeln('${i + 1}. [${p.object.id}] ${p.object.name} (${p.object.type})');
      if (start != null && end != null) {
        buffer.writeln('   Session Slot: ${_formatTime(start)} - ${_formatTime(end)} (${mins ~/ 60}h ${mins % 60}m)');
      }
      buffer.writeln('   Frames: $subs subs × ${_subLengthSeconds}s');
      buffer.writeln('   Peak Altitude: ${p.peak.position.altitude.toStringAsFixed(1)}°');
      if (p.transit != null) {
        buffer.writeln('   Transit (Meridian): ${_formatTime(p.transit!.toLocal())}');
      }
      buffer.writeln('   Moon Separation: ${p.moonSeparation.toStringAsFixed(0)}°');
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    Get.snackbar(
      'Session Plan Copied',
      'Complete run sequence and sub counts copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface2,
      colorText: AppColors.textPrimary,
      duration: const Duration(seconds: 3),
    );
  }

  void _showAddTargetSheet(BuildContext context, FieldController controller) {
    final searchCtrl = TextEditingController();
    var filter = 'All';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allTargets = controller.report.value?.targets ?? <TargetPlan>[];
            final query = searchCtrl.text.trim().toLowerCase();

            final filtered = allTargets.where((t) {
              if (controller.planned.contains(t.object.id)) return false;
              if (query.isNotEmpty) {
                final match = '${t.object.id} ${t.object.name} ${t.object.type}'
                    .toLowerCase()
                    .contains(query);
                if (!match) return false;
              }
              if (filter == 'Messier') return RegExp(r'^M\d+$').hasMatch(t.object.id);
              if (filter == 'Nebulae') return t.object.type.toLowerCase().contains('nebula');
              if (filter == 'Galaxies') return t.object.type.toLowerCase().contains('galaxy');
              if (filter == 'Clusters') return t.object.type.toLowerCase().contains('cluster');
              return true;
            }).toList();

            filtered.sort((a, b) => b.nightScore.compareTo(a.nightScore));

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollCtrl) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Target to Session',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search catalog by name or ID (e.g. M31, Orion)...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          filled: true,
                          fillColor: AppColors.surface2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Messier', 'Nebulae', 'Galaxies', 'Clusters']
                              .map((f) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(f, style: const TextStyle(fontSize: 11)),
                                      selected: filter == f,
                                      onSelected: (val) {
                                        if (val) setSheetState(() => filter = f);
                                      },
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No matching unassigned targets tonight.',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollCtrl,
                                itemCount: filtered.length,
                                itemBuilder: (context, idx) {
                                  final p = filtered[idx];
                                  final score = p.nightScore;
                                  return Card(
                                    color: AppColors.surface2,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: AppColors.border),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 4,
                                      ),
                                      title: Text(
                                        '${p.object.id} · ${p.object.name}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${p.object.type} · Max ${p.peak.position.altitude.toStringAsFixed(0)}° · Moon ${p.moonSeparation.toStringAsFixed(0)}° away',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: (score > 60
                                                      ? AppColors.primary
                                                      : AppColors.amber)
                                                  .withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Score $score',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: score > 60
                                                    ? AppColors.primary
                                                    : AppColors.amber,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle_outline_rounded,
                                              color: AppColors.secondary,
                                            ),
                                            onPressed: () {
                                              controller.planned.add(p.object.id);
                                              controller.persist();
                                              Navigator.of(context).pop();
                                              setState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FieldController>();

    return Obx(() {
      final rep = controller.report.value;
      final plannedIds = controller.planned.toList();

      // Resolve targets from report
      final allTargets = rep?.targets ?? <TargetPlan>[];
      final targetMap = {for (final t in allTargets) t.object.id: t};
      final scheduledPlans = plannedIds
          .map((id) => targetMap[id])
          .whereType<TargetPlan>()
          .toList();

      // Astronomical darkness windows
      final darkWindows = rep?.darkness ?? <ImagingWindow>[];
      final primaryDark = darkWindows.isNotEmpty ? darkWindows.first : null;
      final darkStart = primaryDark?.start;
      final darkEnd = primaryDark?.end;

      // Calculate total scheduled minutes
      var totalScheduledMinutes = 0;
      for (final p in scheduledPlans) {
        totalScheduledMinutes += _getAllocation(p.object.id);
      }
      final totalDarkMinutes = primaryDark?.duration.inMinutes ?? 0;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              PageHeader(
                title: 'Session Scheduler',
                subtitle: 'Multi-target night sequence & darkness allocation',
                trailing: IconButton(
                  tooltip: 'Add Target',
                  icon: const Icon(
                    Icons.add_task_rounded,
                    color: AppColors.secondary,
                  ),
                  onPressed: () => _showAddTargetSheet(context, controller),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Overview stats row
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Dark Window',
                            darkStart != null && darkEnd != null
                                ? '${_formatTime(darkStart.toLocal())} - ${_formatTime(darkEnd.toLocal())}'
                                : 'Twilight Only',
                            darkStart != null && darkEnd != null
                                ? '${darkEnd.difference(darkStart).inHours}h ${darkEnd.difference(darkStart).inMinutes % 60}m deep sky'
                                : 'No full darkness',
                            Icons.dark_mode_outlined,
                            AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            'Planned Run',
                            '${totalScheduledMinutes ~/ 60}h ${totalScheduledMinutes % 60}m',
                            '${scheduledPlans.length} target${scheduledPlans.length == 1 ? "" : "s"} queued',
                            Icons.timer_outlined,
                            totalScheduledMinutes <= totalDarkMinutes
                                ? AppColors.primary
                                : AppColors.amber,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Night Timeline Visualizer
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Night Schedule Timeline',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (rep?.moonIllumination != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Moon ${(rep!.moonIllumination * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.amber,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Visual timeline canvas
                          SizedBox(
                            height: 110,
                            child: CustomPaint(
                              size: const Size(double.infinity, 110),
                              painter: _NightTimelinePainter(
                                report: rep,
                                darkStart: darkStart,
                                darkEnd: darkEnd,
                                plans: scheduledPlans,
                                allocations: _allocations,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Timeline legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _legendItem(const Color(0xFF0D1B2A), 'Astro Dark'),
                              _legendItem(const Color(0xFF1E3A8A), 'Twilight'),
                              _legendItem(AppColors.secondary, 'Scheduled Targets'),
                              _legendItem(AppColors.amber, 'Moonlit'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Target Queue Header & Action Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Imaging Queue (${scheduledPlans.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            if (scheduledPlans.length > 1)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.auto_fix_high_rounded,
                                  size: 14,
                                  color: AppColors.secondary,
                                ),
                                label: const Text(
                                  'Auto-Order',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                onPressed: () => _optimizeSequence(scheduledPlans),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                backgroundColor: AppColors.secondary,
                                foregroundColor: AppColors.background,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: () => _showAddTargetSheet(context, controller),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Scheduled Target Cards
                    if (scheduledPlans.isEmpty)
                      AppCard(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 40,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No Targets in Night Queue',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add deep-sky objects from your catalog or favorites to sequence an optimal imaging run.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: AppColors.background,
                              ),
                              onPressed: () => _showAddTargetSheet(context, controller),
                              child: const Text('Browse 207-Object Catalog'),
                            ),
                          ],
                        ),
                      )
                    else
                      ...List.generate(scheduledPlans.length, (index) {
                        final p = scheduledPlans[index];
                        final id = p.object.id;
                        final mins = _getAllocation(id);
                        final subs = (mins * 60) ~/ _subLengthSeconds;

                        // Check meridian flip risk
                        final transit = p.transit;
                        final bestWin = p.bestWindow;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title row with order badge and reorder buttons
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.secondary,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.background,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$id · ${p.object.name}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '${p.object.type} · ${p.object.constellation.isNotEmpty ? p.object.constellation : "Deep Sky"}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Move Up
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_upward_rounded,
                                        size: 18,
                                      ),
                                      onPressed: index > 0
                                          ? () {
                                              final list = controller.planned.toList();
                                              final item = list.removeAt(index);
                                              list.insert(index - 1, item);
                                              controller.planned.assignAll(list);
                                              controller.persist();
                                            }
                                          : null,
                                    ),
                                    // Move Down
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_downward_rounded,
                                        size: 18,
                                      ),
                                      onPressed: index < scheduledPlans.length - 1
                                          ? () {
                                              final list = controller.planned.toList();
                                              final item = list.removeAt(index);
                                              list.insert(index + 1, item);
                                              controller.planned.assignAll(list);
                                              controller.persist();
                                            }
                                          : null,
                                    ),
                                    // Remove
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: AppColors.danger,
                                      ),
                                      onPressed: () {
                                        controller.planned.remove(id);
                                        controller.persist();
                                      },
                                    ),
                                  ],
                                ),

                                const Divider(height: 16, color: AppColors.border),

                                // Metrics grid
                                Row(
                                  children: [
                                    Expanded(
                                      child: _metricColumn(
                                        'Peak Altitude',
                                        '${p.peak.position.altitude.toStringAsFixed(1)}°',
                                        transit != null ? 'at ${_formatTime(transit.toLocal())}' : 'Tonight',
                                        AppColors.primary,
                                      ),
                                    ),
                                    Expanded(
                                      child: _metricColumn(
                                        'Moon Dist',
                                        '${p.moonSeparation.toStringAsFixed(0)}°',
                                        p.moonSeparation > 60 ? 'Safe / Dark' : 'Moonlit sky',
                                        p.moonSeparation > 60 ? AppColors.secondary : AppColors.amber,
                                      ),
                                    ),
                                    Expanded(
                                      child: _metricColumn(
                                        'Window',
                                        bestWin != null
                                            ? '${bestWin.duration.inHours}h ${bestWin.duration.inMinutes % 60}m'
                                            : 'Limited',
                                        bestWin != null ? '>30° altitude' : 'Low altitude',
                                        AppColors.violet,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Exposure Allocation Slider
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Target Exposure Time:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface2,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Text(
                                        '${mins ~/ 60}h ${mins % 60}m ($subs × ${_subLengthSeconds}s subs)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                Slider(
                                  value: mins.toDouble(),
                                  min: 15,
                                  max: 360,
                                  divisions: 23,
                                  label: '${mins ~/ 60}h ${mins % 60}m',
                                  activeColor: AppColors.secondary,
                                  onChanged: (val) {
                                    _setAllocation(id, val.round());
                                  },
                                ),

                                // Meridian Transit Info
                                if (transit != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface2,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.compare_arrows_rounded,
                                          size: 14,
                                          color: AppColors.amber,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Meridian Transit: ${_formatTime(transit.toLocal())} · Check mount cable clearance for flip.',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 10),

                    // Sub-exposure configuration & Export Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.camera_rounded,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Camera Sub-Exposure Duration',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [30, 60, 120, 180, 300, 600].map((s) {
                              final sel = _subLengthSeconds == s;
                              return ChoiceChip(
                                label: Text('${s}s'),
                                selected: sel,
                                onSelected: (val) {
                                  if (val) setState(() => _subLengthSeconds = s);
                                },
                              );
                            }).toList(),
                          ),
                          const Divider(height: 20, color: AppColors.border),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.surface2,
                                    foregroundColor: AppColors.textPrimary,
                                    side: const BorderSide(color: AppColors.border),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.copy_rounded, size: 16),
                                  label: const Text(
                                    'Copy Plan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onPressed: scheduledPlans.isNotEmpty
                                      ? () => _copySessionPlan(scheduledPlans, darkStart, darkEnd)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: AppColors.background,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                                  label: const Text(
                                    'Save Session',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onPressed: scheduledPlans.isNotEmpty
                                      ? () {
                                          controller.persist();
                                          Get.snackbar(
                                            'Session Saved',
                                            '${scheduledPlans.length} targets scheduled and synced for offline field use.',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: AppColors.surface2,
                                            colorText: AppColors.textPrimary,
                                          );
                                        }
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _statCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricColumn(
    String label,
    String value,
    String sub,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _NightTimelinePainter extends CustomPainter {
  const _NightTimelinePainter({
    required this.report,
    required this.darkStart,
    required this.darkEnd,
    required this.plans,
    required this.allocations,
  });

  final NightReport? report;
  final DateTime? darkStart, darkEnd;
  final List<TargetPlan> plans;
  final Map<String, int> allocations;

  @override
  void paint(Canvas canvas, Size size) {
    final rep = report;
    if (rep == null) return;

    final nightStart = rep.start;
    final nightEnd = rep.end;
    final totalDuration = nightEnd.difference(nightStart).inSeconds;
    if (totalDuration <= 0) return;

    // Draw base twilight backdrop
    final bgPaint = Paint()..color = const Color(0xFF132238);
    final bgRect = RRect.fromRectAndRadius(
      Offset.zero & Size(size.width, 24),
      const Radius.circular(6),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Draw Astronomical darkness segment
    if (darkStart != null && darkEnd != null) {
      final sFract = (darkStart!.difference(nightStart).inSeconds / totalDuration).clamp(0.0, 1.0);
      final eFract = (darkEnd!.difference(nightStart).inSeconds / totalDuration).clamp(0.0, 1.0);

      final darkPaint = Paint()..color = const Color(0xFF060A12);
      final darkRect = Rect.fromLTWH(
        size.width * sFract,
        0,
        size.width * (eFract - sFract),
        24,
      );
      canvas.drawRect(darkRect, darkPaint);
    }

    // Border around darkness bar
    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(bgRect, borderPaint);

    // Draw Target Allocation Blocks below the darkness bar
    var cursorMinutes = 0;
    final baseOffsetSec = darkStart != null
        ? darkStart!.difference(nightStart).inSeconds
        : 0;

    final targetColors = [
      AppColors.secondary,
      AppColors.violet,
      AppColors.primary,
      AppColors.amber,
      Colors.tealAccent,
      Colors.pinkAccent,
    ];

    for (var i = 0; i < plans.length; i++) {
      final p = plans[i];
      final mins = allocations[p.object.id] ?? 120;
      final startSec = baseOffsetSec + cursorMinutes * 60;
      final endSec = startSec + mins * 60;
      cursorMinutes += mins;

      final sFract = (startSec / totalDuration).clamp(0.0, 1.0);
      final eFract = (endSec / totalDuration).clamp(0.0, 1.0);

      final color = targetColors[i % targetColors.length];
      final barPaint = Paint()..color = color.withValues(alpha: 0.85);

      final targetRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * sFract,
          32,
          math.max(4.0, size.width * (eFract - sFract)),
          22,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(targetRect, barPaint);

      // Target Label
      final tp = TextPainter(
        text: TextSpan(
          text: p.object.id,
          style: const TextStyle(
            color: Color(0xFF000000),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: math.max(10.0, size.width * (eFract - sFract)));

      if (tp.width <= size.width * (eFract - sFract)) {
        tp.paint(
          canvas,
          Offset(
            size.width * sFract + (size.width * (eFract - sFract) - tp.width) / 2,
            36,
          ),
        );
      }
    }

    // Time ticks along the bottom
    final tickHours = [18, 20, 22, 0, 2, 4, 6];
    final textStyle = const TextStyle(fontSize: 8, color: AppColors.textSecondary);

    for (final h in tickHours) {
      // Find approximate fraction across night
      var dt = DateTime(nightStart.year, nightStart.month, nightStart.day, h);
      if (h < 12) {
        dt = dt.add(const Duration(days: 1));
      }
      final diff = dt.toUtc().difference(nightStart).inSeconds;
      if (diff >= 0 && diff <= totalDuration) {
        final f = diff / totalDuration;
        final x = size.width * f;

        canvas.drawLine(
          Offset(x, 24),
          Offset(x, 28),
          Paint()..color = AppColors.border..strokeWidth = 1,
        );

        final label = TextPainter(
          text: TextSpan(text: '${h.toString().padLeft(2, '0')}:00', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(canvas, Offset(x - label.width / 2, 60));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NightTimelinePainter oldDelegate) => true;
}
