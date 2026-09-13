// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_search_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PlaceSearchStore on _PlaceSearchStore, Store {
  Computed<bool>? _$hasSuggestionsComputed;

  @override
  bool get hasSuggestions =>
      (_$hasSuggestionsComputed ??= Computed<bool>(() => super.hasSuggestions,
              name: '_PlaceSearchStore.hasSuggestions'))
          .value;

  late final _$suggestionsAtom =
      Atom(name: '_PlaceSearchStore.suggestions', context: context);

  @override
  ObservableList<String> get suggestions {
    _$suggestionsAtom.reportRead();
    return super.suggestions;
  }

  @override
  set suggestions(ObservableList<String> value) {
    _$suggestionsAtom.reportWrite(value, super.suggestions, () {
      super.suggestions = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: '_PlaceSearchStore.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$searchTextAtom =
      Atom(name: '_PlaceSearchStore.searchText', context: context);

  @override
  String get searchText {
    _$searchTextAtom.reportRead();
    return super.searchText;
  }

  @override
  set searchText(String value) {
    _$searchTextAtom.reportWrite(value, super.searchText, () {
      super.searchText = value;
    });
  }

  late final _$getSuggestionsAsyncAction =
      AsyncAction('_PlaceSearchStore.getSuggestions', context: context);

  @override
  Future<void> getSuggestions(String input) {
    return _$getSuggestionsAsyncAction.run(() => super.getSuggestions(input));
  }

  late final _$_PlaceSearchStoreActionController =
      ActionController(name: '_PlaceSearchStore', context: context);

  @override
  void setSearchText(String value) {
    final _$actionInfo = _$_PlaceSearchStoreActionController.startAction(
        name: '_PlaceSearchStore.setSearchText');
    try {
      return super.setSearchText(value);
    } finally {
      _$_PlaceSearchStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void refreshSessionToken() {
    final _$actionInfo = _$_PlaceSearchStoreActionController.startAction(
        name: '_PlaceSearchStore.refreshSessionToken');
    try {
      return super.refreshSessionToken();
    } finally {
      _$_PlaceSearchStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
suggestions: ${suggestions},
isLoading: ${isLoading},
searchText: ${searchText},
hasSuggestions: ${hasSuggestions}
    ''';
  }
}
