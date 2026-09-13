import 'dart:ui';

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

  Widget _buildNavItem(
      BuildContext context, int index, String iconPath, String label) {
    final bool selected = appStore.currentIndex == index;
    return GestureDetector(
      onTap: () => appStore.setCurrentIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        padding: selected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
            : const EdgeInsets.all(10),
        decoration: selected
            ? BoxDecoration(
                color: context.primaryColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: context.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : const BoxDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: iconPath.iconImage(
                color: selected ? Colors.white : appTextSecondaryColor,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 7),
              Text(label, style: boldTextStyle(color: Colors.white, size: 13)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(BuildContext context) {
    final bool selected = appStore.currentIndex == 4;
    return Observer(builder: (context) {
      final hasImage =
          appStore.isLoggedIn && appStore.userProfileImage.isNotEmpty;
      return GestureDetector(
        onTap: () => appStore.setCurrentIndex(4),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          padding: selected
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
              : const EdgeInsets.all(10),
          decoration: selected
              ? BoxDecoration(
                  color: context.primaryColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                )
              : const BoxDecoration(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              hasImage
                  ? IgnorePointer(
                      ignoring: true,
                      child: ImageBorder(
                          src: appStore.userProfileImage, height: 20),
                    )
                  : SizedBox(
                      width: 20,
                      height: 20,
                      child: ic_profile2.iconImage(
                        color: selected ? Colors.white : appTextSecondaryColor,
                      ),
                    ),
              if (selected) ...[
                const SizedBox(width: 7),
                Text(language.profile,
                    style: boldTextStyle(color: Colors.white, size: 13)),
              ],
            ],
          ),
        ),
      );
    });
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
                  left: 20, right: 20, bottom: 14, top: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: appStore.isDarkMode
                          ? scaffoldSecondaryDark.withValues(alpha: 0.80)
                          : Colors.white.withValues(alpha: 0.80),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: appStore.isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.60),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 30,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(context, 0, ic_home, language.home),
                        _buildNavItem(context, 1, ic_ticket, language.booking),
                        _buildNavItem(
                            context, 2, ic_category, language.category),
                        _buildNavItem(context, 3, ic_chat, language.lblChat),
                        _buildProfileNavItem(context),
                      ],
                    ),
                  ),
                ),
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
