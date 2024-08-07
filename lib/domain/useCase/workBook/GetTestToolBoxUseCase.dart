import 'package:kanooniha/common/network/WorkBookApiRoutes.dart';
import 'package:kanooniha/domain/useCase/BaseUseCase.dart';

import '../../../common/user/UserSessionConst.dart';
import '../../../data/body/UserIdInputBody.dart';
import '../../../data/serializer/toolBox/GetTestToolBoxResponse.dart';

class GetTestToolBoxUseCase extends BaseUseCase {

  void getByTestDate({
    required int testDate,
    required MyFlow<AppState> flow,
  }) async {
    try {
      flow.emit(AppState.loading);

      var userId =
          UserIdInputBody(userId: await session.getData(UserSessionConst.id));
      var map = userId.toJson();
      map['testDate'] = testDate.toString();
      Uri uri = UriCreator.createUri(
          path: WorkBookApiRoutes.getTestToolBox, body: map);
      Logger.d(map);
      var response = await apiServiceImpl.post(uri);
      Logger.d(response.statusCode);
      if (response.isSuccessful) {
        var examDetail = getTestToolBoxResponseFromJson(response.body);
        if (examDetail.status == 1 && examDetail.data?.state == 1) {
          flow.emit(AppState.success(examDetail));
        } else {
          flow.emit(
            AppState.error(
              ErrorModel(
                state: ErrorState.Message,
                message: examDetail.data?.message ?? '',
              ),
            ),
          );
        }
      } else {
        flow.emit(
          AppState.error(
            ErrorHandlerImpl().makeError(response),
          ),
        );
      }
    } catch (e) {
      Logger.e(e);
      flow.emit(
        AppState.error(
          const ErrorModel(
            state: ErrorState.Message,
            message: ErrorMessages.ErrorMessage_Connection,
          ),
        ),
      );
    }
  }

  @override
  void invoke({MyFlow<AppState>? flow, Object? data}) async {}
}
