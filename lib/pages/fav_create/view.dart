import 'package:PiliMinus/models_new/fav/fav_folder/list.dart';
import 'package:PiliMinus/services/local_favorites_service.dart';
import 'package:PiliMinus/utils/fav_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class CreateFavPage extends StatefulWidget {
  const CreateFavPage({super.key});

  @override
  State<CreateFavPage> createState() => _CreateFavPageState();
}

class _CreateFavPageState extends State<CreateFavPage> {
  dynamic _mediaId;
  late final TextEditingController _titleController;
  late final TextEditingController _introController;
  bool _isPublic = true;
  int? _attr;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _introController = TextEditingController();
    _mediaId = Get.parameters['mediaId'];
    if (_mediaId != null) {
      _getFolderInfo();
    }
  }

  void _getFolderInfo() {
    final mediaIdInt = int.tryParse(_mediaId.toString());
    if (mediaIdInt == null) return;

    final folder = LocalFavoritesService.getFolder(mediaIdInt);
    if (folder != null) {
      _titleController.text = folder.title;
      _introController.text = folder.intro ?? '';
      _isPublic = FavUtils.isPublicFav(folder.attr);
      _attr = folder.attr;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_mediaId != null ? '编辑' : '创建'),
        actions: [
          TextButton(
            onPressed: () async {
              if (_titleController.text.isEmpty) {
                SmartDialog.showToast('名称不能为空');
                return;
              }

              FavFolderInfo? result;
              if (_mediaId == null) {
                // Create new folder
                result = await LocalFavoritesService.createFolder(
                  title: _titleController.text,
                  privacy: _isPublic ? 0 : 1,
                  intro: _introController.text,
                );
              } else {
                // Edit existing folder
                final mediaIdInt = int.tryParse(_mediaId.toString());
                if (mediaIdInt != null) {
                  result = await LocalFavoritesService.updateFolder(
                    folderId: mediaIdInt,
                    title: _titleController.text,
                    privacy: _isPublic ? 0 : 1,
                    intro: _introController.text,
                  );
                }
              }

              if (result != null) {
                Get.back(result: result);
                SmartDialog.showToast('${_mediaId != null ? '编辑' : '创建'}成功');
              } else {
                SmartDialog.showToast('操作失败');
              }
            },
            child: const Text('完成'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  final leadingStyle = const TextStyle(fontSize: 14);

  Widget _buildBody(ThemeData theme) => SingleChildScrollView(
    padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom + 25),
    child: Column(
      spacing: 12,
      children: [
        ListTile(
          tileColor: theme.colorScheme.onInverseSurface,
          title: Row(
            children: [
              SizedBox(
                width: 55,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '*',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const TextSpan(
                        text: '名称',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  autofocus: true,
                  readOnly: _attr != null && FavUtils.isDefaultFav(_attr!),
                  controller: _titleController,
                  style: TextStyle(
                    fontSize: 14,
                    color: _attr != null && FavUtils.isDefaultFav(_attr!)
                        ? theme.colorScheme.outline
                        : null,
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(20),
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '名称',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.outline,
                    ),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      gapPadding: 0,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_attr == null || !FavUtils.isDefaultFav(_attr!))
          ListTile(
            tileColor: theme.colorScheme.onInverseSurface,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 55,
                  child: Text(
                    '简介',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    minLines: 6,
                    maxLines: 6,
                    controller: _introController,
                    style: const TextStyle(fontSize: 14),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(200),
                    ],
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '可填写简介',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.outline,
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        gapPadding: 0,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Builder(
          builder: (context) {
            void onTap() {
              _isPublic = !_isPublic;
              (context as Element).markNeedsBuild();
            }

            return ListTile(
              onTap: onTap,
              tileColor: theme.colorScheme.onInverseSurface,
              leading: Text(
                '公开',
                style: leadingStyle,
              ),
              trailing: Transform.scale(
                alignment: Alignment.centerRight,
                scale: 0.8,
                child: Switch(
                  value: _isPublic,
                  onChanged: (value) => onTap(),
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}
