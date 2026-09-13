import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/theme_selection_dialog.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/screens/language_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/firebase_messaging_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import 'auth/change_password_screen.dart';

class SettingScreen extends StatefulWidget {
  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    afterBuildCreated(() => _animCtrl.forward());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.lblAppSetting,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 28),

              // ── Security ──────────────────────────────────────────────
              if (isLoginTypeUser) ...[
                _SectionLabel(icon: Icons.shield_outlined, label: language.lblSecurity),
                _SettingsGroup(children: [
                  _NavTile(
                    icon: Icons.lock_outline_rounded,
                    iconBg: const Color(0xFF5B6CF0),
                    title: language.changePassword,
                    onTap: () => doIfLoggedIn(context, () {
                      ChangePasswordScreen().launch(context);
                    }),
                  ),
                ]),
                const SizedBox(height: 24),
              ],

              // ── Preferences ───────────────────────────────────────────
              _SectionLabel(icon: Icons.tune_rounded, label: language.lblPreferences),
              _SettingsGroup(children: [
                _NavTile(
                  icon: Icons.language_rounded,
                  iconBg: const Color(0xFF00BCA4),
                  title: language.language,
                  onTap: () => LanguagesScreen()
                      .launch(context)
                      .then((_) => setState(() {})),
                ),
                _GroupDivider(),
                _NavTile(
                  icon: Icons.palette_outlined,
                  iconBg: const Color(0xFFFF7043),
                  title: language.appTheme,
                  onTap: () async => await showInDialog(
                    context,
                    builder: (_) => ThemeSelectionDaiLog(),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                _GroupDivider(),
                _ToggleTile(
                  icon: Icons.slideshow_rounded,
                  iconBg: const Color(0xFF9C27B0),
                  title: language.lblAutoSliderStatus,
                  value: getBoolAsync(AUTO_SLIDER_STATUS, defaultValue: true),
                  onChanged: (v) {
                    setValue(AUTO_SLIDER_STATUS, v);
                    setState(() {});
                  },
                ),
                _GroupDivider(),
                _ToggleTile(
                  icon: Icons.system_update_alt_rounded,
                  iconBg: const Color(0xFF039BE5),
                  title: language.lblOptionalUpdateNotify,
                  value: getBoolAsync(UPDATE_NOTIFY, defaultValue: true),
                  onChanged: (v) {
                    setValue(UPDATE_NOTIFY, v);
                    setState(() {});
                  },
                ),
              ]),
              const SizedBox(height: 24),

              // ── Notifications ─────────────────────────────────────────
              if (appStore.isLoggedIn) ...[
                _SectionLabel(
                    icon: Icons.notifications_outlined, label: language.lblNotification),
                _SettingsGroup(children: [
                  Observer(builder: (context) {
                    return _ToggleTile(
                      icon: Icons.notifications_active_outlined,
                      iconBg: const Color(0xFFFFB300),
                      title: language.pushNotification,
                      value: FirebaseAuth.instance.currentUser != null &&
                          appStore.isSubscribedForPushNotification,
                      onChanged: (v) async {
                        if (appStore.isLoading) return;
                        appStore.setLoading(true);
                        if (v) {
                          await subscribeToFirebaseTopic();
                        } else {
                          await unsubscribeFirebaseTopic(appStore.userId);
                        }
                        appStore.setLoading(false);
                        setState(() {});
                      },
                    );
                  }),
                ]),
                const SizedBox(height: 24),
              ],

              // ── Display (Android 12+) ──────────────────────────────────
              SnapHelperWidget<bool>(
                future: isAndroid12Above(),
                onSuccess: (data) {
                  if (!data) return const Offstage();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                          icon: Icons.phone_android_rounded,
                          label: language.lblDisplaySection),
                      _SettingsGroup(children: [
                        _ToggleTile(
                          icon: Icons.auto_awesome_rounded,
                          iconBg: const Color(0xFF26A69A),
                          title: language.lblMaterialTheme,
                          value: appStore.useMaterialYouTheme,
                          onChanged: (v) => showConfirmDialogCustom(
                            context,
                            onAccept: (_) {
                              appStore.setUseMaterialYouTheme(v.validate());
                              RestartAppWidget.init(context);
                            },
                            title: language.lblAndroid12Support,
                            primaryColor: context.primaryColor,
                            positiveText: language.lblYes,
                            negativeText: language.lblCancel,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              // ── Danger Zone ───────────────────────────────────────────
              if (appStore.isLoggedIn) ...[
                const SizedBox(height: 4),
                _buildDangerZone(context),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 10),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 14, color: Colors.red.shade600),
                const SizedBox(width: 6),
                Text(
                  language.lblDangerZone.toUpperCase(),
                  style: boldTextStyle(
                    size: 10,
                    color: Colors.red.shade600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(
                  alpha: appStore.isDarkMode ? 0.09 : 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.red.withValues(
                      alpha: appStore.isDarkMode ? 0.35 : 0.25),
                  width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(
                        alpha: appStore.isDarkMode ? 0.14 : 0.08),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(
                      bottom: BorderSide(
                          color: Colors.red.withValues(
                              alpha: appStore.isDarkMode ? 0.22 : 0.15),
                          width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(
                              alpha: appStore.isDarkMode ? 0.20 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.warning_rounded,
                            color: Colors.red.shade600, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              language.lblIrreversibleActions,
                              style: boldTextStyle(
                                  color: Colors.red.shade700, size: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              language.lblActionsCannotBeUndone,
                              style: secondaryTextStyle(
                                  color: Colors.red.shade400, size: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _DangerTile(
                  icon: Icons.person_remove_outlined,
                  title: language.lblDeleteAccount,
                  subtitle: language.lblDeleteAccountSubtitle,
                  onTap: () => _confirmDeleteAccount(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showConfirmDialogCustom(
      context,
      negativeText: language.lblCancel,
      positiveText: language.lblDelete,
      onAccept: (_) {
        ifNotTester(() {
          appStore.setLoading(true);
          deleteAccountCompletely().then((value) async {
            try {
              await userService.removeDocument(appStore.uid);
              await userService.deleteUser();
            } catch (e) {
              print(e);
            }
            appStore.setLoading(false);
            await clearPreferences();
            toast(value.message);
            push(
              DashboardScreen(),
              isNewTask: true,
              pageRouteAnimation: PageRouteAnimation.Fade,
            );
          }).catchError((e) {
            appStore.setLoading(false);
            toast(e.toString());
          });
        });
      },
      dialogType: DialogType.DELETE,
      title: language.lblDeleteAccountConformation,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor,
            context.primaryColor.withOpacity(0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withOpacity(0.32),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -18,
            right: -12,
            child: _GlowCircle(size: 90, opacity: 0.08),
          ),
          Positioned(
            bottom: -24,
            right: 40,
            child: _GlowCircle(size: 70, opacity: 0.06),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.settings_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.lblAppSetting,
                      style: boldTextStyle(color: Colors.white, size: 17),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      language.lblCustomizeAppExperience,
                      style: secondaryTextStyle(
                        color: Colors.white.withOpacity(0.78),
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: context.primaryColor),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: boldTextStyle(
              size: 10,
              color: context.primaryColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings Group Card ───────────────────────────────────────────────────────
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.primaryColor.withOpacity(0.07),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(appStore.isDarkMode ? 0.18 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ── Navigation Tile ───────────────────────────────────────────────────────────
class _NavTile extends StatefulWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
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
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color:
              _pressed ? widget.iconBg.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            _IconBadge(icon: widget.icon, color: widget.iconBg),
            const SizedBox(width: 14),
            Expanded(
              child: Text(widget.title, style: boldTextStyle(size: 14)),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.primaryColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toggle Tile ───────────────────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          _IconBadge(icon: icon, color: iconBg),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: boldTextStyle(size: 14)),
          ),
          Transform.scale(
            scale: 0.82,
            alignment: Alignment.centerRight,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: context.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Icon Badge ────────────────────────────────────────────────────────────────
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ── Group Divider ─────────────────────────────────────────────────────────────
class _GroupDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Divider(
        height: 1,
        thickness: 1,
        color: context.dividerColor.withValues(alpha: 0.5),
      ),
    );
  }
}

// ── Decorative Glow Circle ────────────────────────────────────────────────────
class _GlowCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _GlowCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

// ── Danger Tile ───────────────────────────────────────────────────────────────
class _DangerTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DangerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_DangerTile> createState() => _DangerTileState();
}

class _DangerTileState extends State<_DangerTile> {
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
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _pressed ? Colors.red.withOpacity(0.07) : Colors.transparent,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(widget.icon, color: Colors.red.shade600, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: boldTextStyle(color: Colors.red.shade700, size: 14)),
                  const SizedBox(height: 2),
                  Text(widget.subtitle,
                      style: secondaryTextStyle(
                          color: Colors.red.shade400, size: 11)),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chevron_right_rounded,
                  size: 18, color: Colors.red.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
