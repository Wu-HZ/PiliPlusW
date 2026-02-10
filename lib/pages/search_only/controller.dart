import 'dart:async';

import 'package:PiliMinus/http/loading_state.dart';
import 'package:PiliMinus/http/search.dart';
import 'package:PiliMinus/models/search/suggest.dart';
import 'package:PiliMinus/pages/search/controller.dart';
import 'package:PiliMinus/utils/extension/string_ext.dart';
import 'package:PiliMinus/utils/id_utils.dart';
import 'package:PiliMinus/utils/platform_utils.dart';
import 'package:PiliMinus/utils/storage.dart';
import 'package:PiliMinus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

class SearchOnlyController extends GetxController
    with DebounceStreamMixin<String> {
  SearchOnlyController(this.tag);
  final String tag;

  final searchFocusNode = FocusNode();
  final controller = TextEditingController();

  String? hintText;

  // uid
  final RxBool showUidBtn = false.obs;

  // history (local only, not displayed)
  final historyList = List<String>.from(
    GStorage.historyWord.get('cacheList') ?? [],
  ).obs;
  final recordSearchHistory = Pref.recordSearchHistory.obs;

  // suggestion
  final bool searchSuggestion = Pref.searchSuggestion;
  late final RxList<SearchSuggestItem> searchSuggestList;

  @override
  void onInit() {
    super.onInit();
    final params = Get.parameters;
    hintText = params['hintText'];
    final text = params['text'];
    if (text != null) {
      controller.text = text;
    }

    if (searchSuggestion) {
      subInit();
      searchSuggestList = <SearchSuggestItem>[].obs;
    }
  }

  void validateUid() {
    showUidBtn.value = IdUtils.digitOnlyRegExp.hasMatch(controller.text);
  }

  void onChange(String value) {
    validateUid();
    if (searchSuggestion) {
      if (value.isEmpty) {
        searchSuggestList.clear();
      } else {
        ctr!.add(value);
      }
    }
  }

  void onClear() {
    if (controller.value.text != '') {
      controller.clear();
      if (searchSuggestion) searchSuggestList.clear();
      searchFocusNode.requestFocus();
      showUidBtn.value = false;
    }
  }

  // 搜索
  Future<void> submit() async {
    if (controller.text.isEmpty) {
      if (hintText.isNullOrEmpty) {
        return;
      }
      controller.text = hintText!;
      validateUid();
    }

    if (recordSearchHistory.value) {
      historyList
        ..remove(controller.text)
        ..insert(0, controller.text);
      GStorage.historyWord.put('cacheList', historyList);
    }

    searchFocusNode.unfocus();
    await Get.toNamed(
      '/searchResult',
      parameters: {
        'tag': tag,
        'keyword': controller.text,
      },
      arguments: {
        'initIndex': 0,
        'fromSearch': true,
      },
    );
    searchFocusNode.requestFocus();
    if (PlatformUtils.isDesktop) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
      });
    }
  }

  void onClickKeyword(String keyword) {
    controller.text = keyword;
    validateUid();

    if (searchSuggestion) searchSuggestList.clear();
    submit();
  }

  @override
  Future<void> onValueChanged(String value) async {
    final res = await SearchHttp.searchSuggest(term: value);
    if (res case Success(:final response)) {
      if (response.tag?.isNotEmpty == true) {
        searchSuggestList.value = response.tag!;
      }
    }
  }

  @override
  void onClose() {
    subDispose();
    searchFocusNode.dispose();
    controller.dispose();
    super.onClose();
  }
}
