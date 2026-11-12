import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/screens/mapa_screen.dart';
import 'package:ecomapbrasil/theme/app_theme.dart';
import 'package:ecomapbrasil/widgets/abertura.dart';

/// Pixel 8 (1080x2400 a 2,625), em pe ou deitado.
void _pixel8(WidgetTester tester, {bool deitado = false}) {
  tester.view.physicalSize = deitado
      ? const Size(2400, 1080)
      : const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

void main() {
  // Auditoria de responsividade de 11/11/2026 (v1.3.0): o celular deitado
  // ganhava o layout de tablet, e com fonte grande o credito da foto cobria
  // o botao "Especies ameacadas".

  group('Breakpoints', () {
    test('celular em pé é celular', () {
      expect(Breakpoints.ehMobileEm(const Size(411, 914)), isTrue);
    });

    test(
      'celular deitado continua celular, mesmo com mais de 768 de largura',
      () {
        expect(Breakpoints.ehMobileEm(const Size(915, 412)), isTrue);
        expect(Breakpoints.ehTabletEm(const Size(915, 412)), isFalse);
      },
    );

    test('tablet em pé e deitado não é celular', () {
      expect(Breakpoints.ehMobileEm(const Size(800, 1280)), isFalse);
      expect(Breakpoints.ehTabletEm(const Size(800, 1280)), isTrue);
      expect(Breakpoints.ehMobileEm(const Size(1280, 800)), isFalse);
      expect(Breakpoints.ehTabletEm(const Size(1280, 800)), isFalse);
    });
  });

  group('abertura da Home', () {
    Future<void> montar(WidgetTester tester, {double fonte = 1}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTema(),
          home: MediaQuery.withClampedTextScaling(
            minScaleFactor: fonte,
            maxScaleFactor: fonte,
            child: Scaffold(
              body: SingleChildScrollView(
                child: Abertura(aoAbrirMapa: () {}, aoVerEspecies: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    for (final fonte in [1.0, 1.3, 2.0]) {
      testWidgets('com fonte ${fonte}x, o crédito fica abaixo dos botões', (
        tester,
      ) async {
        _pixel8(tester);
        await montar(tester, fonte: fonte);

        final botao = tester.getRect(find.text('Espécies ameaçadas'));
        final credito = tester.getRect(
          find.textContaining('Foto:', findRichText: true),
        );
        expect(credito.top, greaterThanOrEqualTo(botao.bottom));
      });
    }

    testWidgets('celular deitado: os botões cabem na tela, sem setas', (
      tester,
    ) async {
      _pixel8(tester, deitado: true);
      await montar(tester);

      final altura = tester.view.physicalSize.height / 2.625;
      expect(
        tester.getRect(find.text('Abrir o mapa')).bottom,
        lessThan(altura),
      );
      expect(find.byTooltip('Foto anterior'), findsNothing);
    });

    testWidgets('as barras do slide têm 48 dp de altura para o toque', (
      tester,
    ) async {
      _pixel8(tester);
      await montar(tester);

      final barra = find.bySemanticsLabel(RegExp('^Mostrar '));
      expect(tester.getSize(barra.first).height, greaterThanOrEqualTo(48));
    });
  });

  group('Mapa com o celular deitado', () {
    Future<void> montar(WidgetTester tester) async {
      _pixel8(tester, deitado: true);
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTema(),
          home: const Scaffold(body: MapaScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('usa o layout de celular, com a legenda recolhida', (
      tester,
    ) async {
      await montar(tester);
      // Botão Biomas do celular, sem o painel lateral de tablet.
      expect(
        find.text('Escolha um para centralizar o mapa nele.'),
        findsNothing,
      );
      expect(find.text('Alertas de desmatamento'), findsNothing);

      await tester.tap(find.text('Legenda'));
      await tester.pump();
      expect(find.text('Alertas de desmatamento'), findsOneWidget);
    });
  });
}
