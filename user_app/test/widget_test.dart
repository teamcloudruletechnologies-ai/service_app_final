import 'package:flutter_test/flutter_test.dart';
import 'package:urban_service_user/main.dart';
import 'package:urban_service_user/services/api_service.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    final apiService = ApiService();
    await tester.pumpWidget(UrbanServiceApp(apiService: apiService));
  });
}
