import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../main.dart';
import '../utils/common.dart';

class LanguagesScreen extends StatefulWidget {
  @override
  LanguagesScreenState createState() => LanguagesScreenState();
}

class LanguagesScreenState extends State<LanguagesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    afterBuildCreated(() => _animCtrl.forward());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> _selectLanguage(LanguageDataModel lang) async {
    await appStore.setLanguage(lang.languageCode!);
    RestartAppWidget.init(context);
  }

  @override
  Widget build(BuildContext context) {
    final langs = languageList();

    return AppScaffold(
      appBarTitle: language.language,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                _buildHeader(context),
                const SizedBox(height: 28),

                // Section label
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 16, 12),
                  child: Row(
                    children: [
                      Icon(Icons.translate_rounded,
                          size: 13, color: context.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        language.lblAvailableLanguages.toUpperCase(),
                        style: boldTextStyle(
                          size: 10,
                          color: context.primaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Language cards
                Observer(builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: List.generate(langs.length, (i) {
                        final lang = langs[i];
                        final isSelected =
                            appStore.selectedLanguageCode ==
                                lang.languageCode;
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: i < langs.length - 1 ? 10 : 0),
                          child: _LangCard(
                            lang: lang,
                            isSelected: isSelected,
                            onTap: () => _selectLanguage(lang),
                          ),
                        );
                      }),
                    ),
                  );
                }),

                const SizedBox(height: 32),

                // Info note
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: context.primaryColor.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.info_outline_rounded,
                              color: context.primaryColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            language.lblAppRestartOnLanguageChange,
                            style: secondaryTextStyle(size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
          Positioned(
            top: -18,
            right: -12,
            child: _GlowCircle(size: 90, opacity: 0.08),
          ),
          Positioned(
            bottom: -22,
            right: 44,
            child: _GlowCircle(size: 65, opacity: 0.06),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.language_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.language,
                      style: boldTextStyle(color: Colors.white, size: 17),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      language.lblChoosePreferredLanguage,
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

// ── Language Card ─────────────────────────────────────────────────────────────
class _LangCard extends StatefulWidget {
  final LanguageDataModel lang;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangCard({
    required this.lang,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LangCard> createState() => _LangCardState();
}

class _LangCardState extends State<_LangCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  String get _nativeName {
    switch (widget.lang.languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      case 'hi':
        return 'हिन्दी';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return widget.lang.name.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? context.primaryColor.withOpacity(0.07)
                : context.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? context.primaryColor.withOpacity(0.55)
                  : context.primaryColor.withOpacity(0.08),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? context.primaryColor.withOpacity(0.12)
                    : Colors.black.withOpacity(0.03),
                blurRadius: selected ? 16 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Flag container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.primaryColor.withOpacity(0.10),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: CachedImageWidget(
                    url: widget.lang.flag.validate(),
                    height: 52,
                    width: 52,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Names
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nativeName,
                      style: boldTextStyle(
                        size: 15,
                        color: selected
                            ? context.primaryColor
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.lang.name.validate(),
                      style: secondaryTextStyle(size: 12),
                    ),
                  ],
                ),
              ),
              // Selection indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? context.primaryColor
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? context.primaryColor
                        : grey.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 15)
                    : null,
              ),
            ],
          ),
        ),
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
