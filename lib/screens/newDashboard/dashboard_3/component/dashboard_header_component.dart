import 'dart:async';

import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/screens/notification/notification_screen.dart';
import 'package:booking_system_flutter/screens/wallet/user_wallet_balance_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

class DashboardHeaderComponent extends StatefulWidget {
  final List<ServiceData>? featuredList;
  final VoidCallback? callback;

  DashboardHeaderComponent({this.callback, this.featuredList});

  @override
  State<DashboardHeaderComponent> createState() =>
      _DashboardHeaderComponentState();
}

class _DashboardHeaderComponentState extends State<DashboardHeaderComponent> {
  Timer? _timer;
  int cartItemCount = 3;

  @override
  void initState() {
    super.initState();
  }

  void updateCartCount(int count) {
    setState(() {
      cartItemCount = count;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  Decoration get commonDecoration {
    return boxDecorationDefault(
      color: context.cardColor,
      boxShadow: [
        BoxShadow(color: shadowColorGlobal, offset: Offset(1, 0)),
        BoxShadow(color: shadowColorGlobal, offset: Offset(0, 1)),
        BoxShadow(color: shadowColorGlobal, offset: Offset(-1, 0)),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Observer(
      builder: (context) {
        return GestureDetector(
          onTap: () async {
            locationWiseService(context, () {
              widget.callback?.call();
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
            decoration: BoxDecoration(
              // color: context.cardColor,
              borderRadius: BorderRadius.circular(14),
              // border: Border.all(
              //   color: primaryColor.withValues(alpha: 0.2),
              //   width: 1,
              // ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_pin,
                  color: primaryColor,
                  size: 20,
                ),
                10.width,
                Expanded(
                  child: Text(
                    appStore.isCurrentLocation
                        ? getStringAsync(CURRENT_ADDRESS)
                        : language.lblLocationOff,
                    style: secondaryTextStyle(
                      size: 14,
                      weight: FontWeight.w500,
                      color: appStore.isCurrentLocation
                          ? textPrimaryColorGlobal
                          : textSecondaryColorGlobal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                8.width,
                Icon(
                  Icons.keyboard_arrow_down,
                  color: primaryColor,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWalletSection() {
    return GestureDetector(
      onTap: () {
        if (appConfigurationStore.onlinePaymentStatus) {
          UserWalletBalanceScreen().launch(context);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: primaryColor,
              size: 18,
            ),
            4.width,
            Text(
              appStore.userWalletAmount.toPriceFormat(),
              style: boldTextStyle(
                size: 12,
                color: primaryColor,
                fontFamily: saudiRiyalsFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

/*
  Widget _buildCartSection() {
    return GestureDetector(
      onTap: () {
        // Navigate to cart screen
        toast("Cart tapped");
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              color: primaryColor,
              size: 24,
            ),
          ),
          // Notification badge
          if (cartItemCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    cartItemCount > 99 ? "99+" : cartItemCount.toString(),
                    style: primaryTextStyle(
                      size: 10,
                      color: Colors.white,
                      weight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
*/
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          // Location Section (Expandable)
          Expanded(
            flex: 3,
            child: _buildLocationSection(),
          ),
          16.width,
          // Wallet Section (Fixed width)
          _buildWalletSection(),
          10.width,
          // Notification Section (Fixed width)
          Container(
            decoration: boxDecorationDefault(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: []),
            height: 36,
            padding: EdgeInsets.all(8),
            width: 36,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ic_notification
                    .iconImage(size: 24, color: primaryColor)
                    .center(),
                Observer(builder: (context) {
                  return Positioned(
                    top: -20,
                    right: -10,
                    child: appStore.unreadCount.validate() > 0
                        ? Container(
                            padding: EdgeInsets.all(4),
                            child: FittedBox(
                              child: Text(appStore.unreadCount.toString(),
                                  style: primaryTextStyle(
                                      size: 12, color: Colors.white)),
                            ),
                            decoration: boxDecorationDefault(
                                color: Colors.red, shape: BoxShape.circle),
                          )
                        : Offstage(),
                  );
                })
              ],
            ),
          ).onTap(() {
            NotificationScreen().launch(context);
          }),
        ],
      ),
    );
  }
}
