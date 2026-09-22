import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/about_screen.dart';
import 'package:booking_system_flutter/screens/auth/edit_profile_screen.dart';
import 'package:booking_system_flutter/screens/auth/sign_in_screen.dart';
import 'package:booking_system_flutter/screens/blog/view/blog_list_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/customer_rating_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/fragment/booking_fragment.dart';
import 'package:booking_system_flutter/screens/service/favourite_service_screen.dart';
import 'package:booking_system_flutter/screens/setting_screen.dart';
import 'package:booking_system_flutter/screens/wallet/user_wallet_balance_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/app_configuration.dart';
import '../../bankDetails/view/bank_details.dart';
import '../../favourite_provider_screen.dart';
import '../../helpDesk/help_desk_list_screen.dart';
import '../../refund/refund_request_list_screen.dart';
import '../component/wallet_history.dart';

class ProfileFragment extends StatefulWidget {
  @override
  ProfileFragmentState createState() => ProfileFragmentState();
}

class ProfileFragmentState extends State<ProfileFragment>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    init();
    afterBuildCreated(() {
      appStore.setLoading(false);
      setStatusBarColor(
        Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness:
            appStore.isDarkMode ? Brightness.light : Brightness.dark,
      );
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> init() async {
    if (appStore.isLoggedIn) {
      appStore.setUserWalletAmount();
      userDetailAPI();
    }
  }

  Future<void> userDetailAPI() async {
    await getUserDetail(appStore.userId, forceUpdate: false)
        .then((value) async {
      await saveUserData(value, forceSyncAppConfigurations: false);
      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void _showSupportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Text(language.lblSupport, style: boldTextStyle(size: 18)),
                const Spacer(),
                IconButton(
                  onPressed: () => finish(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ContactTile(
              icon: Icons.call_outlined,
              title: language.lblPhone,
              subtitle: appConfigurationStore.helplineNumber.validate(),
              onTap: () {
                finish(context);
                launchCall(appConfigurationStore.helplineNumber.validate());
              },
            ),
            const SizedBox(height: 8),
            _ContactTile(
              icon: Icons.email_outlined,
              title: language.lblContactUsViaEmail,
              subtitle: defaultSupportEmail,
              onTap: () {
                finish(context);
                launchMail(defaultSupportEmail);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Observer(
        builder: (context) {
          return Stack(
            children: [
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: RefreshIndicator(
                    color: context.primaryColor,
                    onRefresh: () async {
                      await removeKey(LAST_USER_DETAILS_SYNCED_TIME);
                      init();
                      setState(() {});
                      return Future.delayed(1.seconds);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 56),

                          // Avatar + Info
                          if (appStore.isLoggedIn) ...[
                            _buildAvatarSection(),
                            const SizedBox(height: 16),
                            _buildQuickActions(),
                            const SizedBox(height: 8),
                          ],

                          // Wallet Card
                          if (appStore.isLoggedIn &&
                              appConfigurationStore.isEnableUserWallet)
                            _buildWalletCard(),

                          // General
                          // _buildSectionLabel('General'),
                          const SizedBox(height: 10),

                          _buildMenuGroup([
                            if (appStore.isLoggedIn &&
                                appConfigurationStore.isEnableUserWallet)
                              _MenuTile(
                                assetIcon: iconsWalletHistory,
                                label: language.walletHistory,
                                onTap: () =>
                                    UserWalletHistoryScreen().launch(context),
                              ),
                            if (appStore.isLoggedIn &&
                                rolesAndPermissionStore.bankList)
                              _MenuTile(
                                assetIcon: iconsBank,
                                label: language.lblBankDetails,
                                onTap: () => BankDetails().launch(context),
                              ),
                            _MenuTile(
                              assetIcon: iconsFavServices,
                              label: language.lblFavorite,
                              onTap: () => doIfLoggedIn(
                                  context,
                                  () =>
                                      FavouriteServiceScreen().launch(context)),
                            ),
                            _MenuTile(
                              assetIcon: iconsFavoriteProvider,
                              label: language.favouriteProvider,
                              onTap: () => doIfLoggedIn(
                                  context,
                                  () => FavouriteProviderScreen()
                                      .launch(context)),
                            ),
                            if (appConfigurationStore.blogStatus &&
                                rolesAndPermissionStore.blogList)
                              _MenuTile(
                                assetIcon: document,
                                label: language.blogs,
                                onTap: () => BlogListScreen().launch(context),
                              ),
                            _MenuTile(
                              assetIcon: iconsRateUs,
                              label: language.rateUs,
                              onTap: () async {
                                if (isAndroid) {
                                  if (getStringAsync(CUSTOMER_PLAY_STORE_URL)
                                      .isNotEmpty) {
                                    commonLaunchUrl(
                                        getStringAsync(CUSTOMER_PLAY_STORE_URL),
                                        launchMode:
                                            LaunchMode.externalApplication);
                                  } else {
                                    commonLaunchUrl(
                                        '${getSocialMediaLink(LinkProvider.PLAY_STORE)}${await getPackageName()}',
                                        launchMode:
                                            LaunchMode.externalApplication);
                                  }
                                } else if (isIOS) {
                                  if (getStringAsync(CUSTOMER_APP_STORE_URL)
                                      .isNotEmpty) {
                                    commonLaunchUrl(
                                        getStringAsync(CUSTOMER_APP_STORE_URL),
                                        launchMode:
                                            LaunchMode.externalApplication);
                                  } else {
                                    commonLaunchUrl(IOS_LINK_FOR_USER,
                                        launchMode:
                                            LaunchMode.externalApplication);
                                  }
                                }
                              },
                            ),
                            _MenuTile(
                              assetIcon: iconsMyReview,
                              label: language.myReviews,
                              onTap: () => doIfLoggedIn(context,
                                  () => CustomerRatingScreen().launch(context)),
                            ),
                            if (appStore.isLoggedIn &&
                                rolesAndPermissionStore.helpDeskList)
                              _MenuTile(
                                assetIcon: iconsHelpdesk,
                                label: language.helpDesk,
                                onTap: () =>
                                    HelpDeskListScreen().launch(context),
                              ),
                            if (appStore.isLoggedIn)
                              _MenuTile(
                                iconData: Icons.assignment_return_outlined,
                                label: language.myRefundRequests,
                                onTap: () =>
                                    RefundRequestListScreen().launch(context),
                              ),
                          ]),

                          // About
                          _buildMenuGroup([
                            if (rolesAndPermissionStore.aboutUs)
                              _MenuTile(
                                assetIcon: ic_about_us,
                                label: language.lblAboutApp,
                                onTap: () => AboutScreen().launch(context),
                              ),
                            if (rolesAndPermissionStore.privacyPolicy)
                              _MenuTile(
                                assetIcon: ic_shield_done,
                                label: language.privacyPolicy,
                                onTap: () => checkIfLink(context,
                                    appConfigurationStore.privacyPolicy,
                                    title: language.privacyPolicy),
                              ),
                            if (rolesAndPermissionStore.termCondition)
                              _MenuTile(
                                assetIcon: ic_document,
                                label: language.termsCondition,
                                onTap: () => checkIfLink(context,
                                    appConfigurationStore.termConditions,
                                    title: language.termsCondition),
                              ),
                            if (rolesAndPermissionStore
                                .refundAndCancellationPolicy)
                              _MenuTile(
                                assetIcon: ic_refund,
                                label: language.refundPolicy,
                                onTap: () => checkIfLink(
                                    context, appConfigurationStore.refundPolicy,
                                    title: language.refundPolicy),
                              ),
                            if (appConfigurationStore
                                    .helpAndSupport.isNotEmpty &&
                                rolesAndPermissionStore.helpAndSupport)
                              _MenuTile(
                                assetIcon: iconsSupport,
                                label: language.helpSupport,
                                onTap: () {
                                  if (appConfigurationStore
                                      .helpAndSupport.isNotEmpty) {
                                    checkIfLink(context,
                                        appConfigurationStore.helpAndSupport,
                                        title: language.helpSupport);
                                  } else {
                                    checkIfLink(
                                        context,
                                        appConfigurationStore.inquiryEmail
                                            .validate(),
                                        title: language.helpSupport);
                                  }
                                },
                              ),
                            if (!appStore.isLoggedIn &&
                                appConfigurationStore.helplineNumber.isNotEmpty)
                              _MenuTile(
                                assetIcon: phoneCall,
                                label: language.lblHelplineNumber,
                                onTap: () => launchCall(appConfigurationStore
                                    .helplineNumber
                                    .validate()),
                              ),
                          ]),

                          // Account
                          // _buildMenuGroup([
                          //   _MenuTile(
                          //     assetIcon: setting,
                          //     label: language.lblAppSetting,
                          //     onTap: () => SettingScreen().launch(context),
                          //   ),
                          // ]),

                          // Logout
                          if (appStore.isLoggedIn) ...[
                            const SizedBox(height: 24),
                            _buildLogoutButton(),
                          ],

                          // Sign In (shown when not logged in)
                          if (!appStore.isLoggedIn) ...[
                            const SizedBox(height: 24),
                            _buildSignInButton(),
                          ],

                          const SizedBox(height: 16),

                          // Version
                          SnapHelperWidget<PackageInfoData>(
                            future: getPackageInfo(),
                            onSuccess: (data) => TextButton(
                              onPressed: () => showAboutDialog(
                                context: context,
                                applicationName: APP_NAME,
                                applicationVersion: data.versionName,
                                applicationIcon:
                                    Image.asset(appLogo, height: 50),
                              ),
                              child: VersionInfoWidget(
                                prefixText: 'v',
                                textStyle: secondaryTextStyle(),
                              ),
                            ),
                          ).center(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Observer(
                builder: (_) => LoaderWidget().visible(appStore.isLoading),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => EditProfileScreen().launch(context),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        context.primaryColor,
                        context.primaryColor.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CachedImageWidget(
                    url: appStore.userProfileImage,
                    height: 84,
                    width: 84,
                    circle: true,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: context.scaffoldBackgroundColor, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 11, color: white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(appStore.userFullName, style: boldTextStyle(size: 18)),
          const SizedBox(height: 4),
          Text(appStore.userEmail, style: secondaryTextStyle(size: 13)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _QuickCard(
            icon: iconsRequests,
            label: language.requests,
            onTap: () => BookingFragment(showBack: true).launch(context),
          ),
          const SizedBox(width: 10),
          if (appStore.isLoggedIn &&
              appConfigurationStore.helplineNumber.isNotEmpty) ...[
            _QuickCard(
              icon: iconsSupport,
              label: language.lblSupport,
              onTap: _showSupportSheet,
            ),
            const SizedBox(width: 10),
          ],
          _QuickCard(
            icon: setting,
            label: language.lblAppSetting,
            onTap: () => SettingScreen().launch(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return GestureDetector(
      onTap: () {
        if (appConfigurationStore.onlinePaymentStatus) {
          UserWalletBalanceScreen().launch(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.primaryColor,
              context.primaryColor.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.primaryColor.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -10,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: whiteColor.withOpacity(0.07),
                ),
              ),
            ),
            Row(
              children: [
                Image.asset(ic_wallet_cartoon,
                    height: 32, color: whiteColor.withOpacity(0.9)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(language.walletBalance,
                          style: secondaryTextStyle(
                              color: whiteColor.withOpacity(0.75), size: 12)),
                      const SizedBox(height: 4),
                      Observer(
                        builder: (_) => Text(
                          appStore.userWalletAmount.toPriceFormat(),
                          style: boldTextStyle(
                              color: whiteColor,
                              size: 22,
                              fontFamily: saudiRiyalsFontFamily),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: whiteColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: whiteColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: boldTextStyle(
                size: 11, color: context.primaryColor, letterSpacing: 1.2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.primaryColor.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGroup(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: children
            .map((child) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: child,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSignInButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => SignInScreen().launch(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.primaryColor,
                context.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(MaterialCommunityIcons.login, color: white, size: 20),
              const SizedBox(width: 8),
              Text(language.signIn,
                  style: boldTextStyle(color: white, size: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => logout(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(MaterialCommunityIcons.logout,
                  color: Colors.red.shade400, size: 20),
              const SizedBox(width: 8),
              Text(language.logout,
                  style: boldTextStyle(color: Colors.red.shade400, size: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Action Card ──────────────────────────────────────────────────────
class _QuickCard extends StatefulWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickCard> createState() => _QuickCardState();
}

class _QuickCardState extends State<_QuickCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _pressed
                ? context.primaryColor.withOpacity(0.1)
                : context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressed
                  ? context.primaryColor.withOpacity(0.4)
                  : context.primaryColor.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(widget.icon, height: 26, width: 26),
              const SizedBox(height: 6),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: secondaryTextStyle(size: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Menu Item Tile ─────────────────────────────────────────────────────────
class _MenuTile extends StatefulWidget {
  final String? assetIcon;
  final IconData? iconData;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    this.assetIcon,
    this.iconData,
    required this.label,
    required this.onTap,
  });

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _pressed
              ? context.primaryColor.withOpacity(0.07)
              : context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _pressed
                ? context.primaryColor.withOpacity(0.25)
                : context.primaryColor.withOpacity(0.07),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: widget.iconData != null
                    ? Icon(widget.iconData,
                        size: 18, color: context.primaryColor)
                    : Image.asset(widget.assetIcon!, width: 20, height: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(widget.label, style: boldTextStyle(size: 14)),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: grey.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Contact Tile (Support Sheet) ───────────────────────────────────────────
class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: grey.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: context.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: boldTextStyle(size: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: secondaryTextStyle(size: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios,
                  size: 12, color: context.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
