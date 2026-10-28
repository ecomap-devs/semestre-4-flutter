import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/models/avaliacao.dart';
import 'package:ecomapbrasil/screens/home_screen.dart';
import 'package:ecomapbrasil/services/reviews_service.dart';
import 'package:ecomapbrasil/theme/app_theme.dart';
import 'package:ecomapbrasil/widgets/reviews_section.dart';

/// Avaliacoes sem Firestore. Por padrao, duas fixas e o resumo delas;
/// `total` e `lidos` simulam a colecao com documentos que a lista nao mostra.
class _AvaliacoesFalsas implements ReviewsService {
  _AvaliacoesFalsas({this.quantas = 2, int? total, int? lidos})
    : total = total ?? quantas,
      lidos = lidos ?? quantas;

  final int quantas;
  final int total;
  final int lidos;

  @override
  Stream<PaginaAvaliacoes> observar({required int limite}) => Stream.value((
    avaliacoes: [
      for (var i = 0; i < quantas; i++)
        Avaliacao(
          id: '$i',
          uid: 'u$i',
          nome: i.isEven ? 'Ana' : 'Beto',
          fotoUrl: '',
          nota: i.isEven ? 5 : 4,
          comentario: i == 0 ? 'Gostei muito do mapa.' : 'Bem explicado $i.',
          criadoEm: DateTime(2026, 10, 1 + i),
        ),
    ],
    lidos: lidos,
  ));

  @override
  Future<ResumoAvaliacoes> resumo() async =>
      ResumoAvaliacoes(total: total, media: 4.5);

  @override
  Future<void> publicar({
    required User usuario,
    required int nota,
    required String comentario,
  }) async {}
}

void main() {
  // A Home inteira, de cima a baixo, em cada tamanho: nenhuma secao pode
  // estourar o layout. Sem animacao, para a abertura nao trocar sozinha e o
  // pumpAndSettle terminar.
  for (final (nome, tamanho) in [
    ('celular', const Size(390, 844)),
    ('computador', const Size(1440, 1000)),
  ]) {
    testWidgets('a Home rola inteira sem estourar no $nome', (tester) async {
      tester.view.physicalSize = tamanho * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      var mapas = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTema(),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Scaffold(
                body: HomeScreen(
                  usuario: null,
                  aoPedirLogin: () {},
                  aoAbrirMapa: () => mapas++,
                  aoAbrirAnimais: () {},
                  aoAbrirFotos: () {},
                  avaliacoes: _AvaliacoesFalsas(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('O desmatamento no Brasil', findRichText: true),
        findsOneWidget,
      );

      await tester.tap(find.text('Abrir o mapa'));
      expect(mapas, 1);

      // Rola ate o rodape, secao por secao.
      await tester.scrollUntilVisible(
        find.text('© 2025 EcoMapBrasil'),
        500,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 200,
      );
      await tester.pumpAndSettle();
      expect(find.text('Gostei muito do mapa.'), findsOneWidget);
      expect(find.text('4,5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  group('Mostrar mais', () {
    Future<void> montar(WidgetTester tester, _AvaliacoesFalsas falsas) async {
      tester.view.physicalSize = const Size(1440, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTema(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReviewsSection(
                usuario: null,
                aoPedirLogin: () {},
                service: falsas,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('aparece quando o Firestore ainda tem mais', (tester) async {
      await montar(tester, _AvaliacoesFalsas(quantas: 6, total: 7));
      expect(find.text('Mostrar mais (1 restante)'), findsOneWidget);
    });

    // O total da agregacao conta tambem documento que a lista recusa: so com
    // ele, o botao ficava na tela sem trazer nada.
    testWidgets('some quando veio menos que o limite', (tester) async {
      await montar(tester, _AvaliacoesFalsas(quantas: 5, total: 8, lidos: 5));
      expect(find.textContaining('Mostrar mais'), findsNothing);
    });
  });
}
