import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/app_state.dart';
import '../mahatma/mahatma_list_screen.dart';
import '../mahatma/mahatma_form_screen.dart';
import '../vihar/vihar_list_screen.dart';
import '../vihar/vihar_form_screen.dart';
import '../route/route_list_screen.dart';
import '../route/route_form_screen.dart';
import '../route/route_detail_screen.dart';
import '../master/master_screens.dart';
import '../more/more_screen.dart';
import '../search/global_search_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardHomeView(
        onSelectTab: (index) {
          setState(() => _currentIndex = index);
        },
      ),
      const MahatmaListScreen(),
      const ViharListScreen(),
      const RouteListScreen(),
      const MoreScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStateScope.of(context),
      builder: (context, _) {
        return PopScope(
          canPop: _currentIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
            }
          },
          child: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Mahatma',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_walk_outlined),
                activeIcon: Icon(Icons.directions_walk),
                label: 'Vihar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.alt_route_outlined),
                activeIcon: Icon(Icons.alt_route),
                label: 'Routes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined),
                activeIcon: Icon(Icons.grid_view),
                label: 'More',
              ),
            ],
          ),
        ),
      );
    },
  );
  }
}

class DashboardHomeView extends StatefulWidget {
  final ValueChanged<int>? onSelectTab;

  const DashboardHomeView({super.key, this.onSelectTab});

  @override
  State<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends State<DashboardHomeView> {
  String _selectedRouteFilter = 'Today';

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _openMahatmaModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: const MahatmaFormScreen(isModal: true),
        ),
      ),
    );
  }

  void _openRouteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: const RouteFormScreen(isModal: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todayRoutes = appState.routes.where((r) {
      final d = DateTime(r.viharDate.year, r.viharDate.month, r.viharDate.day);
      return d.isAtSameMomentAs(today);
    }).toList();

    final tomorrowRoutes = appState.routes.where((r) {
      final d = DateTime(r.viharDate.year, r.viharDate.month, r.viharDate.day);
      return d.isAtSameMomentAs(tomorrow);
    }).toList();

    List<ViharRoute> displayedRoutes;
    if (_selectedRouteFilter == 'Today') {
      displayedRoutes = todayRoutes;
    } else if (_selectedRouteFilter == 'Tomorrow') {
      displayedRoutes = tomorrowRoutes;
    } else {
      displayedRoutes = appState.routes;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/vps_logo.png',
              height: 32,
              width: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text(
              'VPS Management',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Global Search',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(appState.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => appState.toggleTheme(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.loadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appState.currentUser?.fullName ?? 'Welcome to VPS Management',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Role: ${appState.currentUser?.role ?? "Administrator"}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/images/vps_logo.png',
                      height: 52,
                      width: 52,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),

              if (appState.lastErrorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          appState.lastErrorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () => appState.loadAllData(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Overview Section
              const Text(
                'Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Responsive Metric Cards Grid — Interactive OnTap to open records
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isTablet ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _MetricCard(
                    title: 'Mahatmas',
                    count: '${appState.mahatmas.length}',
                    icon: Icons.people_outline,
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MahatmaListScreen()),
                      );
                    },
                  ),
                  _MetricCard(
                    title: 'Vihars',
                    count: '${appState.vihars.length}',
                    icon: Icons.directions_walk_outlined,
                    color: const Color(0xFF0D9488),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ViharListScreen()),
                      );
                    },
                  ),
                  _MetricCard(
                    title: 'Routes',
                    count: '${appState.routes.length}',
                    icon: Icons.alt_route_outlined,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RouteListScreen()),
                      );
                    },
                  ),
                  _MetricCard(
                    title: 'Districts',
                    count: '${appState.districts.length}',
                    icon: Icons.map_outlined,
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DistrictsScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quick Actions Section
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      label: '+ Mahatma',
                      icon: Icons.person_add_alt_1,
                      color: const Color(0xFF3B82F6),
                      onTap: () => _openMahatmaModal(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionButton(
                      label: '+ Vihar',
                      icon: Icons.directions_run,
                      color: const Color(0xFF0D9488),
                      onTap: () async {
                        final res = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ViharFormScreen(appState: appState),
                          ),
                        );
                        if (res == true && context.mounted) {
                          appState.loadAllData();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionButton(
                      label: '+ Route',
                      icon: Icons.add_road,
                      color: const Color(0xFFF59E0B),
                      onTap: () => _openRouteModal(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Upcoming Vihar Routes Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Vihar Routes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      if (widget.onSelectTab != null) {
                        widget.onSelectTab!(3);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RouteListScreen()),
                        );
                      }
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Filter Tabs (Today / Tomorrow / All)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('Today (${todayRoutes.length})'),
                      selected: _selectedRouteFilter == 'Today',
                      selectedColor: AppTheme.primaryColor.withOpacity(0.18),
                      backgroundColor: Theme.of(context).cardColor,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedRouteFilter == 'Today'
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondaryLight,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedRouteFilter = 'Today');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Tomorrow (${tomorrowRoutes.length})'),
                      selected: _selectedRouteFilter == 'Tomorrow',
                      selectedColor: AppTheme.secondaryColor.withOpacity(0.18),
                      backgroundColor: Theme.of(context).cardColor,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedRouteFilter == 'Tomorrow'
                            ? AppTheme.secondaryColor
                            : AppTheme.textSecondaryLight,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedRouteFilter = 'Tomorrow');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('All (${appState.routes.length})'),
                      selected: _selectedRouteFilter == 'All',
                      selectedColor: AppTheme.accentColor.withOpacity(0.18),
                      backgroundColor: Theme.of(context).cardColor,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedRouteFilter == 'All'
                            ? AppTheme.accentColor
                            : AppTheme.textSecondaryLight,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedRouteFilter = 'All');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (displayedRoutes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_outlined, size: 36, color: Colors.grey.withOpacity(0.6)),
                      const SizedBox(height: 8),
                      Text(
                        'No Vihar Routes for $_selectedRouteFilter',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap "+ Route" above to add a new route schedule.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedRoutes.take(5).length,
                  itemBuilder: (context, index) {
                    final route = displayedRoutes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RouteDetailScreen(routeId: route.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.calendar_today, size: 12, color: AppTheme.primaryColor),
                                        const SizedBox(width: 5),
                                        Text(
                                          DateFormat('dd MMM, hh:mm a').format(route.viharDate),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: route.status == 'Active'
                                          ? Colors.green.withOpacity(0.12)
                                          : (route.status == 'Completed'
                                              ? Colors.blue.withOpacity(0.12)
                                              : Colors.orange.withOpacity(0.12)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      route.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: route.status == 'Active'
                                            ? Colors.green
                                            : (route.status == 'Completed' ? Colors.blue : Colors.orange),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.trip_origin, size: 14, color: AppTheme.primaryColor),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      route.fromLocation,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Icon(Icons.arrow_forward, size: 14, color: AppTheme.textSecondaryLight),
                                  ),
                                  const Icon(Icons.location_on, size: 14, color: AppTheme.secondaryColor),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      route.toLocation,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (route.district.isNotEmpty || route.districtInchargeInfo.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'District: ${route.district}  •  Incharge: ${route.districtInchargeInfo.split("(").first.trim()}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondaryLight),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    Icon(icon, color: color, size: 22),
                  ],
                ),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
