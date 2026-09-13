import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../main.dart';
import '../../auth/sign_in_screen.dart';
import '../../jobRequest/my_post_request_list_screen.dart';

class NewJobRequestComponent extends StatelessWidget {
  final bool isAfterCategory;
  const NewJobRequestComponent({Key? key, this.isAfterCategory = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor,
            Color.lerp(context.primaryColor, Colors.indigo.shade900, 0.45)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: !isAfterCategory
            ? BorderRadius.only(
                topLeft: Radius.circular(defaultRadius),
                topRight: Radius.circular(defaultRadius),
              )
            : BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.38),
            blurRadius: 18,
            spreadRadius: 0,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // ── Decorative circles ──────────────────────────────────────────────
          Positioned(top: -35, right: -25, child: _circle(130, 0.09)),
          Positioned(bottom: -45, right: 55, child: _circle(110, 0.07)),
          Positioned(top: 18, right: 100, child: _circle(14, 0.22)),
          Positioned(bottom: 22, right: 28, child: _circle(9, 0.30)),
          Positioned(top: 50, right: 170, child: _circle(6, 0.18)),

          // ── Content ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: badge + title + subtitle + CTA
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge chip
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: radius(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.work_outline_rounded, color: Colors.white, size: 12),
                            5.width,
                            Text(
                              language.postJob.toUpperCase(),
                              style: boldTextStyle(color: Colors.white, size: 10)
                                  .copyWith(letterSpacing: 1.0),
                            ),
                          ],
                        ),
                      ),
                      10.height,
                      // Bold headline (new localised key)
                      Text(
                        language.lblJobRequestTitle,
                        style: boldTextStyle(color: Colors.white, size: 17),
                      ),
                      6.height,
                      // Subtitle
                      Text(
                        language.jobRequestSubtitle,
                        style: primaryTextStyle(color: Colors.white.withValues(alpha: 0.85), size: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      16.height,
                      // CTA button — full width, no overflow
                      _buildButton(context),
                    ],
                  ),
                ),
                16.width,
                // Right: floating icon
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                  ),
                  child: Center(
                    child: Icon(Icons.work_history_rounded, color: Colors.white, size: 34),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );

  Widget _buildButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (appStore.isLoggedIn) {
          MyPostRequestListScreen().launch(context);
        } else {
          setStatusBarColor(Colors.white, statusBarIconBrightness: Brightness.dark);
          bool? res = await SignInScreen(returnExpected: true).launch(context);
          if (res ?? false) {
            MyPostRequestListScreen().launch(context);
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        // Row is unconstrained — Expanded on the Text prevents overflow
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, color: context.primaryColor, size: 15),
            ),
            10.width,
            Expanded(
              child: Text(
                language.newPostJobRequest,
                style: boldTextStyle(color: context.primaryColor, size: 13),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            8.width,
            Icon(Icons.arrow_forward_ios_rounded, color: context.primaryColor, size: 13),
          ],
        ),
      ),
    );
  }
}
