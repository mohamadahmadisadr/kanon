import 'package:kanooniha/common/network/workBook/WorkBookApiRoutes.dart';
import 'package:kanooniha/data/serializer/workBook/nextExam/DateValueNextSerializer.dart';
import 'package:kanooniha/domain/useCase/BaseUseCase.dart';

class DateValueNextUseCase extends BaseUseCase {
  @override
  void invoke({MyFlow<AppState>? flow, Object? data}) async {
    var uri = createUri(path: WorkBookApiRoutes.dateValueNext);
    var response = await tryCatch(future: apiServiceImpl.get(uri),flow: flow);
    if (response != null) {
      flow?.emitData(dateValueNextSerializerFromJson(response));
    }
  }
}
