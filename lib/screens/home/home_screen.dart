import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../constants.dart';
import '../../model/candidat.dart';
import '../../model/user.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';
import '../../widgets/safe_network_avatar.dart';
import '../documents/documents_tab.dart';
import '../planning/planning_tab.dart';
import '../profil/profil_tab.dart';
import 'home_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  AppUser? _currentUser;
  Candidat? _candidatData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await StorageService.getUser();
      if (mounted) setState(() => _currentUser = user);

      try {
        final response = await ApiClient.get(ApiConfig.candidatMe);
        final data = response is Map<String, dynamic>
            ? (response['data'] as Map<String, dynamic>? ?? response)
            : null;
        if (mounted && data != null) {
          setState(() => _candidatData = Candidat.fromJson(data));
        }
      } catch (e) {
        debugPrint('No candidate profile found: $e');
        if (mounted) setState(() => _candidatData = null);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await StorageService.clear();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  String _loadTodayDate() {
    return DateFormat('d MMM', 'fr_FR').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        leadingWidth: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SafeNetworkAvatar(
                  imageUrl: _currentUser?.photoUrl,
                  radius: 20,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                  fallbackIcon: Icons.person,
                  fallbackIconColor: isDark ? Colors.white : Colors.grey[600],
                  fallbackIconSize: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, ${_currentUser?.displayName.split(' ').first ?? 'Candidate'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Aujourd’hui',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[400] : Colors.black,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: ' ${_loadTodayDate()}',
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[600] : Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              onPressed: () {},
              icon: Container(
                padding: const EdgeInsets.all(4),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    isDark ? Colors.white : Colors.black,
                    BlendMode.srcIn,
                  ),
                  child: Lottie.asset(
                    'asset/lottie/lottieflow-search-09-000000-easey.json',
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return HomeTab(
          currentUser: _currentUser,
          candidat: _candidatData,
          onRefresh: _loadData,
        );
      case 1:
        return PlanningTab(candidat: _candidatData);
      case 2:
        return const DocumentsTab();
      case 3:
        return ProfilTab(
          currentUser: _currentUser,
          candidat: _candidatData,
          onRefresh: _loadData,
          onLogout: _logout,
        );
      default:
        return HomeTab(
          currentUser: _currentUser,
          candidat: _candidatData,
          onRefresh: _loadData,
        );
    }
  }

  Widget _buildCustomBottomNavBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(
          height: 65,
          margin: const EdgeInsets.symmetric(horizontal: 79),
          decoration: BoxDecoration(
              color: const Color(0xFF131313),
              borderRadius: BorderRadius.circular(35),
              border:
                  Border.all(color: Colors.white.withOpacity(0.12), width: 1)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_outlined),
              _buildNavItem(1, Icons.grid_view_rounded),
              _buildNavItem(2, Icons.bar_chart_rounded),
              _buildNavItem(3, Icons.person_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.white : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.grey[500],
          size: 24,
        ),
      ),
    );
  }
}
