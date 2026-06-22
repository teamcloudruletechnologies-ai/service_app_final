import 'package:flutter_test/flutter_test.dart';
import 'package:urban_service_worker/main.dart';
import 'package:urban_service_worker/services/api_service.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    final apiService = ApiService();
    await tester.pumpWidget(UrbanServiceApp(apiService: apiService));
  });
}
