import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/models/avaliacao.dart';
import 'package:ecomapbrasil/screens/home_screen.dart';
import 'package:ecomapbrasil/services/abrir_link.dart';
import 'package:ecomapbrasil/services/auth_service.dart';
import 'package:ecomapbrasil/services/reviews_service.dart';
import 'package:ecomapbrasil/theme/app_theme.dart';
import 'package:ecomapbrasil/widgets/auth_modal.dart';
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

/// O modal so fala com o Firebase ao enviar o formulario, o que estes testes
/// nao fazem.
class _FirebaseAuthFalso implements FirebaseAuth {
  @override
  dynamic noSuchMethod(Invocation chamada) => null;
}

class _FirestoreFalso implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation chamada) => null;
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
        find.text('© 2025–2026 EcoMapBrasil'),
        500,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 200,
      );
      await tester.pumpAndSettle();
      expect(find.text('Gostei muito do mapa.'), findsOneWidget);
      expect(find.text('4,5'), findsOneWidget);
      // Os canais oficiais, como no site. Ate 02/11/2026 a Home mandava usar
      // o aplicativo "Denúncia Ambiente", que nao e canal oficial.
      expect(find.text('Como denunciar'), findsWidgets);
      expect(find.text('0800 061 8080'), findsOneWidget);
      expect(find.text('Fala.BR'), findsOneWidget);
      expect(
        find.textContaining('Denúncia Ambiente', findRichText: true),
        findsNothing,
      );
      expect(
        find.text('Dados de fontes públicas: INPE, IBGE, MMA e IUCN.'),
        findsOneWidget,
      );
      // A foto da secao final e CC BY: o credito aparece nela (04/11/2026).
      expect(
        find.textContaining('Foto: Bruno Kelly/Amazônia Real · CC BY 2.0'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      // Os atalhos do rodape abrem a politica e os termos (02/11/2026).
      await tester.tap(find.text('Política de privacidade'));
      await tester.pumpAndSettle();
      expect(find.text('Quem cuida dos seus dados'), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Termos de uso'));
      await tester.pumpAndSettle();
      expect(find.text('O que é o EcoMapBrasil'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  // Ate 10/11/2026 o app nao abria links: o numero e o site eram texto para
  // copiar. Agora o toque abre o discador ou o navegador.
  testWidgets('os canais de denúncia abrem o discador e o navegador', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final abertos = <String>[];
    final deVerdade = abrirNoSistema;
    abrirNoSistema = (uri) async {
      abertos.add('$uri');
      return true;
    };
    addTearDown(() => abrirNoSistema = deVerdade);

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
                aoAbrirMapa: () {},
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

    Future<void> tocar(Finder alvo) async {
      await tester.scrollUntilVisible(
        alvo,
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 200,
      );
      await tester.pumpAndSettle();
      await tester.tap(alvo);
      await tester.pumpAndSettle();
    }

    await tocar(find.text('Fala.BR'));
    await tocar(find.text('0800 061 8080'));
    await tocar(find.text('190'));
    expect(abertos, [
      'https://falabr.cgu.gov.br/v2/',
      'tel:08000618080',
      'tel:190',
    ]);

    // A fonte e o credito da foto final: o link e o nome, como no site.
    await tester.scrollUntilVisible(
      find.textContaining('conferido em', findRichText: true),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 200,
    );
    await tester.pumpAndSettle();
    await tester.tapOnText(
      find.textRange.ofSubstring('gov.br, Apresentar denúncia ambiental'),
    );
    await tester.pumpAndSettle();
    expect(
      abertos.last,
      'https://www.gov.br/pt-br/servicos/apresentar-denuncia-ambiental',
    );
    await tester.scrollUntilVisible(
      find.textContaining('Bruno Kelly', findRichText: true),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 200,
    );
    await tester.pumpAndSettle();
    await tester.tapOnText(
      find.textRange.ofSubstring('Bruno Kelly/Amazônia Real'),
    );
    await tester.pumpAndSettle();
    expect(abertos.last, startsWith('https://commons.wikimedia.org/wiki/'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('o cadastro avisa dos termos e da política', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: Scaffold(
          body: AuthModal(
            auth: AuthService(
              auth: _FirebaseAuthFalso(),
              db: _FirestoreFalso(),
            ),
          ),
        ),
      ),
    );
    expect(
      find.textContaining('você concorda', findRichText: true),
      findsNothing,
    );
    await tester.tap(find.text('Não tem conta? Cadastre-se'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('você concorda', findRichText: true),
      findsOneWidget,
    );
    await tester.tapOnText(find.textRange.ofSubstring('termos de uso'));
    await tester.pumpAndSettle();
    expect(find.text('O que é o EcoMapBrasil'), findsWidgets);
  });

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
