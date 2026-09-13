import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/screens/maintenance_mode_screen.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../network/rest_apis.dart';
import 'walk_through_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool appNotSynced = false;

  // Entrance: logo scale+fade, then text slides up
  late AnimationController _entranceCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _nameFade;
  late Animation<Offset> _nameSlide;
  late Animation<double> _bottomFade;

  // Glow pulse (repeating ring around logo)
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseAlpha;

  // Shimmer loader bar
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerPos;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1500));

    _logoScale = Tween<double>(begin: 0.35, end: 1.0).animate(CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(0.0, 0.55, curve: Curves.elasticOut)));

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(0.0, 0.30, curve: Curves.easeOut)));

    _nameFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(0.42, 0.70, curve: Curves.easeOut)));

    _nameSlide = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _entranceCtrl,
            curve: Interval(0.42, 0.72, curve: Curves.easeOut)));

    _bottomFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(0.72, 1.0, curve: Curves.easeOut)));

    _pulseCtrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1800))
          ..repeat();

    _pulseScale = Tween<double>(begin: 1.0, end: 2.2)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    _pulseAlpha = Tween<double>(begin: 0.45, end: 0.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    _shimmerCtrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1100))
          ..repeat();

    _shimmerPos = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _entranceCtrl.forward();

    afterBuildCreated(() {
      setStatusBarColor(Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light);
      init();
    });
  }

  Future<void> init() async {
    await appStore.setLanguage(
        getStringAsync(SELECTED_LANGUAGE_CODE, defaultValue: DEFAULT_LANGUAGE));

    await setValue(LAST_APP_CONFIGURATION_SYNCED_TIME, 0);

    await getAppConfigurations().then((value) {}).catchError((e) async {
      if (!await isNetworkAvailable()) {
        toast(errorInternetNotAvailable);
      }
      log(e);
    });

    appStore.setLoading(false);
    if (!getBoolAsync(IS_APP_CONFIGURATION_SYNCED_AT_LEAST_ONCE)) {
      appNotSynced = true;
      setState(() {});
    } else {
      int themeModeIndex =
          getIntAsync(THEME_MODE_INDEX, defaultValue: THEME_MODE_SYSTEM);
      if (themeModeIndex == THEME_MODE_SYSTEM) {
        appStore.setDarkMode(
            MediaQuery.of(context).platformBrightness == Brightness.dark);
      }
      if (!appConfigurationStore.isUserAuthorized && appStore.isLoggedIn) {
        await clearPreferences();
        if (cachedWalletHistoryList != null &&
            cachedWalletHistoryList!.isNotEmpty) {
          cachedWalletHistoryList!.clear();
        }
      }
      if (appConfigurationStore.maintenanceModeStatus) {
        MaintenanceModeScreen().launch(context,
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      } else {
        if (getBoolAsync(IS_FIRST_TIME, defaultValue: true)) {
          WalkThroughScreen().launch(context,
              isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
        } else {
          DashboardScreen().launch(context,
              isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
        }
      }
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appStore.isDarkMode;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Color(0xFF091525), Color(0xFF0D1F3C), Color(0xFF091525)]
                : [Color(0xFF1347A0), Color(0xFF2A66C9), Color(0xFF1853B4)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background circles
            _circle(top: -100, right: -90, size: 280, opacity: 0.07),
            _circle(top: 40, right: -20, size: 130, opacity: 0.05),
            _circle(bottom: -120, left: -90, size: 320, opacity: 0.07),
            _circle(bottom: 90, left: -30, size: 150, opacity: 0.05),
            _circle(
                top: context.height() * 0.38,
                left: -40,
                size: 90,
                opacity: 0.04),

            // Diagonal line grid
            CustomPaint(
              size: Size(context.width(), context.height()),
              painter: _DiagonalGridPainter(),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing glow ring + logo
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer pulse ring
                          Opacity(
                            opacity: _pulseAlpha.value * 0.5,
                            child: Container(
                              width: 130 * _pulseScale.value,
                              height: 130 * _pulseScale.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 1.2),
                              ),
                            ),
                          ),
                          // Inner glow ring
                          Opacity(
                            opacity: _pulseAlpha.value * 0.65,
                            child: Container(
                              width: 130 * (_pulseScale.value * 0.65 + 0.35),
                              height: 130 * (_pulseScale.value * 0.65 + 0.35),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.07),
                              ),
                            ),
                          ),
                          // Logo card
                          FadeTransition(
                            opacity: _logoFade,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: Container(
                                width: 118,
                                height: 118,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 32,
                                      spreadRadius: 2,
                                      offset: Offset(0, 12),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.22),
                                      blurRadius: 20,
                                      spreadRadius: -4,
                                      offset: Offset(0, -4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Image.asset(appLogo,
                                        fit: BoxFit.contain),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  44.height,

                  // App name
                  SlideTransition(
                    position: _nameSlide,
                    child: FadeTransition(
                      opacity: _nameFade,
                      child: Text(
                        APP_NAME,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                  32.height,

                  // Loader / retry
                  FadeTransition(
                    opacity: _bottomFade,
                    child: appNotSynced
                        ? Observer(
                            builder: (_) => appStore.isLoading
                                ? _buildShimmerBar()
                                : _buildRetryButton(),
                          )
                        : _buildShimmerBar(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      ),
    );
  }

  Widget _buildShimmerBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            width: 130,
            height: 3,
            child: Stack(
              children: [
                Container(color: Colors.white.withOpacity(0.15)),
                AnimatedBuilder(
                  animation: _shimmerPos,
                  builder: (_, __) {
                    final dx = (_shimmerPos.value * 1.4 - 0.15) * 130;
                    return Transform.translate(
                      offset: Offset(dx - 55, 0),
                      child: Container(
                        width: 55,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.88),
                              Colors.transparent,
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
      ],
    );
  }

  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: () {
        appStore.setLoading(true);
        init();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
            8.width,
            Text(
              language.reload,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagonalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.028)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const gap = 55.0;
    for (double x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
