
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../main.dart';
import '../../../services/location_service.dart';
import '../../../store/place_search_store.dart';
import '../../../utils/common.dart';
import '../custom_aheadtext_feild.dart';

class FilterLocationComponent extends StatefulWidget {
  const FilterLocationComponent({super.key});

  @override
  State<FilterLocationComponent> createState() =>
      _FilterLocationComponentState();
}

class _FilterLocationComponentState extends State<FilterLocationComponent> {
  PlaceSearchStore placeStore = PlaceSearchStore();

  final destinationAddressController = TextEditingController();
  final destinationAddressFocusNode = FocusNode();

  String destinationAddress = '';

  _handleTap(LatLng point, {String address = ''}) async {
    appStore.setLoading(true);

    if (address.isEmpty) {
      destinationAddressController.text =
      await buildFullAddressFromLatLong(point.latitude, point.longitude)
          .catchError((e){
        log(e);
      });
    } else {
      destinationAddressController.text = address;
    }
    destinationAddress = destinationAddressController.text;

    appStore.setLoading(false);
    setState(() {});
  }
  @override
  void initState() {
    destinationAddressController.text = filterStore.locationName.validate();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: context.width(),
        padding: EdgeInsets.all(16),
        decoration: boxDecorationDefault(color: context.cardColor),
        child: Column(
          children: [
            8.height,
            AheadTextField(
              controller: destinationAddressController,
              store: placeStore,
              onSelected: (val) async {
                await convertAddressToLatLong(val).then((value) {
                  if (value != null) {
                    _handleTap(LatLng(value.latitude, value.longitude), address: val);
                    filterStore.setLatitude(value.latitude.toString());
                    filterStore.setLongitude(value.longitude.toString());
                    filterStore.setLocationName(val.toString());
                    log("----longitude-------$val");
                  } else {
                    toast(errorSomethingWentWrong);
                  }
                }).catchError((Error) {
                  toast(errorSomethingWentWrong);
                });
              },
              hintText: language.lblLocation,
              suggestionStyle: secondaryTextStyle(),
              decoration: inputDecoration(context),
              textStyle: primaryTextStyle(),
            ),
          ],
        ));
  }
}
