
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/input_url_screen.dart';
import 'package:myapp/main.dart';
import 'package:myapp/scanner_screen.dart';

void main() {
  testWidgets('Full App Navigation and UI Flow Test', (WidgetTester tester) async {
    // 1. Build the app and verify the initial state.
    await tester.pumpWidget(const MyApp());

    // Verify that the initial screen shows the "Aktifkan Mode Ujian" button
    // and nothing else.
    expect(find.text('Aktifkan Mode Ujian'), findsOneWidget, reason: 'Initial screen should have the activate button');
    expect(find.text('Menu Utama'), findsNothing, reason: 'Main menu button should not be visible initially');
    expect(find.byIcon(Icons.qr_code_scanner), findsNothing, reason: 'Scan QR button should not be visible initially');
    expect(find.byIcon(Icons.link), findsNothing, reason: 'Input URL button should not be visible initially');

    // 2. Tap the "Aktifkan Mode Ujian" button and verify the UI change.
    await tester.tap(find.text('Aktifkan Mode Ujian'));
    await tester.pumpAndSettle(); // pumpAndSettle to allow for state changes and animations

    // Verify that the "Menu Utama" button is now visible.
    expect(find.text('Aktifkan Mode Ujian'), findsNothing, reason: 'Activate button should disappear after tap');
    expect(find.text('Menu Utama'), findsOneWidget, reason: 'Main menu button should appear after activation');

    // 3. Tap the "Menu Utama" button and verify the main menu options appear.
    await tester.tap(find.text('Menu Utama'));
    await tester.pumpAndSettle();

    // Verify that the main menu buttons are now visible.
    expect(find.text('Menu Utama'), findsNothing, reason: 'Main menu button should disappear after tap');
    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget, reason: 'Scan QR icon should be visible');
    expect(find.byIcon(Icons.link), findsOneWidget, reason: 'Input URL icon should be visible');
    expect(find.byIcon(Icons.exit_to_app), findsOneWidget, reason: 'Exit icon should be visible');
    
    // 4. Test navigation to the "Masukan URL" screen.
    await tester.tap(find.byIcon(Icons.link));
    await tester.pumpAndSettle();

    // Verify that the app navigated to the InputUrlScreen.
    expect(find.byType(InputUrlScreen), findsOneWidget, reason: 'Should navigate to InputUrlScreen');
    expect(find.text('Masukan URL Ujian'), findsOneWidget, reason: 'AppBar title for Input URL screen should be correct');
    expect(find.byType(TextFormField), findsOneWidget, reason: 'InputUrlScreen should have a text form field');

    // 5. Go back to the main menu.
    Navigator.of(tester.element(find.byType(InputUrlScreen))).pop();
    await tester.pumpAndSettle();

    // Verify we are back at the main menu.
    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget, reason: 'Should return to the main menu');

    // 6. Test navigation to the "Scan QR" screen.
    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    await tester.pumpAndSettle();

    // Verify that the app navigated to the ScannerScreen.
    expect(find.byType(ScannerScreen), findsOneWidget, reason: 'Should navigate to ScannerScreen');
    expect(find.text('Pindai Kode QR'), findsOneWidget, reason: 'AppBar title for Scanner screen should be correct');

    // NOTE: Testing the actual camera/scanner requires more complex integration tests.
    // This test confirms navigation is working correctly.
  });
}
