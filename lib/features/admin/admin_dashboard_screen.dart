import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/auth_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedNav = 2; // Analytics selected

  final _navItems = const [
    'OVERVIEW',
    'PERFORMANCE',
    'ANALYTICS',
    'REPORTS',
    'LOGS',
    'SETTINGS',
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      body: SafeArea(
        child: isWide ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 220,
          color: AppColors.commandDark,
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield, size: 24, color: AppColors.lifelineGreen),
                  const SizedBox(width: 8),
                  Text(
                    'GRIDCORE',
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ...List.generate(_navItems.length, (i) {
                final isActive = i == _selectedNav;
                return GestureDetector(
                  onTap: () => setState(() => _selectedNav = i),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.lifelineGreen.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Row(
                      children: [
                        if (isActive)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.lifelineGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          _navItems[i],
                          style: AppTypography.bodyS.copyWith(
                            color: isActive ? AppColors.lifelineGreen : AppColors.white.withValues(alpha: 0.6),
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const Spacer(),
              // Network status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lifelineGreen.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi, size: 16, color: AppColors.lifelineGreen),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NETWORK', style: AppTypography.overline.copyWith(color: AppColors.lifelineGreen)),
                        Text('142 nodes', style: AppTypography.caption.copyWith(color: AppColors.white.withValues(alpha: 0.5))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final nav = GoRouter.of(context);
                  await context.read<AuthProvider>().logout();
                  nav.go('/roles');
                },
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 18, color: AppColors.mediumGray),
                    const SizedBox(width: 8),
                    Text('LOGOUT', style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main content
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final nav = GoRouter.of(context);
                  await context.read<AuthProvider>().logout();
                  nav.go('/roles');
                },
                child: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.shield, size: 22, color: AppColors.lifelineGreen),
              const SizedBox(width: 8),
              Text('GRIDCORE', style: AppTypography.heading3.copyWith(letterSpacing: 1, color: Theme.of(context).colorScheme.onSurface)),
              const Spacer(),
              Text('Dashboard', style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
            ],
          ),
        ),
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  Widget _buildMainContent() {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard Overview', style: AppTypography.heading2.copyWith(color: onSurface)),
          const SizedBox(height: 20),

          // Stats cards
          Row(
            children: [
              Expanded(child: _StatCard(value: '1,284', label: 'EMERGENCIES', color: AppColors.emergencyRed)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(value: '4m12s', label: 'AVG RESPONSE', color: AppColors.medicalBlue)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(value: '99.98%', label: 'UPTIME', color: AppColors.lifelineGreen)),
            ],
          ),
          const SizedBox(height: 24),

          // Response time chart placeholder
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: AppSpacing.borderRadiusLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Response Time', style: AppTypography.heading3.copyWith(color: onSurface)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final h in [0.2, 0.35, 0.5, 0.65, 0.75, 0.85, 0.95, 1.0, 0.95, 0.85, 0.75, 0.65, 0.5, 0.35, 0.2])
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 120 * h,
                            decoration: BoxDecoration(
                              color: AppColors.lifelineGreen.withValues(alpha: h),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Live logs
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: AppSpacing.borderRadiusLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('LIVE LOGS', style: AppTypography.heading3.copyWith(color: onSurface)),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.lifelineGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _LogEntry(time: '14:22', event: 'Green Corridor', status: 'ACTIVE', statusColor: AppColors.lifelineGreen),
                const Divider(height: 16),
                _LogEntry(time: '14:20', event: 'Traffic Signal', status: 'WARNING', statusColor: AppColors.warmOrange),
                const Divider(height: 16),
                _LogEntry(time: '14:18', event: 'Ambulance A-03', status: 'EN ROUTE', statusColor: AppColors.medicalBlue),
                const Divider(height: 16),
                _LogEntry(time: '14:15', event: 'Hospital Sync', status: 'COMPLETE', statusColor: AppColors.lifelineGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.heading3.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.overline.copyWith(color: AppColors.mediumGray),
          ),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final String time;
  final String event;
  final String status;
  final Color statusColor;
  const _LogEntry({required this.time, required this.event, required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(time, style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(event, style: AppTypography.bodyS),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: AppSpacing.borderRadiusFull,
          ),
          child: Text(
            status,
            style: AppTypography.overline.copyWith(color: statusColor),
          ),
        ),
      ],
    );
  }
}
