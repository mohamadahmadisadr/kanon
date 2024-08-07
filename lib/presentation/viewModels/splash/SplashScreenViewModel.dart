import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:kanooniha/common/appCommons/appRoutes.dart';
import 'package:kanooniha/common/imports/appImports.dart';
import 'package:kanooniha/common/user/UserSessionConst.dart';
import 'package:kanooniha/core/app/firebase_api.dart';
import 'package:kanooniha/core/navigationService/NavigationService.dart';
import 'package:kanooniha/data/bases/baseViewModel.dart';
import 'package:kanooniha/data/serializer/update/VersionCheckSerializer.dart';
import 'package:kanooniha/domain/useCase/app/refresh_token_interceptor_use_case.dart';
import 'package:kanooniha/domain/useCase/update/VersionCheckUseCase.dart';
import 'package:kanooniha/presentation/ui/dialog/UpdateDialog.dart';

import '../../../data/body/gift/GetPopupMessagesResponse.dart';
import '../../../domain/useCase/user/GetPopupMessagesUseCase.dart';
import '../../ui/dialog/GiftMessageDialogUI.dart';

class SplashScreenViewModel extends BaseViewModel {
  var navigationService = GetIt.I.get<NavigationServiceImpl>();
  final _getPopupMessagesUseCase = GetPopupMessagesUseCase();

  SplashScreenViewModel(super.initialState) {
    if (!kIsWeb) {
      checkForUpdate();
    }else{
      checkUserSession();
    }
  }

  void getGiftMessages() {
    _getPopupMessagesUseCase.invoke(flow: MyFlow((appState) {
      updateState(appState);
      if (appState.isSuccess && appState.getData is GetPopupMessagesResponse) {
        var popMsg =
            (appState.getData as GetPopupMessagesResponse).data?.popupMessage;
        Get.dialog(GiftMessageDialogUI(message: popMsg!),
            barrierDismissible: false);
      } else if (appState.isFailed) {
        navigationService.replaceTo(AppRoutes.home);
      }
    }));
  }

  void checkForUpdate() {
    VersionCheckUseCase().invoke(flow: MyFlow((appState) {
      if (appState.isSuccess && appState.getData is VersionCheckSerializer) {
        VersionCheckSerializer data = appState.getData;
        if (data.link != '') {
          Get.dialog(
              UpdateDialog(
                  link: data.link ?? '', force: data.isForceUpdate == true),
              barrierDismissible: data.isForceUpdate == false);
        }
      }
      if (!appState.isLoading && !appState.isSuccess) {
        checkUserSession();
      }
    }));
  }

  void checkUserSession() {
    session.getData(UserSessionConst.hasMessage).then((value) {
      if (value == "1") {
        getGiftMessages();
      } else {
        Future.delayed(const Duration(seconds: 3)).then((value) {
          session.getData(UserSessionConst.token).then((token) async {
            if (token.isNotEmpty) {
              await RefreshTokenInterceptorUseCase().invoke();
              await FireBaseApi().updateFireBaseToken();
              navigationService.replaceTo(AppRoutes.home);
            } else {
              navigationService.replaceTo(AppRoutes.login);
            }
          });
        });
      }
    });
  }

  @override
  String pageName() => 'splash';

  @override
  logEvent() {
    logOnFireBase(pageName());
  }

  @override
  onReloadClick() {
    if (!kIsWeb) {
      checkForUpdate();
    }else{
      checkUserSession();
    }
  }
}
