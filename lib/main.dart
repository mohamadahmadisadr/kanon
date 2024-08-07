import 'package:core/downloader/MyDownloader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:kanooniha/common/imports/appImports.dart';
import 'package:kanooniha/core/app/firebase_api.dart';

import 'domain/app/MyApp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FireBaseApi().init();
  MyDownloader.init();
  FireBaseApi.initAwesomeNotification();
  await AppViewModel.initAppModule();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.grey.shade50,
    systemNavigationBarColor: Colors.grey.shade50,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  // setPathUrlStrategy();
  runApp(
    BlocBuilder(
      builder: (context, state) => const MyApp(),
      bloc: AppViewModel.getInstance,
    ),
  );
}
