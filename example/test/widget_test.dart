import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:example/main.dart';
import 'package:example/app_info_model.dart';
import 'package:example/get_app_info.dart';

// Mock class for GetAppInfo
class MockGetAppInfo extends Mock implements GetAppInfo {}

void main() {
  testWidgets('App displays version correctly', (WidgetTester tester) async {
    // Create a mock AppInfoModel
    const mockAppInfo = AppInfoModel(appVersion: '1.0.0');

    // Mock the GetAppInfo.details() method to return the mockAppInfo
    when(GetAppInfo.details()).thenAnswer((_) async => mockAppInfo);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(info: mockAppInfo));

    // Verify that the app title is displayed correctly
    expect(find.text('Custom build tool Example'), findsOneWidget);

    // Verify that the app version is displayed correctly
    expect(find.text('1.0.0'), findsOneWidget);
  });
}
