import 'dart:async';

import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/price_widget.dart';
import '../../withdraw/wallet_request.dart';
import '../user_wallet_balance_screen.dart';

class WalletCard extends StatefulWidget {
  final num availableBalance;
  final FutureOr<dynamic> Function(dynamic)? callback;
  const WalletCard({super.key, required this.availableBalance, this.callback});

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            Color.lerp(primaryColor, Colors.black, 0.25)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.38),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    language.availableBalance,
                    style: secondaryTextStyle(
                        size: 11,
                        color: Colors.white.withOpacity(0.85)),
                  ),
                ),
                12.height,
                FittedBox(
                  child: PriceWidget(
                    price: widget.availableBalance.validate(),
                    size: 32,
                    color: Colors.white,
                    isBoldText: true,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withOpacity(0.15),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: _WalletActionButton(
                    icon: Icons.arrow_upward_rounded,
                    label: language.withdraw,
                    onTap: () {
                      WithdrawRequest(
                        availableBalance: widget.availableBalance,
                      ).launch(context).then(widget.callback!);
                    },
                  ),
                ),
                12.width,
                Expanded(
                  child: _WalletActionButton(
                    icon: Icons.add_rounded,
                    label: language.topUp,
                    onTap: () {
                      UserWalletBalanceScreen(isBackScreen: true)
                          .launch(context)
                          .then(widget.callback!);
                    },
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

class _WalletActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _WalletActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            6.width,
            Text(
              label,
              style: boldTextStyle(size: 13, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
