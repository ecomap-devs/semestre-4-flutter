import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/data/animais_data.dart';
import 'package:ecomapbrasil/data/home_data.dart';
import 'package:ecomapbrasil/screens/animais_screen.dart';
import 'package:ecomapbrasil/screens/mapa_screen.dart';
import 'package:ecomapbrasil/theme/app_theme.dart';
import 'package:ecomapbrasil/widgets/abertura.dart';
import 'package:ecomapbrasil/widgets/deslizar_para_fechar.dart';

/// Tamanho de celular pelo `view`: o `setSurfaceSize` nao muda o MediaQuery.
void _celular(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

void main() {
  // Gestos de deslizar no app (11/11/2026): carrossel da Home, ficha da
  // especie, fichas do Mapa e a legenda dos alertas, que antes nem fechava.

  group('DeslizarParaFechar', () {
    Future<List<int>> montar(
      WidgetTester tester, {
      bool paraBaixo = true,
    }) async {
      final fechou = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: DeslizarParaFechar(
                  aoFechar: () => fechou.add(1),
                  paraBaixo: paraBaixo,
                  child: const ColoredBox(
                    color: Colors.white,
                    child: Center(child: Text('cartão')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return fechou;
    }

    Offset deslocamento(WidgetTester tester) {
      final t = tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(DeslizarParaFechar),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .getTranslation();
      return Offset(t.x, t.y);
    }

    testWidgets('para o lado, além do limite: fecha', (tester) async {
      final fechou = await montar(tester);
      await tester.drag(find.text('cartão'), const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(fechou, [1]);
    });

    testWidgets('arrasto curto e lento: volta ao lugar', (tester) async {
      final fechou = await montar(tester);
      await tester.timedDrag(
        find.text('cartão'),
        const Offset(40, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      expect(fechou, isEmpty);
      expect(deslocamento(tester), Offset.zero);
    });

    testWidgets('jogado rápido para baixo: fecha mesmo curto', (tester) async {
      final fechou = await montar(tester);
      await tester.fling(find.text('cartão'), const Offset(0, 60), 1500);
      await tester.pumpAndSettle();
      expect(fechou, [1]);
    });

    testWidgets('para cima não fecha', (tester) async {
      final fechou = await montar(tester);
      await tester.fling(find.text('cartão'), const Offset(0, -150), 1500);
      await tester.pumpAndSettle();
      expect(fechou, isEmpty);
    });

    testWidgets('sem "para baixo", o arrasto vertical não faz nada', (
      tester,
    ) async {
      final fechou = await montar(tester, paraBaixo: false);
      await tester.fling(find.text('cartão'), const Offset(0, 150), 1500);
      await tester.pumpAndSettle();
      expect(fechou, isEmpty);
      expect(deslocamento(tester), Offset.zero);
    });
  });

  group('carrossel da Home', () {
    Future<void> montar(WidgetTester tester) async {
      _celular(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTema(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Abertura(aoAbrirMapa: () {}, aoVerEspecies: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('deslizar para a esquerda traz a próxima foto, e para a '
        'direita, a anterior', (tester) async {
      await montar(tester);
      expect(find.text(slides[0].rotulo), findsOneWidget);

      await tester.fling(find.byType(Abertura), const Offset(-150, 0), 1000);
      await tester.pump();
      expect(find.text(slides[1].rotulo), findsOneWidget);

      await tester.fling(find.byType(Abertura), const Offset(150, 0), 1000);
      await tester.pump();
      expect(find.text(slides[0].rotulo), findsOneWidget);

      // Da primeira, para a direita, vai para a ultima.
      await tester.fling(find.byType(Abertura), const Offset(150, 0), 1000);
      await tester.pump();
      expect(find.text(slides.last.rotulo), findsOneWidget);
      // O relogio da abertura nunca para sozinho.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('um arrasto curto e lento não troca a foto', (tester) async {
      await montar(tester);
      await tester.timedDrag(
        find.byType(Abertura),
        const Offset(-30, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pump();
      expect(find.text(slides[0].rotulo), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('ficha da espécie', () {
    Finder naFicha(Finder f) =>
        find.descendant(of: find.byType(BottomSheet), matching: f);

    Future<void> abrirAPrimeira(WidgetTester tester) async {
      _celular(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTema(),
          home: const Scaffold(body: AnimaisScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // No meio da tela: no topo, o cabeçalho fixo da busca cobriria o cartão.
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
      expect(naFicha(find.text(animais[0].nome)), findsOneWidget);
    }

    testWidgets('deslizar passa para a vizinha da lista', (tester) async {
      await abrirAPrimeira(tester);

      await tester.fling(find.byType(BottomSheet), const Offset(-200, 0), 1000);
      await tester.pumpAndSettle();
      expect(naFicha(find.text(animais[1].nome)), findsOneWidget);

      await tester.fling(find.byType(BottomSheet), const Offset(200, 0), 1000);
      await tester.pumpAndSettle();
      expect(naFicha(find.text(animais[0].nome)), findsOneWidget);
    });

    testWidgets('as setas fazem o mesmo, sem passar da primeira', (
      tester,
    ) async {
      await abrirAPrimeira(tester);
      // Na primeira, nao ha anterior: nem seta, nem deslizar.
      expect(find.byTooltip('Espécie anterior'), findsNothing);
      await tester.fling(find.byType(BottomSheet), const Offset(200, 0), 1000);
      await tester.pumpAndSettle();
      expect(naFicha(find.text(animais[0].nome)), findsOneWidget);

      await tester.tap(find.byTooltip('Próxima espécie'));
      await tester.pumpAndSettle();
      expect(naFicha(find.text(animais[1].nome)), findsOneWidget);
      await tester.tap(find.byTooltip('Espécie anterior'));
      await tester.pumpAndSettle();
      expect(naFicha(find.text(animais[0].nome)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Mapa', () {
    Future<void> montar(WidgetTester tester) async {
      _celular(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTema(),
          home: const Scaffold(body: MapaScreen()),
        ),
      );
      await tester.pump();
    }

    final legenda = find.text('Alertas de desmatamento');

    testWidgets('a legenda fecha pelo X e volta pelo botão "Legenda"', (
      tester,
    ) async {
      await montar(tester);
      expect(legenda, findsOneWidget);
      expect(find.text('Legenda'), findsNothing);

      await tester.tap(find.byTooltip('Fechar legenda'));
      await tester.pump();
      expect(legenda, findsNothing);

      await tester.tap(find.text('Legenda'));
      await tester.pump();
      expect(legenda, findsOneWidget);
    });

    testWidgets('a legenda fecha deslizando para o lado', (tester) async {
      await montar(tester);
      await tester.fling(legenda, const Offset(-200, 0), 1500);
      await tester.pumpAndSettle();
      expect(legenda, findsNothing);
      expect(find.text('Legenda'), findsOneWidget);
    });

    testWidgets('o cartão do bioma fecha deslizando, e a legenda volta', (
      tester,
    ) async {
      await montar(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Biomas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrado').last);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Fechar'), findsOneWidget);
      expect(legenda, findsNothing);

      await tester.fling(find.byTooltip('Fechar'), const Offset(200, 0), 1500);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Fechar'), findsNothing);
      expect(legenda, findsOneWidget);
    });

    testWidgets('o painel Biomas fecha arrastando para baixo', (tester) async {
      await montar(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Biomas'));
      await tester.pumpAndSettle();
      // Com o painel aberto, o botao que o abre some.
      expect(find.widgetWithText(FilledButton, 'Biomas'), findsNothing);

      await tester.fling(
        find.bySemanticsLabel('Fechar painel'),
        const Offset(0, 150),
        1500,
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Biomas'), findsOneWidget);
    });

    testWidgets('o painel volta ao lugar com um arrasto curto e lento', (
      tester,
    ) async {
      await montar(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Biomas'));
      await tester.pumpAndSettle();
      await tester.timedDrag(
        find.bySemanticsLabel('Fechar painel'),
        const Offset(0, 30),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Biomas'), findsNothing);
      final slide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
      expect(slide.offset, Offset.zero);
    });
  });
}
