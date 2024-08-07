import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:core/storage/shared/LocalSessionImpl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:kanooniha/common/imports/appImports.dart';
import 'package:kanooniha/common/imports/viewModelExports.dart';
import 'package:kanooniha/common/user/UserSessionConst.dart';
import 'package:kanooniha/domain/useCase/user/firebase_token_usecase.dart';
import 'package:kanooniha/firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class FireBaseApi {
  late FirebaseMessaging messaging;

  init() async {
    await Firebase.initializeApp();
    // initializeRemoteNotifications(debug: true);
    await requestPermission();
    if (DefaultFirebaseOptions.currentPlatform ==
        DefaultFirebaseOptions.android) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
    await setupInteractedMessage();
    getToken();
    // openApp();
  }

  Future<void> requestPermission() async {
    messaging = FirebaseMessaging.instance;
    messaging.setAutoInitEnabled(true);
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data.containsKey('link') == true) {
      var link = message.data['link'];
      if (link != null) {
        _launchUrl(link);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch $url';
    }
  }

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // If you're going to use other Firebase services in the background, such as Firestore,
    // make sure you call `initializeApp` before using other Firebase services.
    await Firebase.initializeApp();
    _checkForCallNotif(message);
  }

  Future<void> getToken() async {
    String? token;

    if (DefaultFirebaseOptions.currentPlatform == DefaultFirebaseOptions.web) {
      String vapidKey =
          'BNkCLYgkZRUGROlTcfsvsMt07WXZ24HVhobmv3ia9ZuauC56QOT5oHRvbvniSuD5pKoTYOSmVv0Ov5h2IGSan9k';

      token = await messaging.getToken(vapidKey: vapidKey);
    } else {
      token = await messaging.getToken();
    }

    if (token != null) {
      updateFireBaseToken(token: token);
    }

    messaging.onTokenRefresh.listen(
      (event) => updateFireBaseToken(token: event),
    );

    print('Registration Token=$token');
  }

  Future<void> updateFireBaseToken({String? token}) async {
    if (token != null) {
      GetIt.I
          .get<LocalSessionImpl>()
          .insertData({UserSessionConst.firebaseToken: token});
    } else {
      token = await GetIt.I
          .get<LocalSessionImpl>()
          .getData(UserSessionConst.firebaseToken);
    }

    FireBaseTokenUseCase().invoke(data: token);
  }

  static void _checkForCallNotif(RemoteMessage message) {
    if (message.notification == null) {
      if (message.data.isNotEmpty) {
        showNotificationWithActions(message);
        // openApp();
      }
    }
  }

  static void initAwesomeNotification() async{
    AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null,
      [
        NotificationChannel(
          channelGroupKey: 'calls_channel_group',
          channelKey: 'calls_channel',
          channelName: 'Calls notifications',
          channelDescription: 'Notification channel for calls',
          defaultColor: CupertinoColors.systemBlue,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelGroupKey: 'calls_channel_group',
          channelKey: 'incoming',
          channelName: 'Incoming Call',
          channelDescription: 'Notification channel for calls',
          defaultColor: CupertinoColors.systemBlue,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelGroupKey: 'calls_channel_group',
          channelKey: 'missed',
          channelName: 'Missed Call',
          channelDescription: 'Notification channel for calls',
          defaultColor: CupertinoColors.systemBlue,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'call_channel_group',
            channelGroupName: 'calls group')
      ],
      debug: true,
    );
    await FlutterCallkitIncoming.requestNotificationPermission({
      "rationaleMessagePermission": "Notification permission is required, to show notification.",
      "postNotificationMessageRequired": "Notification permission is required, Please allow notification permission from setting."
    });
  }

  static Future<void> openApp() async {
    AndroidIntent intent = const AndroidIntent(
      action: 'ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      data: 'package:ir.kanoon.kanooniha.android',
    );
    await intent.launch();
  }

// static Future<void> initializeRemoteNotifications(
//     {required bool debug}) async {
//   await Firebase.initializeApp();
//   await AwesomeNotificationsFcm().initialize(
//       onFcmSilentDataHandle: NotificationController.mySilentDataHandle,
//       onFcmTokenHandle: NotificationController.myFcmTokenHandle,
//       onNativeTokenHandle: NotificationController.myNativeTokenHandle,
//       // This license key is necessary only to remove the watermark for
//       // push notifications in release mode. To know more about it, please
//       // visit http://awesome-notifications.carda.me#prices
//       debug: debug);
// }

  @pragma("vm:entry-point")
  static Future<void> showNotificationWithActions(RemoteMessage message) async {
    var name = message.data['username'];
    CallKitParams callKitParams = CallKitParams(
      id: message.messageId,
      nameCaller: name,
      appName: 'kanooniha',
      handle: '',
      type: 0,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: NotificationParams(
        showNotification: true,
        subtitle: 'Missed call',
      ),
      duration: 30000,
      // extra: message.data,
      // headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      android: const AndroidParams(
          isCustomNotification: false,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          actionColor: '#4CAF50',
          textColor: '#ffffff',
          incomingCallNotificationChannelName: "Incoming Call",
          missedCallNotificationChannelName: "Missed Call"),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);

    // AwesomeNotifications().createNotification(
    //   content: NotificationContent(
    //       id: 10,
    //       channelKey: 'calls_channel',
    //       actionType: ActionType.KeepOnTop,
    //       title: 'Calling',
    //       body: '$name is calling',
    //       // payload: message.data,
    //       // fullScreenIntent: true,
    //       wakeUpScreen: true,
    //       timeoutAfter: const Duration(minutes: 1),
    //       category: NotificationCategory.Call,
    //       notificationLayout: NotificationLayout.Default),
    //   actionButtons: [
    //     NotificationActionButton(
    //         key: 'accept',
    //         label: 'Accept',
    //         color: Colors.green,
    //         actionType: ActionType.KeepOnTop,
    //         showInCompactView: true,
    //         isDangerousOption: true),
    //     NotificationActionButton(
    //         key: 'reject',
    //         label: 'Reject',
    //         color: Colors.red,
    //         actionType: ActionType.KeepOnTop,
    //         showInCompactView: true,
    //         isDangerousOption: true),
    //   ],
    // );
  }
}
