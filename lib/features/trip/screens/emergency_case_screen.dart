import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/incident_type.dart';

class EmergencyCaseScreen extends StatefulWidget {
  const EmergencyCaseScreen({super.key});

  @override
  State<EmergencyCaseScreen> createState() => _EmergencyCaseScreenState();
}

class _EmergencyCaseScreenState extends State<EmergencyCaseScreen> {
  static const _prefsKey = 'recent_incident_types';

  static const _cases = [
    _CaseType(icon: Icons.favorite, label: 'Heart\nAttack', color: AppColors.emergencyRed, incidentType: IncidentType.cardiac),
    _CaseType(icon: Icons.car_crash, label: 'Road\nAccident', color: AppColors.warmOrange, incidentType: IncidentType.trauma),
    _CaseType(icon: Icons.local_fire_department, label: 'Burn\nInjury', color: AppColors.warmOrange, incidentType: IncidentType.burn),
    _CaseType(icon: Icons.pregnant_woman, label: 'Pregnancy\nEmergency', color: AppColors.calmPurple, incidentType: IncidentType.obstetric),
    _CaseType(icon: Icons.psychology, label: 'Stroke', color: AppColors.emergencyRed, incidentType: IncidentType.stroke),
    _CaseType(icon: Icons.air, label: 'Breathing\nIssue', color: AppColors.medicalBlue, incidentType: IncidentType.respiratory),
    _CaseType(icon: Icons.child_care, label: 'Pediatric\nEmergency', color: AppColors.hospitalTeal, incidentType: IncidentType.pediatric),
    _CaseType(icon: Icons.more_horiz, label: 'Other', color: AppColors.mediumGray, incidentType: IncidentType.other),
  ];

  List<String> _recentTypes = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey);
    if (stored != null && mounted) {
      setState(() => _recentTypes = stored);
    }
  }

  Future<void> _saveRecent(IncidentType type) async {
    final name = type.toJson();
    _recentTypes.remove(name);
    _recentTypes.insert(0, name);
    if (_recentTypes.length > 2) _recentTypes = _recentTypes.sublist(0, 2);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _recentTypes);
  }

  void _selectCase(_CaseType c) {
    _saveRecent(c.incidentType);
    context.go(
      '/driver/severity',
      extra: {
        'label': c.label.replaceAll('\n', ' '),
        'incidentType': c.incidentType.toJson(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    // Build recent chips from persisted types
    final recentCases = _recentTypes
        .map((name) {
          final type = IncidentType.fromJson(name);
          return _cases.where((c) => c.incidentType == type).firstOrNull;
        })
        .whereType<_CaseType>()
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              GestureDetector(
                onTap: () => context.go('/driver/dashboard'),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, color: onSurface),
                    const SizedBox(width: 12),
                    Text('Select Emergency Type', style: AppTypography.heading3.copyWith(color: onSurface)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  'Choose the emergency case',
                  style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                ),
              ),
              const SizedBox(height: 24),

              // Recent
              if (recentCases.isNotEmpty) ...[
                Row(
                  children: [
                    Text('RECENT:', style: AppTypography.overline.copyWith(color: AppColors.mediumGray)),
                    const SizedBox(width: 12),
                    for (final rc in recentCases) ...[
                      GestureDetector(
                        onTap: () => _selectCase(rc),
                        child: _RecentChip(icon: rc.icon, label: rc.label.replaceAll('\n', ' ')),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: _cases.map((c) {
                    return _CaseCard(
                      caseType: c,
                      onTap: () => _selectCase(c),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaseType {
  final IconData icon;
  final String label;
  final Color color;
  final IncidentType incidentType;
  const _CaseType({required this.icon, required this.label, required this.color, required this.incidentType});
}

class _CaseCard extends StatelessWidget {
  final _CaseType caseType;
  final VoidCallback onTap;
  const _CaseCard({required this.caseType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: AppSpacing.borderRadiusCard,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: caseType.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(caseType.icon, size: 28, color: caseType.color),
            ),
            const SizedBox(height: 10),
            Text(
              caseType.label,
              textAlign: TextAlign.center,
              style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600, color: onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RecentChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.mediumGray),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption.copyWith(color: onSurface)),
        ],
      ),
    );
  }
}
