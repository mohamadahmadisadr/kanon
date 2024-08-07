import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signalr_netcore/hub_connection.dart';

import 'my_webRTC.dart';
import 'signalR_state.dart';
import 'signalr.dart';
import 'user.dart';

class MyWebRtcImpl implements MyWebRTC, SignalRState {
  final SignalR signalR;
  User? user;

  MyWebRtcImpl(this.signalR) {
    signalR.addStateListener(this);
  }

  Map<String, RTCPeerConnection> connections = {};
  MediaStream? localeStream;
  var peerConnectionConfig = {
    "iceServers": [
      {
        "urls": "stun:stun.relay.metered.ca:80",
      },
      {
        "urls": "turn:a.relay.metered.ca:80",
        "username": "a79ed1cf48006d9a273abd28",
        "credential": "fhXaHGiPxiaJFes4",
      }
    ]
  };
  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ]
  };

  String get sdpSemantics => 'unified-plan';

  void setUser(User user) {
    this.user = user;
  }

  @override
  Future<void> initMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false
    };
    localeStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    if (!kIsWeb) {
      localeStream?.getAudioTracks()[0].enableSpeakerphone(false);
    }
  }

  @override
  void initOffer(userId, stream) async {
    var connection = await getConnection(userId);
    stream?.getTracks().forEach((track) {
      connection.addTrack(track, localeStream!);
    });
    connection.createOffer().then((offer) {
      connection.setLocalDescription(offer).then((value) async {
        var ld = await connection.getLocalDescription();
        await signalR.sendMessage('sendSignal', args: [
          jsonEncode({"sdp": ld?.toMap()}),
          userId.toString()
        ]);
      }).catchError((error) {
        print(error);
      });
    }).catchError((error) {
      print(error);
    });
  }

  @override
  void receivedCandidateSignal(connection, userId, candidate) {
    print('received new candidate and that is ${candidate}');
    try {
      connection.addCandidate(RTCIceCandidate(candidate['candidate'],
          candidate['sdpMid'], candidate['sdpMLineIndex']));
    } on Exception catch (e, s) {
      print(s);
    }
  }

  @override
  void receivedSdpSignal(connection, userId, sdp, type) async {
    await connection.setRemoteDescription(RTCSessionDescription(sdp, type));
    var remoteDescription = await connection.getRemoteDescription();
    if (remoteDescription?.type == 'offer') {
      localeStream?.getTracks().forEach((track) {
        connection.addTrack(track, localeStream!);
      });
      connection.createAnswer().then((desc) {
        connection.setLocalDescription(desc).then((value) async {
          var ld = (await connection.getLocalDescription());
          signalR.sendMessage("sendSignal", args: [
            jsonEncode({"sdp": ld?.toMap()}),
            userId.toString()
          ]);
        });
      });
    } else if (remoteDescription?.type == 'answer') {
      print('WebRTC: remote Description type answer');
    }
  }

  @override
  void dispose() {
    localeStream?.dispose();
    connections.clear();
    signalR.stop();
  }

  @override
  void start() {
    if (user == null) {
      print("user don't defined");
      return;
    }
    signalR.start();
  }

  Future<RTCPeerConnection> getConnection(userId) async {
    if (connections[userId] != null) {
      return connections[userId]!;
    } else {
      return await initializeConnection(userId);
    }
  }

  Future<RTCPeerConnection> initializeConnection(dynamic userId) async {
    await initMedia();
    RTCPeerConnection connection = await createPeerConnection({
      ...peerConnectionConfig,
      ...{'sdpSemantics': sdpSemantics}
    }, _config);

    switch (sdpSemantics) {
      case 'plan-b':
        await connection.addStream(localeStream!);
        break;
      case 'unified-plan':
        localeStream!.getTracks().forEach((track) async {
          connection.addTrack(track, localeStream!);
        });
        break;
    }

    connection.onIceCandidate = (candidate) {
      print('candidate is ${candidate.toMap()}');
      signalR.sendMessage('sendSignal', args: [
        jsonEncode({"candidate": candidate.toMap()}),
        userId.toString()
      ]);
    };

    connection.onRemoveTrack = (stream, track) {
      print('new onRemoveTrack');
    };
    connection.onAddTrack = (stream, track) {
      print('new onAddTrack state');
    };

    connection.onRemoveStream = (MediaStream stream) {
      print('new --stream--     removed!');
    };

    connection.onAddStream = (MediaStream stream) {
      print('new --stream--     Added!');
    };

    connection.onIceConnectionState = (RTCIceConnectionState state) {
      print('new ice state is $state');
    };

    connection.onSignalingState = (state) {
      print('new signaling state is $state');
    };

    connection.onIceGatheringState = (state) {
      print('new IceGathering state is $state');
    };

    connections[userId] =
        connection; // Store away the connection based on username
    return connection;
  }

  Future<void> cleanSessions() async {
    if (localeStream != null) {
      localeStream!.getTracks().forEach((element) async {
        await element.stop();
      });
      await localeStream!.dispose();
      localeStream = null;
    }
  }

  void muteMic() {
    if (localeStream != null) {
      bool enabled = localeStream!.getAudioTracks()[0].enabled;
      localeStream!.getAudioTracks()[0].enabled = !enabled;
    }
  }

  bool get isMute => localeStream?.getAudioTracks()[0].enabled ?? false;

  void newSignal(userId, signal) async {
    var connection = await getConnection(userId);
    var c = signal["candidate"];
    var s = signal["sdp"];
    if (c != null) {
      receivedCandidateSignal(connection, userId, c);
    }
    if (s != null) {
      receivedSdpSignal(connection, userId, s['sdp'], s['type']);
    }
  }

  void closeConnection(userId) {
    var connection = connections[userId];
    connection?.close();
    removeConnection(connection);
  }

  void removeConnection(RTCPeerConnection? connection) {
    connections.removeWhere(
      (key, value) =>
          value.iceGatheringState?.index ==
          connection?.iceGatheringState?.index,
    );
  }

  @override
  void onAccept(data) {
    if (data == null && data!.isEmpty) return;
    var signalingUser = (data.first as dynamic);

    initOffer(signalingUser['userId'], localeStream);
  }

  @override
  void onCallEnd(data) {
    if (data == null && data!.isEmpty) return;
    var signalingUser = (data.first as dynamic);
    closeConnection(signalingUser['userId']);
    cleanSessions();
  }

  @override
  void onDeclined(data) {
    // print(arguments);
    // _controller?.close();
  }

  @override
  void onNewCall(data) {}

  @override
  void onNewSignal(data) {
    if (data == null && data!.isEmpty) return;
    var signalingUser = (data.first as dynamic);
    var signal = data[1];
    newSignal(signalingUser['userId'], jsonDecode(signal as String));
  }

  @override
  void onNewState(data) async {
    HubConnectionState event = data;
    if (event == HubConnectionState.Connected) {
      print('joining by this data ${user?.toMap()}');
      var status = await signalR.sendMessage("Join", args: [user!.toMap()]);
      if(status != null && status is bool && status == true) {
        signalR.updateListeners((callBack) => callBack.onJoined(status));
      }
    }
  }

  @override
  void onNewUserList(data) {
    print(data);
  }

  bool get isConnected => signalR.isConnected;

  HubConnectionState get state =>
      signalR.hubConnection?.state ?? HubConnectionState.Disconnected;

  void closeAllConnection() {
    connections.forEach((key, connection) async {
      await connection.close();
      removeConnection(connection);
    });
    cleanSessions();
  }

  void turnSpeaker(bool on) {
    if (!kIsWeb) {
      localeStream?.getAudioTracks()[0].enableSpeakerphone(on);
    }
  }

  @override
  void onConnected(data) {
    //
  }

  @override
  void onJoined(data) {
    //
  }
}
