// place_search_store.dart
import 'dart:convert';
import 'package:mobx/mobx.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../utils/configs.dart';


// Include this line to generate the Store class
part 'place_search_store.g.dart';

class PlaceSearchStore = _PlaceSearchStore with _$PlaceSearchStore;

abstract class _PlaceSearchStore with Store {
  final uuid = const Uuid();

  _PlaceSearchStore() {
    _sessionToken = uuid.v4();
  }

  late String _sessionToken;

  @observable
  ObservableList<String> suggestions = ObservableList<String>();

  @observable
  bool isLoading = false;

  @observable
  String searchText = '';

  @action
  void setSearchText(String value) {
    searchText = value;
  }

  @action
  Future<void> getSuggestions(String input) async {
    if (input.isEmpty) {
      suggestions.clear();
      return;
    }

    isLoading = true;

    try {
      final request =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$GOOGLE_MAP_KEY&sessiontoken=$_sessionToken';
      final response = await http
          .get(Uri.parse(request))
          .timeout(const Duration(seconds: 4));
      final data = jsonDecode(response.body);

      suggestions.clear();
      suggestions.addAll(
        List<String>.from(
          data['predictions'].map((prediction) => prediction['description']),
        ),
      );


      print("suggestion------------------> ${suggestions}");
    } catch (e) {
      suggestions.clear();
    } finally {
      isLoading = false;
    }
  }

  @action
  void refreshSessionToken() {
    _sessionToken = uuid.v4();
  }

  @computed
  bool get hasSuggestions => suggestions.isNotEmpty;
}