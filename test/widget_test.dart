import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_generator/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('receipt studio renders workspace shell', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ReceiptStudioApp());
    await tester.pumpAndSettle();

    expect(find.text('Receipt Studio'), findsAtLeastNWidgets(1));
    expect(find.text('Save to App'), findsOneWidget);
    expect(find.text('Workspace'), findsAtLeastNWidgets(1));
    expect(find.text('Receipt Vault'), findsAtLeastNWidgets(1));
    expect(find.text('Templates'), findsAtLeastNWidgets(1));
    expect(find.text('Import Workspace'), findsOneWidget);
    expect(find.text('Export Workspace'), findsOneWidget);
  });
}
