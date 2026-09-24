import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/auth/sign_in_screen.dart';
import 'package:booking_system_flutter/screens/category/category_screen.dart';
import 'package:booking_system_flutter/screens/chat/chat_list_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/booking_fragment.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/dashboard_fragment.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/profile_fragment.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/voice_search_component.dart';
import '../../utils/app_configuration.dart';
import '../../utils/firebase_messaging_utils.dart';
import '../newDashboard/dashboard_1/dashboard_fragment_1.dart';
import '../newDashboard/dashboard_2/dashboard_fragment_2.dart';
import '../newDashboard/dashboard_3/dashboard_fragment_3.dart';
import '../newDashboard/dashboard_4/dashboard_fragment_4.dart';

class DashboardScreen extends StatefulWidget {
  final bool? redirectToBooking;

  DashboardScreen({this.redirectToBooking});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // int currentIndex = 0;
  bool isInterNetConnect = true;

  @override
  void initState() {
    super.initState();
    if (widget.redirectToBooking.validate(value: false)) {
      appStore.setCurrentIndex(1);
    }

    afterBuildCreated(() async {
      /// Changes System theme when changed
      if (getIntAsync(THEME_MODE_INDEX) == THEME_MODE_SYSTEM) {
        appStore.setDarkMode(context.platformBrightness() == Brightness.dark);
      }

      View.of(context).platformDispatcher.onPlatformBrightnessChanged =
          () async {
        if (getIntAsync(THEME_MODE_INDEX) == THEME_MODE_SYSTEM) {
          appStore.setDarkMode(
              MediaQuery.of(context).platformBrightness == Brightness.light);
        }
      };
    });

    /// Handle Firebase Notification click and redirect to that Service & BookDetail screen
    LiveStream().on(LIVESTREAM_FIREBASE, (value) {
      if (value == 3) {
        appStore.setCurrentIndex(3);
      }
    });

    Firebase.initializeApp().then((value) {
      //When the app is in the background and opened directly from the push notification.
      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        //Handle onClick Notification
        log("data 1 ==> ${message.data}");
        handleNotificationClick(message);
      });

      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
        //Handle onClick Notification
        if (message != null) {
          log("data 2 ==> ${message.data}");
          handleNotificationClick(message);
        }
      });
    }).catchError(onError);

    init();
    // showInAppUpdateFlow(context: context);
  }

  void init() async {
    if (isMobile && appStore.isLoggedIn) {
      /// Handle Notification click and redirect to that Service & BookDetail screen
      ///
      /// TODO check if handled with firebase
      /*OneSignal.Notifications.addClickListener((notification) async {
        if (notification.notification.additionalData == null) return;

        if (notification.notification.additionalData!.containsKey('id')) {
          String? notId = notification.notification.additionalData!["id"].toString();
          if (notId.validate().isNotEmpty) {
            BookingDetailScreen(bookingId: notId.toString().toInt()).launch(context);
          }
        } else if (notification.notification.additionalData!.containsKey('service_id')) {
          String? notId = notification.notification.additionalData!["service_id"];
          if (notId.validate().isNotEmpty) {
            ServiceDetailScreen(serviceId: notId.toInt()).launch(context);
          }
        } else if (notification.notification.additionalData!.containsKey('sender_uid')) {
          String? notId = notification.notification.additionalData!["sender_uid"];
          if (notId.validate().isNotEmpty) {
            currentIndex = 3;
            setState(() {});
          }
        }
      });*/
    }

    await 3.seconds.delay;
    if (getIntAsync(FORCE_UPDATE_USER_APP).getBoolInt()) {
      showForceUpdateDialog(context);
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
    LiveStream().dispose(LIVESTREAM_FIREBASE);
  }

  static const double _navTileHPadding = 6;
  static const double _navMaxLabelSize = 12;
  static const double _navMinLabelSize = 9;

  double _navLabelSize = _navMaxLabelSize;
  double _navTileMinWidth = 56;

  TextStyle _navLabelStyle({required bool selected, double? size}) {
    return TextStyle(
      fontFamily: boldTextStyle().fontFamily,
      fontSize: size ?? _navLabelSize,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      color: selected ? Colors.white : appTextSecondaryColor,
      height: 1.2,
    );
  }

  /// Picks one label size for every tab so the widest label (measured in
  /// bold, its widest state) fits inside a single tab slot. Measures with
  /// the inherited theme style merged in, exactly as the Text renders it.
  void _computeNavLabelSize(
      BuildContext context, double slotWidth, List<String> labels) {
    final double available = slotWidth - (_navTileHPadding * 2) - 4;
    final TextStyle base = DefaultTextStyle.of(context).style;
    double widest = 0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(
            text: label,
            style: base.merge(
                _navLabelStyle(selected: true, size: _navMaxLabelSize))),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: TextScaler.noScaling,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    _navLabelSize = widest <= available || widest == 0
        ? _navMaxLabelSize
        : (_navMaxLabelSize * available / widest)
            .clamp(_navMinLabelSize, _navMaxLabelSize);
    _navTileMinWidth = slotWidth < 56 ? slotWidth : 56;
  }

  Widget _buildNavShell({
    required BuildContext context,
    required bool selected,
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    // Every tab gets an equal slot and the same label size (computed in
    // build() so the longest label fits the screen), so labels line up and
    // are never cut off; the active tab shows a compact tile around them.
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          heightFactor: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(minWidth: _navTileMinWidth),
            padding: const EdgeInsets.symmetric(
                horizontal: _navTileHPadding, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(context.primaryColor, Colors.white, 0.12)!,
                        context.primaryColor,
                      ],
                    )
                  : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: context.primaryColor.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 22, height: 22, child: Center(child: icon)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    textScaler: TextScaler.noScaling,
                    style: _navLabelStyle(selected: selected),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, int index, String iconPath, String label) {
    final bool selected = appStore.currentIndex == index;
    return _buildNavShell(
      context: context,
      selected: selected,
      label: label,
      onTap: () => appStore.setCurrentIndex(index),
      icon: SizedBox(
        width: 20,
        height: 20,
        child: iconPath.iconImage(
          color: selected ? Colors.white : appTextSecondaryColor,
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(BuildContext context) {
    final bool selected = appStore.currentIndex == 4;
    final hasImage =
        appStore.isLoggedIn && appStore.userProfileImage.isNotEmpty;
    return _buildNavShell(
      context: context,
      selected: selected,
      label: language.profile,
      onTap: () => appStore.setCurrentIndex(4),
      icon: hasImage
          ? IgnorePointer(
              ignoring: true,
              child: ImageBorder(src: appStore.userProfileImage, height: 22),
            )
          : SizedBox(
              width: 20,
              height: 20,
              child: ic_profile2.iconImage(
                color: selected ? Colors.white : appTextSecondaryColor,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DoublePressBackWidget(
      message: language.lblBackPressMsg,
      child: Observer(builder: (context) {
        return Scaffold(
          body: AnimatedOpacity(
            opacity: 1,
            duration: Duration(milliseconds: 500),
            child: [
              Observer(builder: (context) {
                if (appConfigurationStore.userDashboardType == DASHBOARD_1) {
                  return DashboardFragment1();
                } else if (appConfigurationStore.userDashboardType ==
                    DASHBOARD_2) {
                  return DashboardFragment2();
                } else if (appConfigurationStore.userDashboardType ==
                    DASHBOARD_3) {
                  return DashboardFragment3();
                } else if (appConfigurationStore.userDashboardType ==
                    DASHBOARD_4) {
                  return DashboardFragment4();
                } else {
                  return DashboardFragment();
                }
              }),
              Observer(
                  builder: (context) => appStore.isLoggedIn
                      ? BookingFragment()
                      : SignInScreen(isFromDashboard: true)),
              CategoryScreen(),
              Observer(
                  builder: (context) => appStore.isLoggedIn
                      ? ChatListScreen()
                      : SignInScreen(isFromDashboard: true)),
              ProfileFragment(),
            ][appStore.currentIndex],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 10, right: 10, bottom: 12, top: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: appStore.isDarkMode
                      ? scaffoldSecondaryDark
                      : Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: LayoutBuilder(builder: (context, constraints) {
                  _computeNavLabelSize(context, constraints.maxWidth / 5, [
                    language.home,
                    language.booking,
                    language.category,
                    language.lblChat,
                    language.profile,
                  ]);
                  // LayoutBuilder builds outside the parent Observer, so the
                  // row needs its own to react to tab changes.
                  return Observer(
                    builder: (context) => Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildNavItem(context, 0, ic_home, language.home),
                        _buildNavItem(
                            context, 1, ic_ticket, language.booking),
                        _buildNavItem(
                            context, 2, ic_category, language.category),
                        _buildNavItem(context, 3, ic_chat, language.lblChat),
                        _buildProfileNavItem(context),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          bottomSheet: Observer(builder: (context) {
            return VoiceSearchComponent().visible(appStore.isSpeechActivated);
          }),
        );
      }),
    );
  }
}
