import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/models/avaliacao.dart';
import 'package:ecomapbrasil/screens/home_screen.dart';
import 'package:ecomapbrasil/services/reviews_service.dart';
import 'package:ecomapbrasil/theme/app_theme.dart';

/// Avaliacoes sem Firestore: duas fixas e o resumo delas.
class _AvaliacoesFalsas implements ReviewsService {
  @override
  Stream<List<Avaliacao>> observar({required int limite}) => Stream.value([
    Avaliacao(
      id: '1',
      uid: 'a',
      nome: 'Ana',
      fotoUrl: '',
      nota: 5,
      comentario: 'Gostei muito do mapa.',
      criadoEm: DateTime(2026, 10, 1),
    ),
    Avaliacao(
      id: '2',
      uid: 'b',
      nome: 'Beto',
      fotoUrl: '',
      nota: 4,
      comentario: 'Bem explicado.',
      criadoEm: DateTime(2026, 10, 2),
    ),
  ]);

  @override
  Future<ResumoAvaliacoes> resumo() async =>
      const ResumoAvaliacoes(total: 2, media: 4.5);

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
}
