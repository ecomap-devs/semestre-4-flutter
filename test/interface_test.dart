import 'package:ecomapbrasil/screens/animais_screen.dart';
import 'package:ecomapbrasil/theme/app_theme.dart';
import 'package:ecomapbrasil/widgets/abertura.dart';
import 'package:ecomapbrasil/widgets/animacao_na_tela.dart';
import 'package:ecomapbrasil/widgets/charts/mapa_biomas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abertura navega e permite escolher outra foto', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var mapas = 0;
    var especies = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Abertura(
              aoAbrirMapa: () => mapas++,
              aoVerEspecies: () => especies++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Onça-pintada'), findsOneWidget);

    await tester.tap(find.text('Abrir o mapa'));
    await tester.tap(find.text('Espécies ameaçadas'));
    expect(mapas, 1);
    expect(especies, 1);

    await tester.tap(find.bySemanticsLabel('Mostrar Arara-azul-de-lear'));
    await tester.pump();
    expect(find.text('Arara-azul-de-lear'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abertura troca de foto sozinha a cada 6 segundos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: Scaffold(
          body: Abertura(aoAbrirMapa: () {}, aoVerEspecies: () {}),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Onça-pintada'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 6100));
    await tester.pump();
    expect(find.text('Arara-azul-de-lear'), findsOneWidget);
    // Desmonta antes do fim: o relogio da abertura nunca para sozinho.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('abertura cabe em celular, sem trocar sozinha com movimento '
      'reduzido', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            disableAnimations: true,
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Abertura(aoAbrirMapa: () {}, aoVerEspecies: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Onça-pintada'), findsOneWidget);
    // Nada agendado: sem animacao, a abertura fica parada.
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('busca do catálogo ignora acento, acha por bioma e limpa', (
    tester,
  ) async {
    // Tamanho de celular pelo `view`: o `setSurfaceSize` nao muda o
    // MediaQuery, e a tela se achava no computador.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: const Scaffold(body: AnimaisScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // A busca fica abaixo da abertura, como no site: rola ate ela.
    await tester.scrollUntilVisible(
      find.byType(TextField),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.enterText(find.byType(TextField), 'onca');
    await tester.pumpAndSettle();
    expect(find.text('Onça-pintada'), findsOneWidget);
    expect(find.text('Arara-azul-de-lear'), findsNothing);

    await tester.enterText(find.byType(TextField), 'caatinga');
    await tester.pumpAndSettle();
    expect(find.text('Arara-azul-de-lear'), findsOneWidget);
    expect(find.text('Onça-pintada'), findsNothing);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Só ameaçadas" deixa de fora as não ameaçadas', (tester) async {
    // No computador, onde o seletor de status fica sempre a vista.
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: const Scaffold(body: AnimaisScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Qualquer status'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('45 espécies'), findsOneWidget);

    await tester.tap(find.text('Qualquer status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Só ameaçadas').last);
    await tester.pumpAndSettle();
    expect(find.text('27 espécies'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catálogo sem resultado oferece limpar a busca', (tester) async {
    // Tamanho de celular pelo `view`: o `setSurfaceSize` nao muda o
    // MediaQuery, e a tela se achava no computador.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: const Scaffold(body: AnimaisScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextField),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.enterText(find.byType(TextField), 'dinossauro');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Limpar a busca e os filtros'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Nenhuma espécie encontrada com esses filtros.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Limpar a busca e os filtros'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhuma espécie encontrada com esses filtros.'),
      findsNothing,
    );
  });

  testWidgets('mapa dos biomas mostra o desmatamento do bioma escolhido', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: const Scaffold(body: SingleChildScrollView(child: MapaBiomas())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Toque num bioma'), findsOneWidget);

    await tester.tap(find.text('Cerrado'));
    await tester.pump();
    expect(find.text('53%'), findsOneWidget);
    expect(find.textContaining('do Cerrado', findRichText: true), findsOne);

    await tester.tap(find.text('Amazônia'));
    await tester.pump();
    expect(find.text('20%'), findsOneWidget);
    expect(find.textContaining('da Amazônia', findRichText: true), findsOne);
  });

  testWidgets('tocar no desenho escolhe o bioma sob o dedo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: const Scaffold(
          body: Align(alignment: Alignment.topLeft, child: MapaBiomas()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // O noroeste do desenho e Amazonia em qualquer escala.
    final desenho = tester.getRect(
      find.descendant(
        of: find.byType(AspectRatio),
        matching: find.byType(CustomPaint),
      ),
    );
    await tester.tapAt(
      desenho.topLeft + Offset(desenho.width * .3, desenho.height * .3),
    );
    await tester.pump();
    expect(find.text('20%'), findsOneWidget);
  });

  group('textoContado', () {
    test('mantém o texto em volta do número', () {
      expect(textoContado('+30%', 1), '+30%');
      expect(textoContado('+30%', 0), '+0%');
      expect(textoContado('6 biomas', .5), '3 biomas');
    });

    test('preserva vírgula decimal e ponto de milhar', () {
      expect(textoContado('1,5 mi ha', 1), '1,5 mi ha');
      expect(textoContado('1,5 mi ha', 0), '0,0 mi ha');
      expect(textoContado('1.173', 1), '1.173');
      expect(textoContado('1.173', .5), '587');
      expect(textoContado('12.500', .5), '6.250');
    });

    test('texto sem número volta igual', () {
      expect(textoContado('muitos', .3), 'muitos');
    });
  });

  group('normalizarBusca', () {
    test('tira acento e caixa', () {
      expect(normalizarBusca('Onça-pintada'), 'onca-pintada');
      expect(normalizarBusca('Mata Atlântica'), 'mata atlantica');
      expect(normalizarBusca('Tamanduá'), 'tamandua');
    });
  });
}
