import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecomapbrasil/services/preferencia_de_tema.dart';
import 'package:ecomapbrasil/theme/app_theme.dart';
import 'package:ecomapbrasil/widgets/botao_de_tema.dart';

/// O mesmo arranjo do `EcoMapApp`, sem o Firebase da `AppShell`.
Widget _app(PreferenciaDeTema tema) => ValueListenableBuilder<ThemeMode>(
  valueListenable: tema,
  builder: (context, modo, _) => MaterialApp(
    theme: construirTema(),
    darkTheme: construirTema(escuro: true),
    themeMode: modo,
    home: Scaffold(
      appBar: AppBar(actions: [BotaoDeTema(tema: tema)]),
    ),
  ),
);

Brightness _brilho(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(BotaoDeTema))).brightness;

void main() {
  group('Preferência de tema', () {
    test('sem nada guardado, segue o sistema', () async {
      SharedPreferences.setMockInitialValues({});
      expect((await PreferenciaDeTema.carregar()).value, ThemeMode.system);
    });

    test('valor estranho guardado também segue o sistema', () async {
      SharedPreferences.setMockInitialValues({PreferenciaDeTema.chave: 'x'});
      expect((await PreferenciaDeTema.carregar()).value, ThemeMode.system);
    });

    test('a escolha fica guardada para a próxima abertura', () async {
      SharedPreferences.setMockInitialValues({});
      final tema = await PreferenciaDeTema.carregar();
      await tema.escolher(ThemeMode.dark);
      expect((await PreferenciaDeTema.carregar()).value, ThemeMode.dark);
      await tema.escolher(ThemeMode.light);
      expect((await PreferenciaDeTema.carregar()).value, ThemeMode.light);
    });
  });

  group('Botão de tema', () {
    testWidgets('escolher Escuro e depois Claro troca o app na hora', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final tema = PreferenciaDeTema();
      await tester.pumpWidget(_app(tema));
      // O sistema dos testes está no claro.
      expect(_brilho(tester), Brightness.light);
      expect(find.byTooltip('Tema: Seguir o sistema'), findsOneWidget);

      await tester.tap(find.byType(BotaoDeTema));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escuro'));
      await tester.pumpAndSettle();
      expect(_brilho(tester), Brightness.dark);
      expect(find.byTooltip('Tema: Escuro'), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

      await tester.tap(find.byType(BotaoDeTema));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Claro'));
      await tester.pumpAndSettle();
      expect(_brilho(tester), Brightness.light);
      expect(tema.value, ThemeMode.light);
    });

    testWidgets('Seguir o sistema volta a obedecer o celular', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final tema = PreferenciaDeTema(ThemeMode.light);
      await tester.pumpWidget(_app(tema));
      expect(_brilho(tester), Brightness.light);

      await tester.tap(find.byType(BotaoDeTema));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seguir o sistema'));
      await tester.pumpAndSettle();
      expect(_brilho(tester), Brightness.dark);
    });

    testWidgets('o botão tem 48 dp de toque', (tester) async {
      await tester.pumpWidget(_app(PreferenciaDeTema()));
      final tamanho = tester.getSize(find.byType(IconButton));
      expect(tamanho.width, greaterThanOrEqualTo(48));
      expect(tamanho.height, greaterThanOrEqualTo(48));
    });
  });
}
