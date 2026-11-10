import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/data/legal_data.dart';
import 'package:ecomapbrasil/models/documento_legal.dart';
import 'package:ecomapbrasil/screens/legal_screen.dart';
import 'package:ecomapbrasil/services/abrir_link.dart';
import 'package:ecomapbrasil/theme/app_theme.dart';

/// O `abrirNoSistema` de verdade, para devolver depois de cada teste.
final _abridorDeVerdade = abrirNoSistema;

/// Todos os textos de um documento, inclusive as celulas das tabelas.
Iterable<String> _textos(DocumentoLegal d) sync* {
  yield d.abertura;
  for (final s in d.secoes) {
    for (final b in s.blocos) {
      switch (b) {
        case ParagrafoLegal(:final texto):
          yield texto;
        case ListaLegal(:final itens):
          yield* itens;
        case TabelaLegal(:final linhas):
          for (final l in linhas) {
            yield* l;
          }
      }
    }
  }
}

final _destinos = RegExp(r'\]\(([^)\s]+)\)');

Future<void> _montar(WidgetTester tester, Widget tela) async {
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: construirTema(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: tela,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('legal_data', () {
    test('a cópia do site tem os dois documentos e a data', () {
      expect(privacidade.titulo, 'Política de privacidade');
      expect(termos.titulo, 'Termos de uso');
      expect(atualizadoEm, matches(RegExp(r'^\d{1,2} de [a-zç]+ de \d{4}$')));
      expect(contatoDados, contains('template=pedido-de-dados.md'));
    });

    test('toda âncora aponta para uma seção que existe', () {
      final ids = {
        '/privacidade': {for (final s in privacidade.secoes) s.id},
        '/termos': {for (final s in termos.secoes) s.id},
      };
      for (final (caminho, doc) in [
        ('/privacidade', privacidade),
        ('/termos', termos),
      ]) {
        expect(ids[caminho]!.length, doc.secoes.length, reason: 'id repetido');
        for (final texto in _textos(doc)) {
          for (final m in _destinos.allMatches(texto)) {
            final destino = m[1]!;
            if (destino.startsWith('#')) {
              expect(ids[caminho], contains(destino.substring(1)));
            } else if (destino.startsWith('/privacidade#') ||
                destino.startsWith('/termos#')) {
              final [pagina, ancora] = destino.split('#');
              expect(ids[pagina], contains(ancora), reason: destino);
            } else {
              expect(
                destino == '/privacidade' ||
                    destino == '/termos' ||
                    destino.startsWith('/#') ||
                    destino.startsWith('https://'),
                isTrue,
                reason: destino,
              );
            }
          }
        }
      }
    });

    test('a política diz o que o app faz com a foto e com a idade', () {
      final tudo = _textos(privacidade).join('\n');
      expect(tudo, contains('sem metadados'));
      expect(tudo, contains('18 anos'));
      expect(tudo, contains('`uso_identificacao`'));
    });
  });

  group('LegalScreen', () {
    testWidgets('mostra a versão e todas as seções, sem estourar no celular', (
      tester,
    ) async {
      await _montar(tester, const LegalScreen(documento: privacidade));
      expect(find.text('Versão de $atualizadoEm'), findsOneWidget);
      for (final s in privacidade.secoes) {
        // Uma vez no indice, uma no titulo da secao.
        expect(find.textContaining(s.titulo), findsAtLeastNWidgets(1));
      }
      await tester.scrollUntilVisible(
        find.text('Voltar'),
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 100,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('o índice rola até a seção', (tester) async {
      await _montar(tester, const LegalScreen(documento: privacidade));
      final secao = find.byWidgetPredicate(
        (w) => w is Text && w.data == 'Segurança' && w.style?.fontSize == 24,
      );
      // O item 9 do indice fica logo abaixo da primeira tela.
      await tester.ensureVisible(find.text('9. Segurança'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(secao).dy, greaterThan(844));
      await tester.tap(find.text('9. Segurança'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(secao).dy, lessThan(844));
    });

    testWidgets('abre já na seção pedida', (tester) async {
      await _montar(
        tester,
        const LegalScreen(documento: privacidade, secao: 'direitos'),
      );
      final secao = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.data == 'Seus direitos e como pedir' &&
            w.style?.fontSize == 24,
      );
      expect(tester.getTopLeft(secao).dy, lessThan(844));
    });

    testWidgets('o botão do fim abre o outro documento', (tester) async {
      await _montar(tester, const LegalScreen(documento: privacidade));
      await tester.scrollUntilVisible(
        find.text('Termos de uso'),
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 100,
      );
      await tester.tap(find.text('Termos de uso'));
      await tester.pumpAndSettle();
      expect(find.text('O que é o EcoMapBrasil'), findsWidgets);
    });

    testWidgets('link para fora abre no navegador', (tester) async {
      final abertos = <Uri>[];
      abrirNoSistema = (uri) async {
        abertos.add(uri);
        return true;
      };
      addTearDown(() => abrirNoSistema = _abridorDeVerdade);

      await _montar(tester, const LegalScreen(documento: termos));
      await tester.ensureVisible(
        find.textContaining('abra uma issue', findRichText: true).first,
      );
      await tester.pumpAndSettle();
      await tester.tapOnText(
        find.textRange.ofSubstring('abra uma issue').first,
      );
      await tester.pump();
      expect(abertos, hasLength(1));
      expect(abertos.single.toString(), startsWith('https://github.com/'));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('link que não abre vai para a área de transferência', (
      tester,
    ) async {
      String? copiado;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (chamada) async {
          if (chamada.method == 'Clipboard.setData') {
            copiado = (chamada.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      // Aparelho sem navegador, ou o sistema recusou.
      abrirNoSistema = (_) async => false;
      addTearDown(() => abrirNoSistema = _abridorDeVerdade);
      String? seguido;
      await _montar(
        tester,
        Scaffold(
          body: TextoMarcado(
            'Veja o [site](https://ecomapbrasil-17756.web.app) e a '
            '**política**.',
            aoSeguir: (d) => seguido = d,
            estilo: const TextStyle(fontSize: 16),
          ),
        ),
      );
      expect(
        find.text('Veja o site e a política.', findRichText: true),
        findsOneWidget,
      );
      await tester.tapOnText(find.textRange.ofSubstring('site'));
      expect(seguido, 'https://ecomapbrasil-17756.web.app');

      // Na tela de verdade, o link que nao abriu vai para a area de
      // transferencia, com o aviso.
      await _montar(tester, const LegalScreen(documento: termos));
      await tester.ensureVisible(
        find.textContaining('abra uma issue', findRichText: true).first,
      );
      await tester.pumpAndSettle();
      await tester.tapOnText(
        find.textRange.ofSubstring('abra uma issue').first,
      );
      await tester.pump();
      expect(copiado, startsWith('https://github.com/ecomap-devs/'));
      expect(find.textContaining('Link copiado'), findsOneWidget);
    });
  });
}
