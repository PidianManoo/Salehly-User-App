import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/dashboard_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/dashboard/component/category_component.dart';
import 'package:booking_system_flutter/screens/dashboard/component/featured_service_list_component.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/booking_fragment.dart';
import 'package:booking_system_flutter/screens/dashboard/shimmer/dashboard_shimmer.dart';
import 'package:booking_system_flutter/screens/jobRequest/my_post_request_list_screen.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_3/component/slider_dashboard_component_3.dart';
import 'package:booking_system_flutter/screens/notification/notification_screen.dart';
import 'package:booking_system_flutter/screens/service/search_service_screen.dart';
import 'package:booking_system_flutter/screens/category/category_screen.dart';
import 'package:booking_system_flutter/screens/wallet/user_wallet_balance_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';
import '../../../component/loader_widget.dart';
import '../component/booking_confirmed_component.dart';
import '../component/promotional_banner_slider_component.dart';

class DashboardFragment extends StatefulWidget {
  @override
  _DashboardFragmentState createState() => _DashboardFragmentState();
}

class _DashboardFragmentState extends State<DashboardFragment>
    with TickerProviderStateMixin {
  Future<DashboardResponse>? future;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  late final AnimationController _floatCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  late final Animation<double> _pulse =
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  late final Animation<double> _float =
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    init();
    setStatusBarColorChange();
    LiveStream().on(LIVESTREAM_UPDATE_DASHBOARD, (p0) {
      init();
      appStore.setLoading(true);
      setState(() {});
    });
  }

  void init() async {
    appStore.setUserWalletAmount();
    future = userDashboard(
      isCurrentLocation: appStore.isCurrentLocation,
      lat: getDoubleAsync(LATITUDE),
      long: getDoubleAsync(LONGITUDE),
    );
    setStatusBarColorChange();
    setState(() {});
  }

  Future<void> setStatusBarColorChange() async {
    setStatusBarColor(
      transparentColor,
      delayInMilliSeconds: 800,
      statusBarIconBrightness: Brightness.light,
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    LiveStream().dispose(LIVESTREAM_UPDATE_DASHBOARD);
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return language.goodMorning;
    if (h < 17) return language.goodAfternoon;
    return language.goodEvening;
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStore.isDarkMode ? scaffoldColorDark : scaffoldColor,
      body: Stack(
        children: [
          SnapHelperWidget<DashboardResponse>(
            initialData: cachedDashboardResponse,
            future: future,
            errorBuilder: (error) => NoDataWidget(
              title: error,
              imageWidget: ErrorStateWidget(),
              retryText: language.reload,
              onRetry: () {
                appStore.setLoading(true);
                init();
                setState(() {});
              },
            ),
            loadingWidget: DashboardShimmer(),
            onSuccess: (snap) {
              return Observer(builder: (context) {
                return RefreshIndicator(
                  color: primaryColor,
                  strokeWidth: 2.5,
                  onRefresh: () async {
                    appStore.setLoading(true);
                    setValue(LAST_APP_CONFIGURATION_SYNCED_TIME, 0);
                    init();
                    setState(() {});
                    return await 2.seconds.delay;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroHeader(snap),
                        _buildFloatingSearchBar(snap),
                        _buildActionButtons(),
                        if (snap.slider.validate().isNotEmpty)
                          _buildSliderSection(snap),
                        PendingBookingComponent(
                            upcomingConfirmedBooking: snap.upcomingData),
                        if (snap.featuredCategory.validate().isNotEmpty) ...[
                          _sectionLabel(
                            language.topServices,
                            actionLabel: language.moreServices,
                            onAction: () => CategoryScreen().launch(context),
                          ),
                          16.height,
                          CategoryComponent(
                              categoryList: snap.featuredCategory.validate()),
                        ],
                        if (snap.promotionalBanner.validate().isNotEmpty &&
                            appConfigurationStore.isPromotionalBanner) ...[
                          _sectionLabel('Special Offers'),
                          PromotionalBannerSliderComponent(
                            promotionalBannerList:
                                snap.promotionalBanner.validate(),
                          ).paddingBottom(8),
                        ],
                        FeaturedServiceListComponent(
                          serviceList: snap.featuredServices.validate(),
                        ).paddingTop(16),
                        80.height,
                      ],
                    ),
                  ),
                );
              });
            },
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HERO HEADER
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(DashboardResponse snap) {
    final isDark = appStore.isDarkMode;
    return ClipPath(
      clipper: _WaveBottomClipper(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1D2E),
                    const Color(0xFF0E1116),
                  ]
                : [
                    const Color(0xFF150028),
                    const Color(0xFF3D0066),
                    primaryColor,
                    primaryColor.withValues(alpha: 0.80),
                  ],
            stops: isDark ? const [0.0, 1.0] : const [0.0, 0.28, 0.65, 1.0],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Glow orbs ──────────────────────────────────────────────────
            Positioned(
              top: -70,
              right: -50,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => _glowOrb(
                  240,
                  Colors.white.withValues(alpha: 0.08 + _pulse.value * 0.05),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => _glowOrb(
                  90,
                  Colors.white
                      .withValues(alpha: 0.06 + (1 - _pulse.value) * 0.04),
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              left: -55,
              child: AnimatedBuilder(
                animation: _float,
                builder: (_, __) => _glowOrb(
                  170,
                  Colors.purple.withValues(alpha: 0.18 + _float.value * 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              right: 80,
              child: AnimatedBuilder(
                animation: _float,
                builder: (_, __) => _glowOrb(
                  60,
                  Colors.white.withValues(alpha: 0.05 + _float.value * 0.04),
                ),
              ),
            ),
            // ── Decorative rings ───────────────────────────────────────────
            Positioned(
              top: 30,
              left: 120,
              child: _ring(70, Colors.white.withValues(alpha: 0.10)),
            ),
            Positioned(
              top: 80,
              left: 160,
              child: _ring(36, Colors.white.withValues(alpha: 0.07)),
            ),
            // ── Sparkle dots ───────────────────────────────────────────────
            Positioned(top: 52, left: 55, child: _sparkle(_pulse)),
            Positioned(top: 108, right: 140, child: _sparkle(_floatCtrl.view)),
            Positioned(top: 70, right: 68, child: _dotGlow(5)),
            Positioned(top: 148, left: 80, child: _dotGlow(4)),
            // ── Content ────────────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(snap),
                  _buildGreeting(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(DashboardResponse snap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // ── Location ──────────────────────────────────────────────────────
          Expanded(
            child: Observer(builder: (_) {
              return GestureDetector(
                onTap: () => locationWiseService(context, () {
                  appStore.setLoading(true);
                  init();
                  setState(() {});
                }),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20)),
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: Colors.white, size: 14),
                    ),
                    8.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language.yourLocation,
                            style: primaryTextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              size: 9,
                            ),
                          ),
                          Text(
                            appStore.isCurrentLocation
                                ? (getStringAsync(CURRENT_ADDRESS).isNotEmpty
                                    ? getStringAsync(CURRENT_ADDRESS)
                                    : language.lblLocationOff)
                                : language.lblLocationOff,
                            style: boldTextStyle(color: Colors.white, size: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70, size: 16),
                  ],
                ),
              );
            }),
          ),
          10.width,
          // ── Wallet pill ───────────────────────────────────────────────────
          if (appConfigurationStore.onlinePaymentStatus)
            GestureDetector(
              onTap: () => UserWalletBalanceScreen().launch(context),
              child: Observer(builder: (_) {
                return _glassPill(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 14),
                      5.width,
                      Text(
                        appStore.userWalletAmount.toPriceFormat(),
                        style: boldTextStyle(
                          size: 11,
                          color: Colors.white,
                          fontFamily: saudiRiyalsFontFamily,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          8.width,
          // ── Notification bell ─────────────────────────────────────────────
          GestureDetector(
            onTap: () => NotificationScreen().launch(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      color: Colors.white, size: 18),
                  Observer(builder: (_) {
                    if (appStore.unreadCount.validate() <= 0) {
                      return const SizedBox.shrink();
                    }
                    return Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Colors.orangeAccent, Colors.redAccent]),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.5),
                                blurRadius: 6)
                          ],
                        ),
                        child: FittedBox(
                          child: Text(
                            appStore.unreadCount.toString(),
                            style:
                                primaryTextStyle(size: 9, color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 52),
      child: Observer(builder: (_) {
        final first = appStore.userFullName.trim().isNotEmpty
            ? appStore.userFullName.trim().split(' ').first
            : 'Guest';
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Online status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7FFFB4),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7FFFB4)
                                    .withValues(alpha: 0.9),
                                blurRadius: 8,
                              )
                            ],
                          ),
                        ),
                        6.width,
                        Text(
                          _greeting(),
                          style: primaryTextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            size: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  12.height,
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: first,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.6,
                            height: 1.0,
                          ),
                        ),
                        const TextSpan(
                          text: ' 👋',
                          style: TextStyle(fontSize: 22),
                        ),
                      ],
                    ),
                  ),
                  7.height,
                  Text(
                    language.whatServiceDoYouNeedToday,
                    style: primaryTextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      size: 13,
                    ),
                  ),
                ],
              ),
            ),
            // User avatar circle
            AnimatedBuilder(
              animation: _float,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -4 * _float.value),
                child: child,
              ),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.12),
                      blurRadius: 16,
                    )
                  ],
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FLOATING SEARCH BAR
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFloatingSearchBar(DashboardResponse snap) {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTap: () => SearchServiceScreen(
                  featuredList: snap.featuredServices.validate())
              .launch(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: appStore.isDarkMode ? scaffoldSecondaryDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.22),
                  blurRadius: 36,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.14),
                        primaryColor.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child:
                      Icon(Icons.search_rounded, color: primaryColor, size: 20),
                ),
                14.width,
                Expanded(
                  child: Text(
                    '${language.search} ${language.services}...',
                    style: primaryTextStyle(
                      color: appStore.isDarkMode
                          ? Colors.white54
                          : appTextSecondaryColor,
                      size: 14,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        Color.lerp(primaryColor, Colors.indigo.shade800, 0.35)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.38),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune_rounded,
                          color: Colors.white, size: 14),
                      4.width,
                      Text(language.lblFilterBy,
                          style: boldTextStyle(color: Colors.white, size: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ACTION BUTTONS ROW
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.calendar_month_rounded,
                label: language.booking,
                subtitle: language.bookingHistory,
                accentColor: const Color(0xFF6C63FF),
                gradientEnd: const Color(0xFF8F88FF),
                onTap: () => BookingFragment(showBack: true).launch(context),
              ),
            ),
            14.width,
            Expanded(
              child: _actionButton(
                icon: Icons.work_outline_rounded,
                label: language.postJob,
                subtitle: language.myPostJobList,
                accentColor: const Color(0xFFFF6B35),
                gradientEnd: const Color(0xFFFFB347),
                onTap: () => MyPostRequestListScreen().launch(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color accentColor,
    required Color gradientEnd,
    required VoidCallback onTap,
  }) {
    final isDark = appStore.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    accentColor.withValues(alpha: 0.20),
                    accentColor.withValues(alpha: 0.08),
                  ]
                : [
                    accentColor.withValues(alpha: 0.10),
                    accentColor.withValues(alpha: 0.03),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.30 : 0.18),
            width: 1,
          ),
          color: isDark ? scaffoldSecondaryDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.40),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: boldTextStyle(
                      size: 13,
                      color: isDark ? Colors.white : appTextPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  3.height,
                  Text(
                    subtitle,
                    style: primaryTextStyle(
                      size: 10,
                      color: appTextSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: accentColor.withValues(alpha: 0.60),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SLIDER SECTION
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSliderSection(DashboardResponse snap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SliderDashboardComponent3(sliderList: snap.slider.validate()),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SECTION LABEL
  // ──────────────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String title,
      {String? actionLabel, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      Color.lerp(primaryColor, Colors.purple, 0.45)!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
              10.width,
              Text(title, style: boldTextStyle(size: 17)),
            ],
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.12),
                      primaryColor.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: primaryColor.withValues(alpha: 0.28), width: 1),
                ),
                child: Text(
                  actionLabel,
                  style: primaryTextStyle(
                    color: primaryColor,
                    size: 12,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _glassPill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)
        ],
      ),
      child: child,
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _ring(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }

  Widget _dotGlow(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.40),
        boxShadow: [
          BoxShadow(color: Colors.white.withValues(alpha: 0.60), blurRadius: 8)
        ],
      ),
    );
  }

  Widget _sparkle(Animation<double> anim) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value * 0.55,
        child: const Icon(Icons.star_rounded, color: Colors.white, size: 8),
      ),
    );
  }
}

// ── Wave clipper ──────────────────────────────────────────────────────────────
class _WaveBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 28);
    path.quadraticBezierTo(
      size.width * 0.22,
      size.height + 4,
      size.width * 0.5,
      size.height - 20,
    );
    path.quadraticBezierTo(
      size.width * 0.78,
      size.height - 44,
      size.width,
      size.height - 14,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveBottomClipper old) => false;
}
