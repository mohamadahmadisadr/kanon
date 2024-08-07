import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:core/call/my_webrtc_impl.dart';
import 'package:core/call/signalR_state.dart';
import 'package:core/call/user.dart';
import 'package:core/ringtone/my_ringtone.dart';
import 'package:core/storage/shared/LocalSessionImpl.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:kanooniha/common/user/UserSessionConst.dart';
import 'package:kanooniha/core/Notification/MyNotification.dart';
import 'package:kanooniha/core/Notification/MyNotificationListener.dart';
import 'package:kanooniha/core/navigationService/NavigationService.dart';
import 'package:kanooniha/data/bases/baseViewModel.dart';
import 'package:kanooniha/data/body/user/UserInfoCallResponse.dart';
import 'package:kanooniha/data/serializer/app/MenuItemSerializer.dart';
import 'package:kanooniha/data/serializer/poll/polls_response.dart';
import 'package:kanooniha/domain/useCase/app/app_menu_UseCase.dart';
import 'package:kanooniha/domain/useCase/home/NavigationNotifier.dart';
import 'package:kanooniha/domain/useCase/home/StartupTaskUseCase.dart';
import 'package:kanooniha/presentation/ui/dialog/polls_dialog.dart';
import 'package:kanooniha/presentation/uiModel/home/HomeNavigationModel.dart';
import 'package:kanooniha/presentation/uiModel/home/HomeNavigationObject.dart';
import 'package:kanooniha/presentation/uiModel/home/MessagesNavigationModel.dart';

import '../../../common/imports/appImports.dart';
import '../../../domain/useCase/poll/get_poll_use_case.dart';
import '../../../domain/useCase/user/GetUserCallInfoUseCase.dart';

