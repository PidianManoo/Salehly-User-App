import 'package:booking_system_flutter/component/shimmer_widget.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class WalletHistoryShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        20.height,
        // Wallet card shimmer
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: ShimmerWidget(height: 158, width: context.width()),
        ).paddingSymmetric(horizontal: 16),
        28.height,
        // Section header shimmer
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: ShimmerWidget(height: 18, width: 3),
            ),
            10.width,
            ShimmerWidget(height: 14, width: 120),
          ],
        ).paddingSymmetric(horizontal: 20),
        14.height,
        // Transaction item shimmers
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          itemCount: 6,
          itemBuilder: (_, i) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ShimmerWidget(height: double.infinity, width: 4),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: ShimmerWidget(height: 46, width: 46),
                              ),
                              12.width,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ShimmerWidget(
                                        height: 12,
                                        width: context.width() * 0.35),
                                    8.height,
                                    ShimmerWidget(
                                        height: 10,
                                        width: context.width() * 0.50),
                                  ],
                                ),
                              ),
                              16.width,
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  ShimmerWidget(height: 14, width: 70),
                                  8.height,
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child:
                                        ShimmerWidget(height: 20, width: 50),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
