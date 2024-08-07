import 'package:core/storage/shared/LocalSessionImpl.dart';
import 'package:kanooniha/domain/useCase/BaseUseCase.dart';

import '../../../common/network/BooksApiRoutes.dart';
import '../../../common/user/UserSessionConst.dart';
import '../../../data/body/book/CreateEBookFactorBody.dart';
import '../../../data/serializer/book/CreateEBookFactorResponse.dart';

class CreateEBookFactorUseCase extends BaseUseCase {
  LocalSessionImpl session = GetIt.I.get<LocalSessionImpl>();

  void createLink({required MyFlow<AppState> flow, required int BookId}) async {
    try {
      flow.emit(AppState.loading);

      var createEBookFactor = CreateEBookFactorBody(
        userId: await session.getData(UserSessionConst.id),
        bookId: BookId.toString(),
      );
      Uri uri = UriCreator.createUri(
          path: BooksApiRoutes.createEBookFactor,
          body: createEBookFactor.toJson());
      Logger.d(createEBookFactor.toJson());
      var response = await apiServiceImpl.post(uri);
      Logger.d(response.statusCode);
      if (response.isSuccessful) {
        var examDetail = createEBookFactorResponseFromJson(response.body);
        if (examDetail.status == 1 && examDetail.data?.status == 1) {
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
            ErrorHandlerImpl().makeErrorByStatusCode(response.statusCode),
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