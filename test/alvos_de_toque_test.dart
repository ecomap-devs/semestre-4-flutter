import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/screens/animais_screen.dart';
import 'package:ecomapbrasil/screens/mapa_screen.dart';
import 'package:ecomapbrasil/theme/app_theme.dart';
import 'package:ecomapbrasil/widgets/charts/mapa_biomas.dart';
import 'package:ecomapbrasil/widgets/toque_ampliado.dart';

/// Tablet de 800x1280 dp, como o simulado na auditoria.
void _tablet(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 2560);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  // Auditoria de responsividade de 11/11/2026 (v1.3.0): alvos de toque abaixo
  // de 48 dp, nome do bioma cortado no painel e filtros cortados sem aviso.

  group('ToqueAmpliado', () {
    testWidgets('o toque na margem em volta do desenho conta', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: ToqueAmpliado(
              aoTocar: () => toques++,
              child: const SizedBox(width: 20, height: 20),
            ),
          ),
        ),
      );
      final area = tester.getRect(find.byType(ToqueAmpliado));
      expect(area.height, 48);
      expect(area.width, 48);
      // 2 dp para dentro da borda, fora do desenho de 20 dp.
      await tester.tapAt(area.topLeft + const Offset(2, 2));
      expect(toques, 1);
    });
  });

  testWidgets('filtros de Animais: 48 dp de toque e nenhum cortado', (
    tester,
  ) async {
    _tablet(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: const Scaffold(body: AnimaisScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final filtro = find.ancestor(
      of: find.text('Caatinga').first,
      matching: find.byType(ToqueAmpliado),
    );
    expect(tester.getSize(filtro.first).height, greaterThanOrEqualTo(48));

    // A fileira quebra linha em vez de rolar: todo filtro cabe na tela.
    final largura = tester.view.physicalSize.width / 2;
    for (final f in tester.widgetList<ToqueAmpliado>(
      find.byType(ToqueAmpliado),
    )) {
      final r = tester.getRect(find.byWidget(f));
      expect(r.right, lessThanOrEqualTo(largura));
    }
  });

  testWidgets('etiquetas de bioma da Home têm 48 dp de toque', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: const Scaffold(body: SingleChildScrollView(child: MapaBiomas())),
      ),
    );
    await tester.pump();
    final etiqueta = find.ancestor(
      of: find.text('Pantanal').last,
      matching: find.byType(ToqueAmpliado),
    );
    expect(tester.getSize(etiqueta).height, greaterThanOrEqualTo(48));
  });

  testWidgets('painel do Mapa no tablet mostra "Mata Atlântica" inteiro', (
    tester,
  ) async {
    _tablet(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: const Scaffold(body: MapaScreen()),
      ),
    );
    await tester.pump();

    final nome = tester.renderObject<RenderParagraph>(
      find.text('Mata Atlântica').last,
    );
    // Pode quebrar em duas linhas; o que nao pode e virar "Mata Atlan...".
    expect(nome.didExceedMaxLines, isFalse);
  });
}
