import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/data/animais_data.dart';
import 'package:ecomapbrasil/data/denuncia_data.dart';
import 'package:ecomapbrasil/services/abrir_link.dart';
import 'package:ecomapbrasil/theme/app_theme.dart';
import 'package:ecomapbrasil/widgets/texto_com_links.dart';

/// Um botao que chama `abrirLink` com [endereco], e o que foi copiado.
Future<List<String>> _montar(WidgetTester tester, String endereco) async {
  final copiados = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (chamada) async {
      if (chamada.method == 'Clipboard.setData') {
        copiados.add((chamada.arguments as Map)['text'] as String);
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
  await tester.pumpWidget(
    MaterialApp(
      theme: construirTema(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => abrirLink(context, endereco),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  return copiados;
}

void main() {
  final deVerdade = abrirNoSistema;
  late List<Uri> abertos;
  late bool abre;

  setUp(() {
    abertos = [];
    abre = true;
    abrirNoSistema = (uri) async {
      abertos.add(uri);
      return abre;
    };
  });
  tearDown(() => abrirNoSistema = deVerdade);

  group('abrirLink', () {
    testWidgets('https e tel vão para o sistema, sem aviso', (tester) async {
      for (final endereco in ['https://falabr.cgu.gov.br/v2/', 'tel:190']) {
        final copiados = await _montar(tester, endereco);
        await tester.tap(find.text('abrir'));
        await tester.pumpAndSettle();
        expect(abertos.last.toString(), endereco);
        expect(copiados, isEmpty);
        expect(find.byType(SnackBar), findsNothing);
      }
    });

    testWidgets('telefone que não abre copia só o número', (tester) async {
      abre = false;
      final copiados = await _montar(tester, 'tel:08000618080');
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(copiados, ['08000618080']);
      expect(find.textContaining('Número copiado: 08000618080'), findsOne);
    });

    testWidgets('erro do sistema também vira cópia', (tester) async {
      abrirNoSistema = (_) async =>
          throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
      final copiados = await _montar(tester, 'https://github.com/ecomap-devs');
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(copiados, ['https://github.com/ecomap-devs']);
      expect(find.textContaining('Link copiado'), findsOne);
    });

    // Os enderecos sao nossos, mas um esquema estranho que entrasse por
    // engano nos dados nao chega ao sistema.
    for (final estranho in [
      'javascript:alert(1)',
      'intent://scan/#Intent;scheme=zxing;end',
      'file:///sdcard/x',
      'falabr.cgu.gov.br',
    ]) {
      testWidgets('não entrega "$estranho" ao sistema', (tester) async {
        final copiados = await _montar(tester, estranho);
        await tester.tap(find.text('abrir'));
        await tester.pumpAndSettle();
        expect(abertos, isEmpty);
        expect(copiados, [estranho]);
      });
    }
  });

  testWidgets('TextoComLinks: só o trecho com link abre', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextoComLinks(const [
            Trecho('Foto: '),
            Trecho(
              'Autor',
              link: 'https://commons.wikimedia.org/wiki/File:A_(1).jpg',
            ),
            Trecho(' · CC BY 4.0 · Wikimedia Commons'),
          ], estilo: const TextStyle(fontSize: 16)),
        ),
      ),
    );
    expect(
      find.text(
        'Foto: Autor · CC BY 4.0 · Wikimedia Commons',
        findRichText: true,
      ),
      findsOneWidget,
    );
    await tester.tapOnText(find.textRange.ofSubstring('CC BY'));
    await tester.pump();
    expect(abertos, isEmpty);
    await tester.tapOnText(find.textRange.ofSubstring('Autor'));
    await tester.pump();
    // O parentese do endereco do Wikimedia chega inteiro.
    expect(abertos.map((u) => '$u'), [
      'https://commons.wikimedia.org/wiki/File:A_(1).jpg',
    ]);
  });

  group('os links dos dados abrem', () {
    test('canal de denúncia é tel: ou https:', () {
      for (final c in canaisDenuncia) {
        expect(
          c.link.startsWith('tel:') || c.link.startsWith('https://'),
          isTrue,
          reason: c.titulo,
        );
      }
      // O numero do link e o mostrado, sem os espacos.
      for (final c in canaisDenuncia.where((c) => c.link.startsWith('tel:'))) {
        expect(c.link, 'tel:${c.contato.replaceAll(' ', '')}');
      }
    });

    test('fonte de população é https:', () {
      for (final a in animais) {
        final p = a.populacao;
        if (p == null) continue;
        expect(Uri.parse(p.link).scheme, 'https', reason: a.nome);
      }
    });
  });
}
