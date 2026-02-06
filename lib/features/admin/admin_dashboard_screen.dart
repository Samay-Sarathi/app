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

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spaceMd),
              child: Row(
                children: [
                  const Icon(Icons.shield, size: 24, color: AppColors.lifelineGreen),
                  const SizedBox(width: 8),
                  Text(
                    'ADMIN CONSOLE',
                    style: AppTypography.heading3.copyWith(
                      letterSpacing: 1.5,
                      color: onSurface,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      final nav = GoRouter.of(context);
                      await context.read<AuthProvider>().logout();
                      nav.go('/roles');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.logout, size: 16, color: AppColors.emergencyRed),
                          const SizedBox(width: 4),
                          Text(
                            'Logout',
                            style: AppTypography.caption.copyWith(color: AppColors.emergencyRed),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: AppColors.lifelineGreen,
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.mediumGray,
                labelStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTypography.caption,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Users'),
                  Tab(text: 'Hospitals'),
                  Tab(text: 'Trips'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _OverviewTab(),
                  _UserManagementTab(),
                  _HospitalManagementTab(),
                  _TripAnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── OVERVIEW TAB ───────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          const Row(
            children: [
              Expanded(child: _StatCard(value: '1,284', label: 'EMERGENCIES', color: AppColors.emergencyRed)),
              SizedBox(width: 10),
              Expanded(child: _StatCard(value: '4m12s', label: 'AVG RESPONSE', color: AppColors.medicalBlue)),
              SizedBox(width: 10),
              Expanded(child: _StatCard(value: '99.98%', label: 'UPTIME', color: AppColors.lifelineGreen)),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _StatCard(value: '47', label: 'ACTIVE DRIVERS', color: AppColors.warmOrange)),
              SizedBox(width: 10),
              Expanded(child: _StatCard(value: '23', label: 'HOSPITALS', color: AppColors.hospitalTeal)),
              SizedBox(width: 10),
              Expanded(child: _StatCard(value: '12', label: 'ACTIVE TRIPS', color: AppColors.calmPurple)),
            ],
          ),
          const SizedBox(height: 24),

          // Response time chart
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
                Text('Response Time Trend', style: AppTypography.heading3.copyWith(color: onSurface)),
                const SizedBox(height: 4),
                Text('Last 24 hours', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final h in [0.3, 0.45, 0.55, 0.7, 0.85, 0.95, 1.0, 0.9, 0.75, 0.6, 0.5, 0.4, 0.35, 0.5, 0.65, 0.8, 0.7, 0.55, 0.4, 0.3, 0.25, 0.35, 0.45, 0.55])
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
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
                const _LogEntry(time: '14:22', event: 'Green Corridor activated', status: 'ACTIVE', statusColor: AppColors.lifelineGreen),
                const Divider(height: 16),
                const _LogEntry(time: '14:20', event: 'Traffic Signal Override', status: 'WARNING', statusColor: AppColors.warmOrange),
                const Divider(height: 16),
                const _LogEntry(time: '14:18', event: 'Ambulance A-03 dispatched', status: 'EN ROUTE', statusColor: AppColors.medicalBlue),
                const Divider(height: 16),
                const _LogEntry(time: '14:15', event: 'Hospital Sync complete', status: 'DONE', statusColor: AppColors.lifelineGreen),
                const Divider(height: 16),
                const _LogEntry(time: '14:12', event: 'New driver registered', status: 'PENDING', statusColor: AppColors.warmOrange),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── USER MANAGEMENT TAB ────────────────────────────────────────────────

class _UserManagementTab extends StatefulWidget {
  const _UserManagementTab();

  @override
  State<_UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<_UserManagementTab> {
  String _filterRole = 'All';
  String _filterStatus = 'All';

  final _roles = ['All', 'Driver', 'Hospital', 'Police', 'Admin', 'Paramedic'];
  final _statuses = ['All', 'Pending', 'Approved', 'Rejected'];

  // Mock user data
  final List<_MockUser> _users = [
    _MockUser(name: 'Rajesh Kumar', role: 'Driver', phone: '+91 98765 43210', status: 'Pending', createdAt: '2 hours ago'),
    _MockUser(name: 'City Hospital', role: 'Hospital', phone: '+91 98765 43211', status: 'Approved', createdAt: '1 day ago'),
    _MockUser(name: 'Priya Sharma', role: 'Driver', phone: '+91 98765 43212', status: 'Pending', createdAt: '3 hours ago'),
    _MockUser(name: 'Inspector Rao', role: 'Police', phone: '+91 98765 43213', status: 'Approved', createdAt: '5 days ago'),
    _MockUser(name: 'Metro Hospital', role: 'Hospital', phone: '+91 98765 43214', status: 'Pending', createdAt: '6 hours ago'),
    _MockUser(name: 'Amit Singh', role: 'Driver', phone: '+91 98765 43215', status: 'Rejected', createdAt: '2 days ago'),
    _MockUser(name: 'Dr. Arun Medics', role: 'Paramedic', phone: '+91 98765 43216', status: 'Approved', createdAt: '1 week ago'),
    _MockUser(name: 'SP Verma', role: 'Police', phone: '+91 98765 43217', status: 'Pending', createdAt: '1 hour ago'),
  ];

  List<_MockUser> get _filteredUsers {
    return _users.where((u) {
      if (_filterRole != 'All' && u.role != _filterRole) return false;
      if (_filterStatus != 'All' && u.status != _filterStatus) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;
    final filtered = _filteredUsers;

    return Column(
      children: [
        // Filter row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Role',
                  value: _filterRole,
                  items: _roles,
                  onChanged: (v) => setState(() => _filterRole = v ?? 'All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterDropdown(
                  label: 'Status',
                  value: _filterStatus,
                  items: _statuses,
                  onChanged: (v) => setState(() => _filterStatus = v ?? 'All'),
                ),
              ),
            ],
          ),
        ),
        // Count badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
          child: Row(
            children: [
              Text(
                '${filtered.length} users',
                style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warmOrange.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  '${_users.where((u) => u.status == 'Pending').length} pending',
                  style: AppTypography.caption.copyWith(color: AppColors.warmOrange, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // User list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final user = filtered[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: _roleColor(user.role).withValues(alpha: 0.15),
                          child: Icon(
                            _roleIcon(user.role),
                            size: 20,
                            color: _roleColor(user.role),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${user.role} • ${user.phone}',
                                style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: user.status),
                      ],
                    ),
                    if (user.status == 'Pending') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Registered ${user.createdAt}',
                            style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                          ),
                          const Spacer(),
                          _ActionButton(
                            label: 'Reject',
                            color: AppColors.emergencyRed,
                            onTap: () {
                              setState(() => user.status = 'Rejected');
                            },
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            label: 'Approve',
                            color: AppColors.lifelineGreen,
                            filled: true,
                            onTap: () {
                              setState(() => user.status = 'Approved');
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Driver':
        return AppColors.medicalBlue;
      case 'Hospital':
        return AppColors.hospitalTeal;
      case 'Police':
        return AppColors.calmPurple;
      case 'Admin':
        return AppColors.lifelineGreen;
      case 'Paramedic':
        return AppColors.warmOrange;
      default:
        return AppColors.mediumGray;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'Driver':
        return Icons.local_shipping;
      case 'Hospital':
        return Icons.local_hospital;
      case 'Police':
        return Icons.shield;
      case 'Admin':
        return Icons.admin_panel_settings;
      case 'Paramedic':
        return Icons.medical_services;
      default:
        return Icons.person;
    }
  }
}

// ─── HOSPITAL MANAGEMENT TAB ────────────────────────────────────────────

class _HospitalManagementTab extends StatelessWidget {
  const _HospitalManagementTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;

    final hospitals = [
      _MockHospital(name: 'City General Hospital', beds: 45, totalBeds: 120, freeDoctors: 8, onDuty: 15, staffing: 'Adequate', chaos: 3),
      _MockHospital(name: 'Metro Medical Center', beds: 12, totalBeds: 80, freeDoctors: 3, onDuty: 10, staffing: 'Short-staffed', chaos: 7),
      _MockHospital(name: 'Apollo Emergency', beds: 30, totalBeds: 60, freeDoctors: 5, onDuty: 8, staffing: 'Full', chaos: 2),
      _MockHospital(name: 'Fortis Trauma Center', beds: 5, totalBeds: 50, freeDoctors: 1, onDuty: 6, staffing: 'Critical', chaos: 9),
      _MockHospital(name: 'Max Super Specialty', beds: 22, totalBeds: 100, freeDoctors: 6, onDuty: 12, staffing: 'Adequate', chaos: 4),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '${hospitals.length}',
                  label: 'HOSPITALS',
                  color: AppColors.hospitalTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '${hospitals.fold<int>(0, (s, h) => s + h.beds)}',
                  label: 'TOTAL BEDS FREE',
                  color: AppColors.lifelineGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '${hospitals.where((h) => h.chaos >= 7).length}',
                  label: 'HIGH CHAOS',
                  color: AppColors.emergencyRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Hospital Status', style: AppTypography.heading3.copyWith(color: onSurface)),
          const SizedBox(height: 12),

          // Hospital cards
          ...hospitals.map((h) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: h.chaos >= 7
                      ? Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.4))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_hospital, size: 20, color: _chaosColor(h.chaos)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            h.name,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _staffingColor(h.staffing).withValues(alpha: 0.1),
                            borderRadius: AppSpacing.borderRadiusFull,
                          ),
                          child: Text(
                            h.staffing,
                            style: AppTypography.overline.copyWith(color: _staffingColor(h.staffing)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bed occupancy bar
                    Row(
                      children: [
                        const Icon(Icons.bed, size: 16, color: AppColors.mediumGray),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${h.beds} / ${h.totalBeds} beds free',
                                    style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                                  ),
                                  Text(
                                    '${((h.totalBeds - h.beds) / h.totalBeds * 100).round()}% occupied',
                                    style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (h.totalBeds - h.beds) / h.totalBeds,
                                  backgroundColor: AppColors.lifelineGreen.withValues(alpha: 0.15),
                                  valueColor: AlwaysStoppedAnimation(
                                    h.beds < 10 ? AppColors.emergencyRed : AppColors.lifelineGreen,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Doctors + Chaos
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: AppColors.mediumGray),
                        const SizedBox(width: 4),
                        Text(
                          '${h.freeDoctors} free / ${h.onDuty} on duty',
                          style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                        ),
                        const Spacer(),
                        Text('Chaos: ', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                        Text(
                          '${h.chaos}/10',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _chaosColor(h.chaos),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Color _chaosColor(int chaos) {
    if (chaos <= 3) return AppColors.lifelineGreen;
    if (chaos <= 6) return AppColors.warmOrange;
    return AppColors.emergencyRed;
  }

  Color _staffingColor(String staffing) {
    switch (staffing) {
      case 'Full':
        return AppColors.lifelineGreen;
      case 'Adequate':
        return AppColors.medicalBlue;
      case 'Short-staffed':
        return AppColors.warmOrange;
      case 'Critical':
        return AppColors.emergencyRed;
      default:
        return AppColors.mediumGray;
    }
  }
}

// ─── TRIP ANALYTICS TAB ─────────────────────────────────────────────────

class _TripAnalyticsTab extends StatefulWidget {
  const _TripAnalyticsTab();

  @override
  State<_TripAnalyticsTab> createState() => _TripAnalyticsTabState();
}

class _TripAnalyticsTabState extends State<_TripAnalyticsTab> {
  String _filterType = 'All';
  String _filterStatus = 'All';

  final _types = ['All', 'Cardiac', 'Trauma', 'Stroke', 'Respiratory', 'Burn', 'Other'];
  final _tripStatuses = ['All', 'En Route', 'Arrived', 'Completed', 'Cancelled'];

  final _trips = [
    _MockTrip(id: 'TRP-001', type: 'Cardiac', severity: 9, driver: 'Rajesh K.', hospital: 'City General', status: 'En Route', eta: '4 min'),
    _MockTrip(id: 'TRP-002', type: 'Trauma', severity: 7, driver: 'Amit S.', hospital: 'Apollo ER', status: 'Arrived', eta: '—'),
    _MockTrip(id: 'TRP-003', type: 'Stroke', severity: 8, driver: 'Priya S.', hospital: 'Fortis', status: 'Completed', eta: '—'),
    _MockTrip(id: 'TRP-004', type: 'Burn', severity: 6, driver: 'Vikram R.', hospital: 'Metro MC', status: 'En Route', eta: '7 min'),
    _MockTrip(id: 'TRP-005', type: 'Respiratory', severity: 5, driver: 'Suresh M.', hospital: 'Max Super', status: 'Completed', eta: '—'),
    _MockTrip(id: 'TRP-006', type: 'Cardiac', severity: 10, driver: 'Anil K.', hospital: 'City General', status: 'En Route', eta: '2 min'),
    _MockTrip(id: 'TRP-007', type: 'Trauma', severity: 4, driver: 'Ravi P.', hospital: 'Apollo ER', status: 'Cancelled', eta: '—'),
  ];

  List<_MockTrip> get _filtered {
    return _trips.where((t) {
      if (_filterType != 'All' && t.type != _filterType) return false;
      if (_filterStatus != 'All' && t.status != _filterStatus) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;
    final filtered = _filtered;

    return Column(
      children: [
        // Summary row
        Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '${_trips.length}',
                  label: 'TOTAL TRIPS',
                  color: AppColors.medicalBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '${_trips.where((t) => t.status == 'En Route').length}',
                  label: 'ACTIVE',
                  color: AppColors.lifelineGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: (_trips.fold<int>(0, (s, t) => s + t.severity) / _trips.length).toStringAsFixed(1),
                  label: 'AVG SEVERITY',
                  color: AppColors.warmOrange,
                ),
              ),
            ],
          ),
        ),
        // Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
          child: Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Type',
                  value: _filterType,
                  items: _types,
                  onChanged: (v) => setState(() => _filterType = v ?? 'All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterDropdown(
                  label: 'Status',
                  value: _filterStatus,
                  items: _tripStatuses,
                  onChanged: (v) => setState(() => _filterStatus = v ?? 'All'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
          child: Row(
            children: [
              Text(
                '${filtered.length} trips',
                style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Trip list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final trip = filtered[index];
              final sevColor = _severityColor(trip.severity);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: AppSpacing.borderRadiusMd,
                  boxShadow: [
                    BoxShadow(
                      color: sevColor.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Gradient header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [sevColor, sevColor.withValues(alpha: 0.7)],
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            trip.id,
                            style: AppTypography.vitalS.copyWith(
                              color: AppColors.white,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.2),
                              borderRadius: AppSpacing.borderRadiusFull,
                            ),
                            child: Text(
                              'SEV ${trip.severity}',
                              style: AppTypography.overline.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _TripStatusBadge(status: trip.status, inverted: true),
                        ],
                      ),
                    ),
                    // Body
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.category, size: 14, color: sevColor),
                              const SizedBox(width: 6),
                              Text(trip.type, style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600, color: onSurface)),
                              const Spacer(),
                              const Icon(Icons.local_shipping, size: 14, color: AppColors.medicalBlue),
                              const SizedBox(width: 6),
                              Text(trip.driver, style: AppTypography.caption.copyWith(color: onSurface)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: AppSpacing.borderRadiusSm,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_hospital, size: 14, color: AppColors.hospitalTeal),
                                const SizedBox(width: 6),
                                Text(trip.hospital, style: AppTypography.caption.copyWith(color: onSurface)),
                                if (trip.eta != '—') ...[
                                  const Spacer(),
                                  Icon(Icons.timer, size: 14, color: AppColors.warmOrange),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ETA: ${trip.eta}',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.warmOrange,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _severityColor(int severity) {
    if (severity >= 8) return AppColors.emergencyRed;
    if (severity >= 5) return AppColors.warmOrange;
    return AppColors.lifelineGreen;
  }
}

// ─── SHARED WIDGETS ─────────────────────────────────────────────────────

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
          Text(value, style: AppTypography.heading3.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.overline.copyWith(color: AppColors.mediumGray)),
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
        Expanded(child: Text(event, style: AppTypography.bodyS)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: AppSpacing.borderRadiusFull,
          ),
          child: Text(status, style: AppTypography.overline.copyWith(color: statusColor)),
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          style: AppTypography.bodyS,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'Approved':
        return AppColors.lifelineGreen;
      case 'Pending':
        return AppColors.warmOrange;
      case 'Rejected':
        return AppColors.emergencyRed;
      default:
        return AppColors.mediumGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.overline.copyWith(color: _color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusSm,
          border: filled ? null : Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: filled ? AppColors.white : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TripStatusBadge extends StatelessWidget {
  final String status;
  final bool inverted;
  const _TripStatusBadge({required this.status, this.inverted = false});

  Color get _color {
    switch (status) {
      case 'En Route':
        return AppColors.medicalBlue;
      case 'Arrived':
        return AppColors.lifelineGreen;
      case 'Completed':
        return AppColors.lifelineGreen;
      case 'Cancelled':
        return AppColors.emergencyRed;
      default:
        return AppColors.mediumGray;
    }
  }

  IconData get _icon {
    switch (status) {
      case 'En Route':
        return Icons.navigation;
      case 'Arrived':
        return Icons.location_on;
      case 'Completed':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayColor = inverted ? Colors.white : _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: inverted ? Colors.white.withValues(alpha: 0.2) : _color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: displayColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: AppTypography.overline.copyWith(color: displayColor),
          ),
        ],
      ),
    );
  }
}

// ─── MOCK DATA CLASSES ──────────────────────────────────────────────────

class _MockUser {
  final String name;
  final String role;
  final String phone;
  String status;
  final String createdAt;

  _MockUser({
    required this.name,
    required this.role,
    required this.phone,
    required this.status,
    required this.createdAt,
  });
}

class _MockHospital {
  final String name;
  final int beds;
  final int totalBeds;
  final int freeDoctors;
  final int onDuty;
  final String staffing;
  final int chaos;

  const _MockHospital({
    required this.name,
    required this.beds,
    required this.totalBeds,
    required this.freeDoctors,
    required this.onDuty,
    required this.staffing,
    required this.chaos,
  });
}

class _MockTrip {
  final String id;
  final String type;
  final int severity;
  final String driver;
  final String hospital;
  final String status;
  final String eta;

  const _MockTrip({
    required this.id,
    required this.type,
    required this.severity,
    required this.driver,
    required this.hospital,
    required this.status,
    required this.eta,
  });
}
