import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecomapbrasil/models/identificacao.dart';
import 'package:ecomapbrasil/screens/fotos_screen.dart';
import 'package:ecomapbrasil/services/declaracao_de_idade.dart';
import 'package:ecomapbrasil/services/identificacao_service.dart';

/// Só o uid importa para a trava.
class _Usuario extends Fake implements User {
  _Usuario(this.uid);

  @override
  final String uid;
}

/// O Gemini falso: devolve o que o teste mandar, quando o teste mandar.
class _Servico extends Fake implements IdentificacaoService {
  Completer<Identificacao> resposta = Completer();

  @override
  Future<Identificacao> identificar(Uint8List foto) => resposta.future;
}

const _onca = Identificacao(
  ehAnimal: true,
  nomePopular: 'Onça-pintada',
  nomeCientifico: 'Panthera onca',
  confianca: Confianca.alta,
  descricao: 'Pelagem com rosetas.',
);

/// Um PNG de 1 x 1 pixel, para a prévia da foto ter o que desenhar.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

void main() {
  // Trava por autodeclaração de 11/11/2026: os termos da Gemini API exigem 18
  // anos. A pergunta aparece na primeira tentativa de usar a foto, e só o
  // "sim" fica guardado, por conta.
  late List<ImageSource> aberturas;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    aberturas = [];
  });

  Future<void> montar(WidgetTester tester, {String uid = 'ana'}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FotosScreen(
            usuario: _Usuario(uid),
            aoPedirLogin: () {},
            // Sem foto escolhida: nada vai para o Gemini.
            escolherImagem: (origem) async {
              aberturas.add(origem);
              return null as Uint8List?;
            },
          ),
        ),
      ),
    );
  }

  /// Rola até o texto e toca: a pergunta fica embaixo, no ListView da tela.
  /// Com [esperar] falso, avança só um quadro: enquanto a identificação não
  /// responde, o indicador gira e a tela nunca assenta.
  Future<void> tocar(
    WidgetTester tester,
    String texto, {
    bool esperar = true,
  }) async {
    await tester.ensureVisible(find.text(texto));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texto));
    if (esperar) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<String?> guardado(String uid) async =>
      (await SharedPreferences.getInstance()).getString(
        DeclaracaoDeIdade.chave(uid),
      );

  testWidgets('primeira tentativa: pergunta a idade e não abre nada', (
    tester,
  ) async {
    await montar(tester);
    expect(find.text('Você tem 18 anos ou mais?'), findsNothing);

    await tocar(tester, 'Escolher imagem');

    expect(find.text('Você tem 18 anos ou mais?'), findsOneWidget);
    // A pergunta fica no lugar dos botões.
    expect(find.text('Escolher imagem'), findsNothing);
    expect(aberturas, isEmpty);
  });

  testWidgets('"sim": guarda, abre o que foi tocado, e não pergunta de novo', (
    tester,
  ) async {
    await montar(tester);
    await tocar(tester, 'Tirar foto');
    await tocar(tester, 'Tenho 18 anos ou mais');

    expect(aberturas, [ImageSource.camera]);
    expect(await guardado('ana'), isNotNull);

    await tocar(tester, 'Escolher imagem');
    expect(find.text('Você tem 18 anos ou mais?'), findsNothing);
    expect(aberturas, [ImageSource.camera, ImageSource.gallery]);
  });

  testWidgets('"não": avisa, desliga os botões e não guarda nada', (
    tester,
  ) async {
    await montar(tester);
    await tocar(tester, 'Escolher imagem');
    await tocar(tester, 'Tenho menos de 18');

    expect(find.textContaining('só para quem tem 18 anos ou mais'), findsOne);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    expect(aberturas, isEmpty);
    expect(await guardado('ana'), isNull);
  });

  testWidgets('quem já declarou neste aparelho vai direto', (tester) async {
    SharedPreferences.setMockInitialValues({
      DeclaracaoDeIdade.chave('ana'): '2026-11-11T12:00:00.000Z',
    });
    await montar(tester);

    await tocar(tester, 'Escolher imagem');

    expect(find.text('Você tem 18 anos ou mais?'), findsNothing);
    expect(aberturas, [ImageSource.gallery]);
  });

  testWidgets('a resposta é da conta: outra conta no mesmo aparelho é '
      'perguntada', (tester) async {
    SharedPreferences.setMockInitialValues({
      DeclaracaoDeIdade.chave('ana'): '2026-11-11T12:00:00.000Z',
    });
    await montar(tester, uid: 'bia');

    await tocar(tester, 'Escolher imagem');

    expect(find.text('Você tem 18 anos ou mais?'), findsOneWidget);
    expect(aberturas, isEmpty);
  });

  // Revisão do Codex de 11/11/2026: a tela é a mesma quando a conta muda (o
  // AppShell a identifica só pela aba), e o estado da conta anterior ficava.
  group('troca de conta na mesma tela', () {
    late ValueNotifier<User?> conta;
    late _Servico servico;

    Future<void> montarComTroca(WidgetTester tester, {Uint8List? foto}) async {
      conta = ValueNotifier(_Usuario('ana'));
      servico = _Servico();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<User?>(
              valueListenable: conta,
              builder: (_, usuario, _) => FotosScreen(
                usuario: usuario,
                aoPedirLogin: () {},
                servico: servico,
                escolherImagem: (origem) async {
                  aberturas.add(origem);
                  return foto;
                },
              ),
            ),
          ),
        ),
      );
    }

    /// Sai da conta e entra com outra, sem sair da tela.
    Future<void> trocarPara(WidgetTester tester, String uid) async {
      conta.value = null;
      await tester.pump();
      conta.value = _Usuario(uid);
      await tester.pumpAndSettle();
    }

    testWidgets('o "não" de uma conta não vale para a próxima', (tester) async {
      SharedPreferences.setMockInitialValues({
        DeclaracaoDeIdade.chave('bia'): '2026-11-11T12:00:00.000Z',
      });
      await montarComTroca(tester);
      await tocar(tester, 'Escolher imagem');
      await tocar(tester, 'Tenho menos de 18');
      expect(find.textContaining('só para quem tem 18 anos ou mais'), findsOne);

      await trocarPara(tester, 'bia');

      expect(
        find.textContaining('só para quem tem 18 anos ou mais'),
        findsNothing,
      );
      await tocar(tester, 'Escolher imagem');
      expect(aberturas, [ImageSource.gallery]);
    });

    testWidgets('a foto e o resultado da conta anterior somem', (tester) async {
      SharedPreferences.setMockInitialValues({
        DeclaracaoDeIdade.chave('ana'): '2026-11-11T12:00:00.000Z',
      });
      await montarComTroca(tester, foto: _png);
      await tocar(tester, 'Escolher imagem', esperar: false);
      servico.resposta.complete(_onca);
      await tester.pumpAndSettle();
      expect(find.text('Onça-pintada'), findsOneWidget);
      expect(find.bySemanticsLabel('Foto enviada'), findsOneWidget);

      await trocarPara(tester, 'bia');

      expect(find.text('Onça-pintada'), findsNothing);
      expect(find.bySemanticsLabel('Foto enviada'), findsNothing);
    });

    testWidgets('a resposta que chega depois da troca não aparece', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        DeclaracaoDeIdade.chave('ana'): '2026-11-11T12:00:00.000Z',
      });
      await montarComTroca(tester, foto: _png);
      await tocar(tester, 'Escolher imagem', esperar: false);
      expect(find.textContaining('Procurando o animal'), findsOneWidget);

      await trocarPara(tester, 'bia');
      servico.resposta.complete(_onca);
      await tester.pumpAndSettle();

      expect(find.text('Onça-pintada'), findsNothing);
      expect(find.textContaining('Procurando o animal'), findsNothing);
    });
  });
}
