import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:proyecto_pingpong/main.dart';
import 'package:proyecto_pingpong/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App loads successfully', (WidgetTester tester) async {
    await DatabaseService().init();
    await tester.pumpWidget(const PingPongApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Control de Lanzador'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  tearDown(() async {
    await DatabaseService().close();
  });
}
