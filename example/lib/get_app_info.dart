import 'package:example/app_info_model.dart';
import 'package:package_info_plus/package_info_plus.dart';

class GetAppInfo {
  static Future<AppInfoModel> details() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    String code = packageInfo.buildNumber;
    return AppInfoModel(
      appBuildNumber: int.parse(code),
      appVersion: version,
    );
  }
}
