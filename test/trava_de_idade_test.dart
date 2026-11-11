import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecomapbrasil/screens/fotos_screen.dart';
import 'package:ecomapbrasil/services/declaracao_de_idade.dart';

/// Só o uid importa para a trava.
class _Usuario extends Fake implements User {
  _Usuario(this.uid);

  @override
  final String uid;
}

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
  Future<void> tocar(WidgetTester tester, String texto) async {
    await tester.ensureVisible(find.text(texto));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texto));
    await tester.pumpAndSettle();
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
}