class HomeViewModel extends BaseViewModel
    implements MyNotificationListener, SignalRState {
  final MyNotification _notification = GetIt.I.get<MyNotification>();
  final MyRingTone _ringTone = GetIt.I.get();
  final _navigationServiceImpl = GetIt.I.get<NavigationServiceImpl>();
  final _localSession = GetIt.I.get<LocalSessionImpl>();
  final homeMenu = HomeNavigationObject.homeMenu;
  final appBarMenu = HomeNavigationObject.appbarMenu;
  var rtc = GetIt.I.get<MyWebRtcImpl>();

  AppState menuState = AppState.idle;

  HomeViewModel(super.initialState) {
    _notification.subscribeListener(this);
    getMenus();
    getPolls();
    getUserCall();
    getNotificationPermission();
    // checkStarUpData();
  }

  late HomeNavigationModel _index = homeMenu[0];

  HomeNavigationModel get currentIndex => _index;

  Function(HomeNavigationModel) onIndexChange() {
    return (value) {
      var item = total.firstWhereOrNull(
          (element) => element.runtimeType == value.runtimeType);
      if (item != null) {
        _index = item;
        updateScreen(time: DateTime.now().microsecondsSinceEpoch.toDouble());
      }
    };
  }

  List<HomeNavigationModel> get total => homeMenu + appBarMenu;

  Function(HomeNavigationModel) onBadgeChange() {
    return (value) {
      _index = value;
      refreshScreen();
    };
  }

  void checkStarUpData() {
    StartupTaskUseCase.invoke();
  }

  void updateMessages(String value) {
    var index = homeMenu.indexWhere(
        (element) => element.value() == HomeNavigationEnum.messages);
    if (index != -1 && index < homeMenu.length) {
      if (homeMenu[index] is MessagesNavigationModel) {
        if (value.isNum) {
          (homeMenu[index] as MessagesNavigationModel).changeBadge(value);
        } else {
          var oldValueStr =
              (homeMenu[index] as MessagesNavigationModel).badgeContainer;
          var oldValueInt = int.tryParse(oldValueStr);
          if (oldValueInt != null) {
            if (oldValueInt > 1) {
              (homeMenu[index] as MessagesNavigationModel)
                  .changeBadge('${oldValueInt - 1}');
            } else {
              (homeMenu[index] as MessagesNavigationModel).changeBadge('');
            }
          }
        }

        refreshScreen();
      }
    }
  }

  void getMenus() {
    AppMenuUseCase().invoke(flow: MyFlow<AppState>((appState) {
      if (appState.isSuccess && appState.getData is List<MenuItemSerializer>) {
        var list = appState.getData as List<MenuItemSerializer>;
        for (var totalElement in total) {
          var item = list
              .firstWhereOrNull((item) => totalElement.serverName == item.kind);
          if (item != null) {
            if (item.isActive == false) {
              homeMenu.remove(totalElement);
              appBarMenu.remove(totalElement);
            } else {
              var index = homeMenu
                  .indexWhere((element) => element.serverName == item.kind);
              if (index != -1 && item.title != null) {
                homeMenu[index].name = item.title!;
              }
            }
          }
        }
      }
      menuState = appState;
      postResult(appState);
    }));
  }

  @override
  void onReceiveData(data) {
    if (data != null && data is Map<String, String>) {
      Map<String, String> value = data;
      if (value.keys.first == NavigationNotifier.messages) {
        updateMessages(value.values.first);
      }
      if (value.keys.first == NavigationNotifier.news) {
        updateNews(value.values.first);
      }
    }
  }

  @override
  String tag() {
    return 'HomeViewModel';
  }

  void updateNews(String value) {
    // if (homeMenu[4] is NewsNavigationModel) {
    //   (homeMenu[4] as NewsNavigationModel).changeBadge(value);
    //   refreshScreen();
    // }
  }

  getPage() => _index.page();

  @override
  String pageName() => '';

  @override
  logEvent() {
    // logOnFireBase(pageName());
  }

  @override
  onReloadClick() {
    getMenus();
  }

  void getPolls() {
    GetPollUseCase().invoke(flow: MyFlow((appState) {
      if (appState.isSuccess && appState.getData is List<PollsResponse>) {
        List<PollsResponse> response = appState.getData;
        if (response.isNotEmpty) {
          Get.dialog(
            PollsDialog(
              polls: response.first,
              force: response.first.isRequired == true,
            ),
          );
        }
      }
    }));
  }

  void getUserCall() {
    if (rtc.isConnected) {
      return;
    }
    GetUserCallInfoUseCase().invoke(flow: MyFlow((appState) async {
      if (appState.isSuccess) {
        UserInfoCallResponse userInfoCall = appState.getData;
        if (userInfoCall.userAllowCall == true) {
          var token =
              await _localSession.getData(UserSessionConst.firebaseToken);
          User user = userInfoCall.createUser(token: token);
          rtc.signalR.addStateListener(this);
          rtc.setUser(user);
          rtc.start();
        }
      }
    }));
  }

  @override
  void onAccept(data) {
    _ringTone.stop();
    if (isInCall) {
      _navigationServiceImpl.replaceTo(AppRoutes.call, data);
    } else {
      _navigationServiceImpl.navigateTo(AppRoutes.call, data);
    }
  }

  @override
  void onCallEnd(data) {
    if (isInCall) {
      _ringTone.stop();
      _navigationServiceImpl.pop();
    }
    print('call ended data is $data');
  }

  @override
  void onDeclined(data) {
    _ringTone.stop();
    print('call declined data is $data');
    if (isInCall) {
      _navigationServiceImpl.pop();
    }
  }

  bool get isInCall =>
      Get.currentRoute == AppRoutes.call ||
      Get.currentRoute == AppRoutes.calling;

  @override
  void onNewCall(data) {
    _ringTone.play();
    _navigationServiceImpl.navigateTo(AppRoutes.calling, data);
  }

  @override
  void onNewSignal(data) {
    //
  }

  @override
  void onNewState(data) {
    print('new state reached is $data');
  }

  @override
  void onNewUserList(data) {
    //
  }

  @override
  Future<void> close() {
    _ringTone.stop();
    rtc.dispose();
    return super.close();
  }

  void getNotificationPermission() {
    AwesomeNotifications().requestPermissionToSendNotifications();
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // This is just a basic example. For real apps, you must show some
        // friendly dialog box before call the request method.
        // This is very important to not harm the user experience
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  @override
  void onConnected(data) async {
    //
  }

  @override
  void onJoined(data) async{
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        await FlutterCallkitIncoming.endAllCalls();
        print('DATA: ${calls[0]['extra']}');
        var data = calls[0]['extra'];
        User user = User(
          userName: data['username'],
          connectionId: data['connectionId'],
          userId: data['userId'],
          officeId: data['officeId'],
          isOffice: false,
          inCall: false,
        );
        rtc.signalR.answerOfflineCall(user);

      }
    }
  }
}
