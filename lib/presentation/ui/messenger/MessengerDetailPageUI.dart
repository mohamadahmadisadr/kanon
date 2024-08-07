import 'package:core/downloader/DownloadTaskStrategyRepository.dart';
import 'package:core/downloader/MyDownloader.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:kanooniha/common/imports/viewModelExports.dart';
import 'package:kanooniha/presentation/ui/main/CubitProvider.dart';
import 'package:kanooniha/presentation/ui/main/custom_leasing.dart';

import '../../../common/imports/WidgetImports.dart';
import '../../../core/GetExtensions.dart';
import '../../uiModel/messenger/MessengerUIModel.dart';
import '../../viewModels/messenger/MessengerDetailViewModel.dart';

class MessengerDetailPageUI extends StatefulWidget {
  const MessengerDetailPageUI({Key? key}) : super(key: key);

  @override
  State<MessengerDetailPageUI> createState() => _MessengerDetailPageUIState();
}

class _MessengerDetailPageUIState extends State<MessengerDetailPageUI> {
  MessengerUIModel? messengerItem;

  @override
  void initState() {
    messengerItem = getExtra();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزییات پیام'),
        leading: const CustomLeading(),
      ),
      body: CubitProvider(
        create: (context) => MessengerDetailViewModel(AppState.idle),
        builder: (bloc, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(WidgetSize.pagePaddingSize),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    messengerItem?.title ?? '',
                    style: context.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const MySpacer(size: 30),
                  Text(messengerItem?.description ?? '',
                      style: context.textTheme.bodyMedium),
                  if (messengerItem?.link.isNotEmpty == true)
                    TextButton.icon(
                      onPressed: () {
                        MyDownloader.openUrl(link: messengerItem!.link,type: DownloadTaskTypes.url);
                      },
                      label: const Text('مشاهده فایل پیوست'),
                      icon: const Icon(CupertinoIcons.left_chevron),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  MessengerUIModel? getExtra() {
    return GetExtensions.getArgs<MessengerUIModel>();
  }
}
