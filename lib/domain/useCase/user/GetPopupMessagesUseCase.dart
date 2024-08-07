import 'package:kanooniha/domain/useCase/BaseUseCase.dart';

import '../../../common/network/userApiRoutes.dart';
import '../../../common/user/UserSessionConst.dart';
import '../../../data/body/UserIdInputBody.dart';
import '../../../data/body/gift/GetPopupMessagesResponse.dart';

class GetPopupMessagesUseCase extends BaseUseCase {

  @override
  void invoke({MyFlow<AppState>? flow, Object? data}) async {
    try {
      flow?.emit(AppState.loading);
      var userId =
          UserIdInputBody(userId: await session.getData(UserSessionConst.id));
      Uri uri = UriCreator.createUri(
          path: UserApiRoutes.getPopupMessages, body: userId.toJson());
      var response = await apiServiceImpl.post(uri);
      Logger.d(response.statusCode);
      Logger.d(response.body);
      if (response.isSuccessful) {
        Logger.d(response.body);
        var giftResponse = getPopupMessagesResponseFromJson(response.body);
        if (giftResponse.status == 1 &&
            giftResponse.data?.state == 1 &&
            giftResponse.data?.popupMessage != null) {
          session.insertData({UserSessionConst.hasMessage: "1"});
          flow?.emit(AppState.success(giftResponse));
        } else {
          flow?.emit(
            AppState.error(
              ErrorModel(
                state: ErrorState.Message,
                message: giftResponse.data?.message ?? '',
              ),
            ),
          );
        }
      } else {
        flow?.emit(
          AppState.error(
            ErrorHandlerImpl().makeError(response),
          ),
        );
      }
    } catch (e) {
      Logger.e(e);
      flow?.emit(
        AppState.error(
          const ErrorModel(
            state: ErrorState.Message,
            message: ErrorMessages.ErrorMessage_Connection,
          ),
        ),
      );
    }
  }
}