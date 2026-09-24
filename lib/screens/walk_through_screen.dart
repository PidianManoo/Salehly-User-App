import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:booking_system_flutter/utils/widgets/custom_dotindicator.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';

class WalkThroughScreen extends StatefulWidget {
  @override
  _WalkThroughScreenState createState() => _WalkThroughScreenState();
}

class _WalkThroughScreenState extends State<WalkThroughScreen>
    with SingleTickerProviderStateMixin {
  int currentPosition = 0;
  PageController pageController = PageController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Per-page accent colors
  final List<Color> _pageAccents = [
    Color(0xFF2A66C9),
    Color(0xFF5E35B1),
    Color(0xFF00897B),
    Color(0xFFE65100),
  ];

  Color get _accent =>
      _pageAccents[currentPosition.clamp(0, _pageAccents.length - 1)];

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: 0);
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  List<WalkThroughModelClass> get pages {
    return [
      WalkThroughModelClass(
        title: language.walk_title1,
        image: walk_Img1,
        subTitle: language.walk_subtitle1,
      ),
      WalkThroughModelClass(
        title: language.walk_title2,
        image: walk_Img2,
        subTitle: language.walk_subtitle2,
      ),
      WalkThroughModelClass(
        title: language.walk_title3,
        image: appStore.selectedLanguageCode == 'en' ? walk_Img_en3 : walk_Img3,
        subTitle: language.walk_subtitle3,
      ),
      WalkThroughModelClass(
        title: language.walk_title4,
        image: appStore.selectedLanguageCode == 'en' ? walk_Img_en4 : walk_Img4,
        subTitle: language.walk_subtitle4,
      ),
    ];
  }

  @override
  void dispose() {
    _animController.dispose();
    pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => currentPosition = index);
    _animController
      ..reset()
      ..forward();
  }

  Future<void> _handleNext() async {
    if (currentPosition == pages.length - 1) {
      await setValue(IS_FIRST_TIME, false);
      DashboardScreen().launch(context,
          isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
    } else {
      pageController.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleSkip() async {
    await setValue(IS_FIRST_TIME, false);
    DashboardScreen().launch(context,
        isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
  }

  Future<void> _showLanguageMenu() async {
    final selected = await showMenu<LanguageDataModel>(
      context: context,
      position: RelativeRect.fromLTRB(20, 110, 0, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      items: localeLanguageList.map((lang) {
        return PopupMenuItem<LanguageDataModel>(
          value: lang,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lang.flag != null)
                ClipOval(
                  child: Image.asset(
                    lang.flag!,
                    width: 26,
                    height: 26,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        SizedBox(width: 26, height: 26),
                  ),
                ),
              10.width,
              Flexible(
                child: Text(lang.name.validate(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        );
      }).toList(),
    );
    if (selected != null) {
      appStore.setLanguage(selected.languageCode!);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldColor,
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _accent.withOpacity(0.10),
                  _accent.withOpacity(0.04),
                  scaffoldColor,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Decorative blobs
          _blob(top: -90, right: -70, size: 240, opacity: 0.09),
          _blob(top: 50, right: -10, size: 110, opacity: 0.06),
          _blob(bottom: 180, left: -60, size: 170, opacity: 0.06),

          // Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: PageView.builder(
                    itemCount: pages.length,
                    controller: pageController,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (_, index) => _buildPage(pages[index], index),
                  ),
                ),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob({
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
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _accent.withOpacity(opacity),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Language selector pill
          GestureDetector(
            onTap: _showLanguageMenu,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 400),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _accent.withOpacity(0.25), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language_rounded, size: 15, color: _accent),
                  5.width,
                  Text(
                    appStore.selectedLanguageCode.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                      letterSpacing: 0.8,
                    ),
                  ),
                  4.width,
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 15, color: _accent),
                ],
              ),
            ),
          ),
          Spacer(),
          // App brand
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Image.asset(appLogo, height: 22),
                8.width,
                Text(
                  APP_NAME,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: appTextPrimaryColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(WalkThroughModelClass page, int index) {
    final color = _pageAccents[index.clamp(0, _pageAccents.length - 1)];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image inside layered circles
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: context.width() * 0.72,
                height: context.width() * 0.72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.07),
                ),
              ),
              Container(
                width: context.width() * 0.58,
                height: context.width() * 0.58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.09),
                ),
              ),
              // Small floating accent dots
              Positioned(
                top: 18,
                left: context.width() * 0.08,
                child: _accentDot(color, 10, 0.4),
              ),
              Positioned(
                bottom: 24,
                right: context.width() * 0.06,
                child: _accentDot(color, 7, 0.3),
              ),
              Positioned(
                top: context.width() * 0.22,
                right: context.width() * 0.03,
                child: _accentDot(color, 5, 0.25),
              ),
              SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Image.asset(
                    page.image.validate(),
                    height: context.height() * 0.30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          36.height,

          // Step chip
          FadeTransition(
            opacity: _fadeAnim,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${index + 1} / ${pages.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          14.height,

          // Title
          SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                page.title.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: appStore.selectedLanguageCode == 'ar' ? 22 : 24,
                  fontWeight: FontWeight.w800,
                  color: appTextPrimaryColor,
                  height: 1.3,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
          14.height,

          // Subtitle
          FadeTransition(
            opacity: _fadeAnim,
            child: Text(
              page.subTitle.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: appTextSecondaryColor,
                height: 1.65,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accentDot(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }

  Widget _buildBottomControls() {
    final isLast = currentPosition == pages.length - 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        children: [
          // Dot indicator
          CustomDotIndicator(
            borderRadius: BorderRadiusDirectional.circular(20),
            pageController: pageController,
            pages: pages,
            indicatorColor: _accent,
            unselectedIndicatorColor: _accent.withOpacity(0.18),
            dotSize: 8,
            currentDotWidth: 30,
          ),
          22.height,

          // Primary CTA button
          AnimatedContainer(
            duration: Duration(milliseconds: 400),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _accent.withOpacity(0.80)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.38),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _handleNext,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? language.getStarted : language.btnNext,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      if (!isLast) ...[
                        10.width,
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ] else ...[
                        10.width,
                        Icon(Icons.rocket_launch_rounded,
                            color: Colors.white, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          12.height,

          // Skip
          AnimatedOpacity(
            opacity: isLast ? 0.0 : 1.0,
            duration: Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: isLast ? null : _handleSkip,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                child: Text(
                  language.lblSkip,
                  style: TextStyle(
                    color: appTextSecondaryColor.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
