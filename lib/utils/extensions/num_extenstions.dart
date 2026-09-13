import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../main.dart';
import '../app_configuration.dart';

extension NumExtension on num {
  String toPriceFormat() {
    return "${isCurrencyPositionLeft ? isSaudiRiyalsSymbol ? saudiRiyalsNewSymbol : appConfigurationStore.currencySymbol : ''}${this.toStringAsFixed(appConfigurationStore.priceDecimalPoint).formatNumberWithComma()}${isCurrencyPositionRight ? isSaudiRiyalsSymbol ? saudiRiyalsNewSymbol : appConfigurationStore.currencySymbol : ''}";
  }

  num calculatePercentage(int discount) {
    return this.validate() - (this.validate() * discount / 100);
  }
}
