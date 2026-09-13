import 'dart:async';

import 'package:booking_system_flutter/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../component/cached_image_widget.dart';
import '../../../../model/dashboard_model.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/configs.dart';
import '../../../../utils/constant.dart';

class SliderDashboardComponent3 extends StatefulWidget {
  final List<SliderModel> sliderList;

  SliderDashboardComponent3({required this.sliderList});

  @override
  _SliderDashboardComponent3State createState() =>
      _SliderDashboardComponent3State();
}

class _SliderDashboardComponent3State extends State<SliderDashboardComponent3> {
  late final PageController sliderPageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    sliderPageController = PageController(
      initialPage: 0,
      viewportFraction: 0.88,
    );
    init();
  }

  void init() {
    if (getBoolAsync(AUTO_SLIDER_STATUS, defaultValue: true) &&
        widget.sliderList.length >= 2) {
      _timer = Timer.periodic(
        Duration(seconds: DASHBOARD_AUTO_SLIDER_SECOND),
        (timer) {
          _currentPage = _currentPage < widget.sliderList.length - 1
              ? _currentPage + 1
              : 0;
          sliderPageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
          );
        },
      );

      sliderPageController.addListener(() {
        final page = sliderPageController.page?.round() ?? 0;
        if (page != _currentPage) {
          setState(() => _currentPage = page);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    sliderPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sliderList.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 185,
          child: PageView.builder(
            controller: sliderPageController,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.sliderList.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final data = widget.sliderList[index];
              final bool isActive = index == _currentPage;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.only(
                  right: 10,
                  top: isActive ? 0 : 12,
                  bottom: isActive ? 0 : 12,
                ),
                child: _SlideCard(
                  data: data,
                  isActive: isActive,
                ),
              );
            },
          ),
        ),

        // Dot indicators
        if (widget.sliderList.length > 1) ...[
          14.height,
          _buildDotRow(),
        ],
      ],
    );
  }

  Widget _buildDotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.sliderList.length, (i) {
        final bool active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? primaryColor : primaryColor.withOpacity(0.25),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}

class _SlideCard extends StatelessWidget {
  final SliderModel data;
  final bool isActive;

  const _SlideCard({required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          // boxShadow: isActive
          //     ? [
          //         BoxShadow(
          //           color: primaryColor.withOpacity(0.22),
          //           blurRadius: 20,
          //           offset: const Offset(0, 8),
          //         ),
          //         BoxShadow(
          //           color: Colors.black.withOpacity(0.10),
          //           blurRadius: 10,
          //           offset: const Offset(0, 3),
          //         ),
          //       ]
          //     : [
          //         BoxShadow(
          //           color: Colors.black.withOpacity(0.06),
          //           blurRadius: 8,
          //           offset: const Offset(0, 2),
          //         ),
          // ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              CachedImageWidget(
                url: data.sliderImage.validate(),
                fit: BoxFit.cover,
                height: 100,
              ),

              // Gradient overlay for depth
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.35),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              // Active slide shimmer border
              if (isActive)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ).onTap(() {
        launchMail(defaultSupportEmail);
      }),
    );
  }
}
