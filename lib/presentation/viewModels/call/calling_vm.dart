import 'package:core/call/my_webrtc_impl.dart';
import 'package:core/call/user.dart';
import 'package:kanooniha/core/navigationService/NavigationService.dart';
import 'package:kanooniha/data/bases/baseViewModel.dart';

class CallingViewModel extends BaseViewModel {
  final NavigationServiceImpl _navigationServiceImpl = GetIt.I.get();
  final MyWebRtcImpl _webRtcImpl = GetIt.I.get();

  User? user;

  CallingViewModel(super.initialState) {
    getExtra();
  }

  @override
  logEvent() {
    //
  }

  @override
  onReloadClick() {
    //
  }

  @override
  String pageName() => 'calling';

  void getExtra() {
    var data = _navigationServiceImpl.getArgs();
    if (data == null) {
      _navigationServiceImpl.pop();
      return;
    }
    data = (_navigationServiceImpl.getArgs()?.first as dynamic);
    print('got data from calling vm and data is \n $data \n');
    user = User(
      userName: data['username'],
      connectionId: data['connectionId'],
      userId: data['userId'],
      officeId: data['officeId'],
      isOffice: false,
      inCall: false,
    );

    print('got user from calling vm and data is \n ${user?.toMap()} \n');
    refreshScreen();
  }

  void accept() {
    _webRtcImpl.signalR.answerCall(user!);
  }

  void decline() {
    _webRtcImpl.signalR.decline(user!);
  }
}
