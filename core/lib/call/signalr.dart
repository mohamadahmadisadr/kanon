import 'package:core/call/user.dart';
import 'package:logging/logging.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'signalR_state.dart';
import 'signalr_callback.dart';

class SignalR extends CallBack {
  List<SignalRState> stateCallbacks = [];

  HubConnection? hubConnection;

  void initHubConfig() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((LogRecord rec) {
      print(
          "${rec.level.name}: ${rec.time}: ${rec.message} ${rec.object != null ? '=>' : ''} ${rec.object ?? ''}");
    });

    final hubProtLogger = Logger("SignalR - hub");

    const serverUrl = "https://app.kanoon.ir/call/ConnectionHub";
    final connectionOptions = HttpConnectionOptions(
      transport: HttpTransportType.WebSockets,
      logMessageContent: true,
      requestTimeout: 30000,
    );
    hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl, options: connectionOptions)
        .configureLogging(hubProtLogger)
        .build();

    hubConnection?.onclose(({error}) {
      print('hubConnection closed error is ${error?.toString()}');
    });
  }

  initEventsHandler() {
    hubConnection?.stateStream.listen(_handleEventStream);

    hubConnection?.on('updateUserList', _handleUpdateUserList);
    hubConnection?.on('incomingCall', _handleIncomingCall);
    hubConnection?.on('callDeclined', _handleCallDeclined);
    hubConnection?.on('receiveSignal', _handleReceiveSignal);
    hubConnection?.on('callAccepted', _handleCallAccepted);
    hubConnection?.on('callEnded', _handleCallEnded);
  }

  void _handleCallDeclined(List<Object?>? arguments) {
    onMessage(MessageType.decline, arguments);
  }

  void _handleCallAccepted(List<Object?>? arguments) {
    onMessage(MessageType.accept, arguments);
  }

  void _handleCallEnded(List<Object?>? arguments) {
    onMessage(MessageType.callEnd, arguments);
  }

  void _handleReceiveSignal(List<Object?>? arguments) {
    onMessage(MessageType.signal, arguments);
  }

  void _handleIncomingCall(List<Object?>? arguments) {
    onMessage(MessageType.calling, arguments);
  }

  void _handleUpdateUserList(List<Object?>? arguments) {
    onMessage(MessageType.updateUsers, arguments);
  }

  void _handleEventStream(HubConnectionState event) {
    onMessage(MessageType.newState, event);
  }

  Future<Object?> hangUp() {
    print('hanging up');
    return hubConnection!.invoke('hangUp');
  }

  Future<Object?> answerCall(User user) {
    return sendMessage("AnswerCall", args: [true, user.userId]);
  }

  Future<Object?> answerOfflineCall(User user) {
    return sendMessage("AnswerCall", args: [true, user.userId,true]);
  }

  Future<Object?> decline(User user) {
    return sendMessage("AnswerCall", args: [false, user.userId]);
  }

  Future<void> callUser(dynamic user) {
    return sendMessage("callUser", args: [user]);
  }

  @override
  onMessage(MessageType type, data) {
    switch (type) {
      case MessageType.calling:
        updateListeners((callBack) => callBack.onNewCall(data));
        break;
      case MessageType.decline:
        updateListeners((callBack) => callBack.onDeclined(data));
        break;
      case MessageType.accept:
        updateListeners((callBack) => callBack.onAccept(data));
        break;
      case MessageType.signal:
        updateListeners((callBack) => callBack.onNewSignal(data));
        break;
      case MessageType.updateUsers:
        updateListeners((callBack) => callBack.onNewUserList(data));
        break;
      case MessageType.callEnd:
        updateListeners((callBack) => callBack.onCallEnd(data));
        break;
      case MessageType.newState:
        updateListeners((callBack) {
          callBack.onNewState(data);
          if (data is HubConnectionState &&
              data == HubConnectionState.Connected) {
            callBack.onConnected(data);
          }
        });
    }
  }

  updateListeners(Function(SignalRState callBack) callback) {
    for (var element in stateCallbacks) {
      callback.call(element);
    }
  }

  @override
  Future<Object?> sendMessage(String name, {List<Object>? args}) {
    return hubConnection!.invoke(name, args: args);
  }

  @override
  start() {
    initHubConfig();
    initEventsHandler();
    hubConnection?.start();
  }

  void addStateListener(SignalRState state) {
    stateCallbacks.add(state);
  }

  @override
  stop() {
    stateCallbacks.clear();
    hubConnection?.stop();
  }

  bool get isConnected => hubConnection?.state == HubConnectionState.Connected;
}
