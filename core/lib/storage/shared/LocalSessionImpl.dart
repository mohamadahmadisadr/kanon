import 'package:core/storage/LocalSession.dart';
import 'package:core/storage/LocalSessionRepository.dart';
import 'package:core/storage/other/other_localSession_impl.dart'
    if (dart.library.html) 'package:core/storage/web/web_localSession_impl.dart';

class LocalSessionImpl extends LocalSessionRepository {
  final LocalSessionRepository sessionImpl = getLocalSession();

  @override
  Future<bool> clearSession() {
    return sessionImpl.clearSession();
  }

  @override
  Future<String> getData(String key) {
    return sessionImpl.getData(key);
  }

  @override
  Future<void> insertData(Map<String, String> data) {
    return sessionImpl.insertData(data);
  }
}
