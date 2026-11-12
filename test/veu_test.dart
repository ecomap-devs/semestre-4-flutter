import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/data/animais_data.dart';
import 'package:ecomapbrasil/screens/animais_screen.dart';
import 'package:ecomapbrasil/services/auth_service.dart';
import 'package:ecomapbrasil/theme/app_theme.dart';
import 'package:ecomapbrasil/widgets/apagar_conta_dialog.dart';
import 'package:ecomapbrasil/widgets/auth_modal.dart';

/// Só abre os diálogos: nenhum teste aqui chega a falar com o Firebase.
class _Auth extends Fake implements AuthService {}

/// Tamanho de celular pelo `view`: o `setSurfaceSize` nao muda o MediaQuery.
void _celular(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

/// A cor do véu atrás do diálogo ou da ficha aberta (o último `ModalBarrier`).
Color corDoVeu(WidgetTester tester) {
  final barreiras = tester.widgetList<ModalBarrier>(find.byType(ModalBarrier));
  return barreiras.last.color!;
}

Widget _app(ThemeMode modo, Widget home) => MaterialApp(
  theme: construirTema(),
  darkTheme: construirTema(escuro: true),
  themeMode: modo,
  home: home,
);

/// Um botão que abre o diálogo pedido.
Widget _botao(void Function(BuildContext) abrir) => Scaffold(
  body: Builder(
    builder: (context) =>
        TextButton(onPressed: () => abrir(context), child: const Text('abrir')),
  ),
);

void main() {
  // Até 12/11/2026 o véu atrás de diálogo e ficha era a tinta do tema com
  // 55%: no escuro, a tinta é quase branca, e a tela ficava coberta por um véu
  // claro. Agora é o `AppCores.veu`, escuro nos dois temas, como no site.

  for (final modo in [ThemeMode.light, ThemeMode.dark]) {
    final nome = modo == ThemeMode.dark ? 'escuro' : 'claro';

    testWidgets('véu do login escuro no tema $nome', (tester) async {
      await tester.pumpWidget(
        _app(modo, _botao((c) => AuthModal.abrir(c, _Auth()))),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthModal), findsOneWidget);
      expect(corDoVeu(tester), AppCores.veu);
    });

    testWidgets('véu de apagar conta escuro no tema $nome', (tester) async {
      await tester.pumpWidget(
        _app(modo, _botao((c) => ApagarContaDialog.abrir(c, _Auth()))),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(ApagarContaDialog), findsOneWidget);
      expect(corDoVeu(tester), AppCores.veu);
    });

    testWidgets('véu da ficha da espécie escuro no tema $nome', (tester) async {
      _celular(tester);
      await tester.pumpWidget(
        _app(modo, const Scaffold(body: AnimaisScreen())),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(animais[0].nome),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text(animais[0].nome)),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(animais[0].nome));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(corDoVeu(tester), AppCores.veu);
    });
  }

  test('o véu é escuro: o texto claro do tema escuro aparece sobre ele', () {
    expect(AppCores.veu.computeLuminance(), lessThan(0.05));
    expect(AppCores.veu.a, closeTo(0.55, 0.01));
  });
}
