import 'package:PiliMinus/pages/search_only/controller.dart';
import 'package:PiliMinus/utils/em.dart' show Em;
import 'package:PiliMinus/utils/extension/size_ext.dart';
import 'package:PiliMinus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchOnlyPage extends StatefulWidget {
  const SearchOnlyPage({super.key});

  @override
  State<SearchOnlyPage> createState() => _SearchOnlyPageState();
}

class _SearchOnlyPageState extends State<SearchOnlyPage> {
  final _tag = Utils.generateRandomString(6);
  late final SearchOnlyController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = Get.put(
      SearchOnlyController(_tag),
      tag: _tag,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPortrait = MediaQuery.sizeOf(context).isPortrait;
    return Scaffold(
      appBar: AppBar(
        shape: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        leading: IconButton(
          tooltip: '进入应用主页',
          icon: const Icon(Icons.home_outlined, size: 22),
          onPressed: () => Get.offAllNamed('/'),
        ),
        actions: [
          Obx(
            () => _searchController.showUidBtn.value
                ? IconButton(
                    tooltip: 'UID搜索用户',
                    icon: const Icon(Icons.person_outline, size: 22),
                    onPressed: () => Get.toNamed(
                      '/member?mid=${_searchController.controller.text}',
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: '清空',
            icon: const Icon(Icons.clear, size: 22),
            onPressed: _searchController.onClear,
          ),
          IconButton(
            tooltip: '搜索',
            onPressed: _searchController.submit,
            icon: const Icon(Icons.search, size: 22),
          ),
          const SizedBox(width: 10),
        ],
        title: TextField(
          autofocus: true,
          focusNode: _searchController.searchFocusNode,
          controller: _searchController.controller,
          textInputAction: TextInputAction.search,
          onChanged: _searchController.onChange,
          decoration: InputDecoration(
            visualDensity: .standard,
            hintText: _searchController.hintText ?? '搜索',
            border: InputBorder.none,
          ),
          onSubmitted: (value) => _searchController.submit(),
        ),
      ),
      body: _buildBody(theme, isPortrait),
    );
  }

  Widget _buildBody(ThemeData theme, bool isPortrait) {
    return ListView(
      padding: MediaQuery.viewPaddingOf(context).copyWith(top: 0),
      children: [
        if (_searchController.searchSuggestion) _searchSuggest(),
        _emptyStateHint(theme),
      ],
    );
  }

  Widget _searchSuggest() {
    return Obx(
      () =>
          _searchController.searchSuggestList.isNotEmpty &&
              _searchController.searchSuggestList.first.term != null &&
              _searchController.controller.text != ''
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _searchController.searchSuggestList
                  .map(
                    (item) => InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      onTap: () =>
                          _searchController.onClickKeyword(item.term!),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          top: 9,
                          bottom: 9,
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: Em.regTitle(item.textRich)
                                .map(
                                  (e) => TextSpan(
                                    text: e.text,
                                    style: e.isEm
                                        ? TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          )
                                        : null,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _emptyStateHint(ThemeData theme) {
    return Obx(() {
      if (_searchController.searchSuggestion &&
          _searchController.searchSuggestList.isNotEmpty &&
          _searchController.controller.text.isNotEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '输入关键词开始搜索',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () => Get.offAllNamed('/'),
              icon: const Icon(Icons.home_outlined),
              label: const Text('进入应用主页'),
            ),
          ],
        ),
      );
    });
  }
}
