class AppInfoModel {
  final int? appBuildNumber;
  final String? appVersion;

  const AppInfoModel({
    this.appBuildNumber,
    this.appVersion,
  });

  factory AppInfoModel.fromJson(Map<String, dynamic> json) => AppInfoModel(
        appBuildNumber: json["build_number"],
        appVersion: json["version"],
      );

  Map<String, dynamic> toJson() => {
        "build_number": appBuildNumber,
        "version": appVersion,
      };
}
