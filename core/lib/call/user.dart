class User {
  final String userName, connectionId, userId, officeId;
  final String? firebaseUserToken;
  final bool isOffice, inCall;

  const User({
    required this.userName,
    required this.connectionId,
    required this.userId,
    required this.officeId,
    required this.isOffice,
    required this.inCall,
    this.firebaseUserToken,
  });

  Map<String, dynamic> toMap() {
    return {
      "UserName": userName,
      "ConnectionId": connectionId,
      "UserId": userId,
      "OfficeId": officeId,
      "IsOffice": isOffice,
      "InCall": inCall,
      "FirebaseUserToken": firebaseUserToken
    };
  }
}
