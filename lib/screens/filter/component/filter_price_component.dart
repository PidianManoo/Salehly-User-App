import 'package:booking_system_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/price_widget.dart';

class FilterPriceComponent extends StatefulWidget {
  final num min;
  final num max;

  const FilterPriceComponent({
    Key? key,
    required this.min,
    required this.max,
  }) : super(key: key);

  @override
  State<FilterPriceComponent> createState() => _FilterPriceComponentState();
}

class _FilterPriceComponentState extends State<FilterPriceComponent> {
  late RangeValues rangeValues;

  // The backend has been observed to return an unbounded/sentinel value
  // (e.g. PHP_INT_MAX, 9223372036854775807) as the max price when it fails
  // to compute a real one. Anything past this ceiling is clearly not a
  // genuine price and is clamped so the UI never has to render 19-digit
  // numbers.
  static const double _maxReasonablePrice = 999999;

  // The API can return min == max (e.g. only one priced service), which
  // RangeSlider does not allow (min must be strictly less than max).
  double get _min => widget.min.toDouble();

  double get _max {
    final double apiMax = widget.max.toDouble();
    final double bounded =
        apiMax > _maxReasonablePrice ? _maxReasonablePrice : apiMax;
    return bounded > _min ? bounded : _min + 1;
  }

  @override
  void initState() {
    super.initState();
    rangeValues = _resolveRange();
  }

  @override
  void didUpdateWidget(covariant FilterPriceComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The price bounds are loaded asynchronously and can also change when
    // switching category/provider, so re-sync whenever they change instead
    // of keeping values from the previous (possibly out-of-range) bounds.
    if (oldWidget.min != widget.min || oldWidget.max != widget.max) {
      setState(() => rangeValues = _resolveRange());
    }
  }

  // Builds a RangeValues that is always guaranteed to sit within
  // [_min, _max] — a previously saved filter can otherwise fall outside the
  // current bounds and make the slider thumbs jump/stick when dragged.
  RangeValues _resolveRange() {
    double start = _min;
    double end = _max;

    final storedMin = num.tryParse(filterStore.isPriceMin);
    final storedMax = num.tryParse(filterStore.isPriceMax);

    if (storedMin != null && storedMax != null) {
      start = storedMin.toDouble().clamp(_min, _max).toDouble();
      end = storedMax.toDouble().clamp(_min, _max).toDouble();
    }

    if (start > end) {
      final temp = start;
      start = end;
      end = temp;
    }

    return RangeValues(start, end);
  }

  Widget _priceChip({required int price}) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.primaryColor.withOpacity(0.08),
        borderRadius: radius(10),
        border: Border.all(color: context.primaryColor.withOpacity(0.2)),
      ),
      // FittedBox shrinks the text instead of overflowing the row if a
      // price ever renders wider than the chip has room for.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: PriceWidget(
          price: price,
          isBoldText: true,
          size: 13,
          color: context.primaryColor,
          decimalPoint: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int divisionCount = (_max - _min).toInt();

    return Container(
      width: context.width(),
      padding: EdgeInsets.all(16),
      decoration: boxDecorationDefault(color: context.cardColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.lblPrice, style: boldTextStyle()),
          20.height,
          Row(
            children: [
              Expanded(child: _priceChip(price: rangeValues.start.round())),
              Container(
                width: 16,
                height: 1.5,
                margin: EdgeInsets.symmetric(horizontal: 8),
                color: context.dividerColor,
              ),
              Expanded(child: _priceChip(price: rangeValues.end.round())),
            ],
          ),
          8.height,
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: context.primaryColor,
              inactiveTrackColor: context.primaryColor.withOpacity(0.15),
              trackHeight: 4,
              rangeThumbShape:
                  const RoundRangeSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              overlayColor: context.primaryColor.withOpacity(0.15),
              rangeValueIndicatorShape:
                  const PaddleRangeSliderValueIndicatorShape(),
              valueIndicatorColor: context.primaryColor,
              valueIndicatorTextStyle:
                  secondaryTextStyle(color: Colors.white, size: 12),
              showValueIndicator: ShowValueIndicator.always,
            ),
            child: RangeSlider(
              min: _min,
              max: _max,
              divisions: divisionCount > 0 ? divisionCount : null,
              labels: RangeLabels(
                rangeValues.start.round().toString(),
                rangeValues.end.round().toString(),
              ),
              values: rangeValues,
              onChanged: (values) {
                setState(() => rangeValues = values);
                filterStore.setMinPrice(values.start.round().toString());
                filterStore.setMaxPrice(values.end.round().toString());
              },
            ),
          ),
        ],
      ),
    );
  }
}
