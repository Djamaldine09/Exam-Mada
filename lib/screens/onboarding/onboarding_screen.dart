import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onFinished,
  });

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  final List<OnboardingData> _pages = const [
    OnboardingData(
      title: 'Inscrivez-vous facilement',
      description:
          'Créez votre compte, complétez vos informations et inscrivez-vous '
          'à votre examen national en quelques étapes.',
      illustrationType: IllustrationType.registration,
    ),
    OnboardingData(
      title: 'Suivez votre candidature',
      description:
          'Consultez l’état de votre dossier, déposez vos documents et '
          'recevez des notifications importantes en temps réel.',
      illustrationType: IllustrationType.tracking,
    ),
    OnboardingData(
      title: 'Votre examen, simplifié',
      description:
          'Accédez à votre convocation, votre centre d’examen, votre QR code '
          'et vos résultats depuis votre téléphone.',
      illustrationType: IllustrationType.exam,
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _nextPage() {
    if (_isLastPage) {
      widget.onFinished();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  void _previousPage() {
    if (_currentPage == 0) return;

    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _skip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _OnboardingPage(data: _pages[index]);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            AnimatedOpacity(
              opacity: _currentPage == 0 ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: _currentPage == 0,
                child: IconButton(
                  onPressed: _previousPage,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                  ),
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _skip,
              child: const Text(
                'Passer',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
      child: Column(
        children: [
          _PageIndicator(
            pageCount: _pages.length,
            currentPage: _currentPage,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0ABF83),
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: const Color(0xFF0ABF83).withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _isLastPage ? 'Commencer' : 'Continuer',
                      key: ValueKey(_isLastPage),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: widget.onFinished,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text.rich(
                TextSpan(
                  text: 'Vous avez déjà un compte ? ',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  children: [
                    TextSpan(
                      text: 'Se connecter',
                      style: TextStyle(
                        color: Color(0xFF1E3A5F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
  });

  final OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxHeight < 570;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: isSmallScreen ? 245 : 310,
                  child: Center(
                    child: Transform.scale(
                      scale: isSmallScreen ? 0.82 : 1,
                      child: _OnboardingIllustration(
                        type: data.illustrationType,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 14),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF172033),
                    fontSize: isSmallScreen ? 24 : 29,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: isSmallScreen ? 13 : 15,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({
    required this.type,
  });

  final IllustrationType type;

  @override
  Widget build(BuildContext context) {
    final illustration = switch (type) {
      IllustrationType.registration => const _RegistrationIllustration(),
      IllustrationType.tracking => const _TrackingIllustration(),
      IllustrationType.exam => const _ExamIllustration(),
    };

    return SizedBox(
      width: 330,
      height: 310,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 270,
            height: 270,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFFE6F8F1),
                  Color(0xFFF8FAFC),
                ],
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: 67,
            child: Transform.rotate(
              angle: -0.18,
              child: const _BackgroundCard(
                colors: [
                  Color(0xFFFFD369),
                  Color(0xFFA8E063),
                ],
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 65,
            child: Transform.rotate(
              angle: 0.18,
              child: const _BackgroundCard(
                colors: [
                  Color(0xFFF7A8C4),
                  Color(0xFFEF7C8E),
                ],
              ),
            ),
          ),
          illustration,
          const Positioned(
            right: 22,
            top: 49,
            child: _FloatingStatus(
              color: Color(0xFF0ABF83),
              icon: Icons.check_rounded,
            ),
          ),
          Positioned(
            bottom: 22,
            child: _FloatingStatus(
              color: type == IllustrationType.tracking
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE11D8A),
              icon: type == IllustrationType.exam
                  ? Icons.school_rounded
                  : Icons.arrow_upward_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundCard extends StatelessWidget {
  const _BackgroundCard({
    required this.colors,
  });

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 185,
      height: 195,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
    );
  }
}

class _RegistrationIllustration extends StatelessWidget {
  const _RegistrationIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 205,
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFB7AE),
            Color(0xFFE75CB9),
            Color(0xFF7C3AED),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
            blurRadius: 35,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AvatarCircle(
                icon: Icons.person_rounded,
                color: Color(0xFF1E3A5F),
                size: 54,
              ),
              SizedBox(width: 8),
              _AvatarCircle(
                icon: Icons.person_rounded,
                color: Color(0xFF0ABF83),
                size: 46,
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inscription candidat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                _FakeLine(width: 125),
                SizedBox(height: 7),
                _FakeLine(width: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingIllustration extends StatelessWidget {
  const _TrackingIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 205,
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE4DDFF),
            Color(0xFF8B7CF6),
            Color(0xFF5145CD),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5145CD).withValues(alpha: 0.25),
            blurRadius: 35,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.folder_copy_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.check_rounded,
                    color: Color(0xFF0ABF83),
                    size: 20,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dossier validé',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 5),
                      _FakeLine(width: 75),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamIllustration extends StatelessWidget {
  const _ExamIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int index = 0; index < 3; index++)
            Container(
              width: 210 - (index * 45),
              height: 210 - (index * 45),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFDCEEE8),
                  width: 1.4,
                ),
              ),
            ),
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 7,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0ABF83).withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFF1E3A5F),
              size: 66,
            ),
          ),
          const Positioned(
            top: 15,
            child: _SmallOrbitIcon(
              icon: Icons.check_rounded,
              color: Color(0xFF0ABF83),
            ),
          ),
          const Positioned(
            right: 5,
            top: 83,
            child: _SmallOrbitIcon(
              icon: Icons.qr_code_2_rounded,
              color: Color(0xFFFF8B3D),
            ),
          ),
          const Positioned(
            left: 5,
            top: 92,
            child: _SmallOrbitIcon(
              icon: Icons.notifications_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const Positioned(
            right: 37,
            bottom: 15,
            child: _SmallOrbitIcon(
              icon: Icons.description_rounded,
              color: Color(0xFF7C3AED),
            ),
          ),
          const Positioned(
            left: 37,
            bottom: 15,
            child: _SmallOrbitIcon(
              icon: Icons.location_on_rounded,
              color: Color(0xFFE11D8A),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.58,
      ),
    );
  }
}

class _SmallOrbitIcon extends StatelessWidget {
  const _SmallOrbitIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }
}

class _FloatingStatus extends StatelessWidget {
  const _FloatingStatus({
    required this.color,
    required this.icon,
  });

  final Color color;
  final IconData icon;

@override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}

class _FakeLine extends StatelessWidget {
  const _FakeLine({
    required this.width,
  });

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.pageCount,
    required this.currentPage,
  });

  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final bool isSelected = index == currentPage;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isSelected ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0ABF83)
                : const Color(0xFFD8E4E0),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}

class OnboardingData {
  const OnboardingData({
    required this.title,
    required this.description,
    required this.illustrationType,
  });

  final String title;
  final String description;
  final IllustrationType illustrationType;
}

enum IllustrationType {
  registration,
  tracking,
  exam,
}