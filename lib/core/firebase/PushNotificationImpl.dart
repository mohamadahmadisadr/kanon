import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:kanooniha/core/Logger.dart';
import 'package:kanooniha/firebase_options.dart';

import '../../presentation/viewModels/appViewModel.dart';

class PushNotificationImpl {
  static void invoke() async {
    try {
      if (kIsWeb) {
        // FirebaseMessaging messaging = FirebaseMessaging.instance;
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyD6dz46y3hvIdUm8cjmAJSR088sNB1rxU8',
            appId: '1:495671824064:web:b4fade677302788cc56725',
            messagingSenderId: '495671824064',
            projectId: 'kanooniha-android',
          ),
        );

    //     alert: true,
    // announcement: false,
    // badge: true,
    // carPlay: false,
    // criticalAlert: false,
    // provisional: false,
    // sound: true,
    // );await messaging.requestPermission(

      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
          name: 'kanooniha-android',
        );
        // FirebaseMessaging messaging = FirebaseMessaging.instance;
        // await messaging.setAutoInitEnabled(true);
        // FirebaseMessaging.onBackgroundMessage(
        //   AppViewModel.firebaseMessagingBackgroundHandler,
        // );
      }
      // FirebaseMessaging messaging = FirebaseMessaging.instance;
      // final fcmToken = await messaging.getToken();
      // print('token is $fcmToken');

      // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      //   print('Got a message whilst in the foreground!');
      //   print('Message data: ${message.data}');
      //
      //   if (message.notification != null) {
      //     print('Message also contained a notification: ${message.notification}');
      //   }
      // });
    } on Exception catch (e, s) {
      print(s);
    }

  }
}
