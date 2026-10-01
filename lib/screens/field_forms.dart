import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/field_controller.dart';
import '../domain/field_models.dart';
import '../widgets/page_header.dart';

// Widget state owns disposable text controllers; app state stays in GetX.
class FieldForm extends StatefulWidget {
  const FieldForm({super.key, this.location = false});
  final bool location;
  @override
  State<FieldForm> createState() => _FieldFormState();
}

class _FieldFormState extends State<FieldForm> {
  final c = Get.find<FieldController>();
  final form = GlobalKey<FormState>();
  late final int? index =
      !widget.location && Get.arguments is int ? Get.arguments as int : null;
  late final fields = _createFields();
  bool saving = false;
  List<TextEditingController> _createFields() {
    if (widget.location) {
      final s = c.site.value;
      return [
        s?.name ?? 'Observing site',
        s?.latitude.toString() ?? '',
        s?.longitude.toString() ?? '',
        s?.elevation.toString() ?? '0'
      ].map((s) => TextEditingController(text: s)).toList();
    }
    final e = index == null ? null : c.equipment[index!];
    return [
      e?.name ?? '',
      e?.width.toString() ?? '',
      e?.height.toString() ?? '',
      e?.focalLength.toString() ?? '',
      e?.pixelSize.toString() ?? ''
    ].map((s) => TextEditingController(text: s)).toList();
  }

  @override
  void dispose() {
    for (final f in fields) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.location
        ? [
            'Site name',
            'Latitude (south negative)',
            'Longitude (west negative)',
            'Elevation (metres)'
          ]
        : [
            'Setup name',
            'Sensor width (mm)',
            'Sensor height (mm)',
            'Effective focal length (mm)',
            'Pixel size (µm)'
          ];
    final ranges = widget.location
        ? [(-90.0, 90.0), (-180.0, 180.0), (-500.0, 10000.0)]
        : [(.1, 200.0), (.1, 200.0), (1.0, 100000.0), (.1, 100.0)];

    return Scaffold(
      backgroundColor: const Color(0xFF070B18),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              PageHeader(
                title: widget.location
                    ? 'Location & GPS'
                    : 'Equipment setup',
                subtitle: widget.location
                    ? 'GPS or manual coordinates'
                    : 'Sensor and effective focal length',
              ),
              Obx(() => c.message.value.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xCC1A1F3D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF5D51D6)),
                        ),
                        child: Text(
                          c.message.value,
                          style: const TextStyle(color: Color(0xFFB5C8E5)),
                        ),
                      ),
                    )),
              if (widget.location)
                Obx(() => FilledButton.icon(
                      onPressed: c.locating.value
                          ? null
                          : () async {
                              await c.gps();
                              final s = c.site.value;
                              if (!mounted || s == null) return;
                              final values = [
                                s.name,
                                '${s.latitude}',
                                '${s.longitude}',
                                '${s.elevation}'
                              ];
                              for (var i = 0; i < fields.length; i++) {
                                fields[i].text = values[i];
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5D51D6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.gps_fixed),
                      label: Text(c.locating.value
                          ? 'Acquiring location…'
                          : 'Use GPS to auto-fill'),
                    )),
              const SizedBox(height: 16),
              for (var i = 0; i < fields.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xDD0D152E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF243358)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextFormField(
                      controller: fields[i],
                      style: const TextStyle(color: Colors.white, fontSize: 14.5),
                      decoration: InputDecoration(
                        labelText: labels[i],
                        labelStyle: const TextStyle(color: Color(0xFF8A9BB8)),
                        border: InputBorder.none,
                      ),
                      keyboardType: i == 0
                          ? TextInputType.text
                          : const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                      validator: (value) {
                        if (i == 0) {
                          return value == null || value.trim().isEmpty
                              ? 'Enter a name'
                              : null;
                        }
                        final n = double.tryParse(value?.trim() ?? '');
                        final range = ranges[i - 1];
                        return n == null ||
                                !n.isFinite ||
                                n < range.$1 ||
                                n > range.$2
                            ? 'Enter a number from ${range.$1} to ${range.$2}'
                            : null;
                      },
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xCC0B1124),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E2B4C)),
                ),
                child: Text(
                  widget.location
                      ? 'Times use the device timezone, including for remote sites. GPS can take longer without internet; manual coordinates remain available.'
                      : 'Include any reducer or Barlow in the effective focal length. Field of view and image scale are calculated locally.',
                  style: const TextStyle(color: Color(0xFF8A9BB8), fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        setState(() => saving = true);
                        double n(int i) =>
                            double.parse(fields[i].text.trim());
                        if (widget.location) {
                          await c.setSite(Site(n(1), n(2),
                              elevation: n(3),
                              name: fields[0].text.trim()));
                        } else {
                          final e = Equipment(fields[0].text.trim(), n(1),
                              n(2), n(3), n(4));
                          if (index == null) {
                            c.equipment.add(e);
                            c.activeEquipment.value =
                                c.equipment.length - 1;
                          } else {
                            c.equipment[index!] = e;
                          }
                          await c.persist();
                        }
                        if (mounted) {
                          setState(() => saving = false);
                          Get.back();
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5D51D6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  saving ? 'Saving…' : 'Save',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
