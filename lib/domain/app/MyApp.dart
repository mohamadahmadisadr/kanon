import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:kanooniha/core/messagingService/MessagingService.dart';

import '../../common/imports/appImports.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const double rootPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialRoute: AppRoutes.splash,
      darkTheme: AppTheme.myTheme(),
      getPages: AppRouteHelper.router,
      title: 'Kanooniha',
      theme: AppTheme.myTheme(),
      locale: AppDefaultLocale.getAppLocale,
      supportedLocales: AppDefaultLocale.supportedLocale,
      localizationsDelegates: AppDefaultLocale.localizationDelegate,
      localeResolutionCallback: (_, __) => AppDefaultLocale.getAppLocale,
      builder: rootTransitionBuilder(),
      scaffoldMessengerKey: GetIt.I.get<MessagingServiceImpl>().messageService,
    );
  }

  TransitionBuilder rootTransitionBuilder() =>
      (_, child) => Scaffold(body: child);
}
