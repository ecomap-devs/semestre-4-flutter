import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/services/auth_service.dart';
import 'package:ecomapbrasil/widgets/apagar_conta_dialog.dart';

void main() {
  // Botão de apagar conta (11/11/2026). As etapas falam com o Firebase e o
  // Supabase; aqui elas viram funções falsas, e o que se testa é a ordem, a
  // parada na primeira falha e o que a pessoa lê.
  group('apagarEmOrdem', () {
    test('roda todas, na ordem', () async {
      final feitas = <EtapaDoApagamento>[];
      await apagarEmOrdem([
        for (final etapa in EtapaDoApagamento.values)
          (etapa, () async => feitas.add(etapa)),
      ]);
      expect(feitas, EtapaDoApagamento.values);
    });

    test('a conta no Auth é a última, e a senha a primeira', () {
      expect(EtapaDoApagamento.values.first, EtapaDoApagamento.senha);
      expect(EtapaDoApagamento.values.last, EtapaDoApagamento.conta);
    });

    test('para na primeira falha e diz qual foi', () async {
      final feitas = <EtapaDoApagamento>[];
      final causa = StateError('Supabase fora do ar');
      final falha = apagarEmOrdem([
        for (final etapa in EtapaDoApagamento.values)
          (
            etapa,
            () async {
              if (etapa == EtapaDoApagamento.servidor) throw causa;
              feitas.add(etapa);
            },
          ),
      ]);
      await expectLater(
        falha,
        throwsA(
          isA<ApagamentoIncompleto>()
              .having((e) => e.etapa, 'etapa', EtapaDoApagamento.servidor)
              .having((e) => e.causa, 'causa', causa),
        ),
      );
      // Nada do Firebase foi tocado depois da falha no servidor.
      expect(feitas, [EtapaDoApagamento.senha]);
    });
  });

  group('ApagamentoIncompleto.mensagem', () {
    test('senha errada', () {
      for (final codigo in ['invalid-credential', 'wrong-password']) {
        expect(
          ApagamentoIncompleto(
            EtapaDoApagamento.senha,
            FirebaseAuthException(code: codigo),
          ).mensagem,
          'Senha incorreta.',
        );
      }
    });

    test('outro erro na senha usa a tradução do login', () {
      expect(
        ApagamentoIncompleto(
          EtapaDoApagamento.senha,
          FirebaseAuthException(code: 'too-many-requests'),
        ).mensagem,
        'Muitas tentativas. Aguarde um momento.',
      );
    });

    test('falha no servidor avisa que nada foi apagado', () {
      expect(
        ApagamentoIncompleto(EtapaDoApagamento.servidor, Exception()).mensagem,
        contains('nada foi apagado'),
      );
    });

    test('falha depois do servidor avisa que parte já saiu', () {
      for (final etapa in [
        EtapaDoApagamento.avaliacoes,
        EtapaDoApagamento.perfil,
        EtapaDoApagamento.conta,
      ]) {
        expect(
          ApagamentoIncompleto(etapa, Exception()).mensagem,
          contains('parte dos seus dados já saiu'),
          reason: etapa.name,
        );
      }
    });
  });

  group('ApagarContaDialog', () {
    /// Um botão que abre o diálogo e guarda o que ele devolveu.
    Future<List<bool?>> abrir(
      WidgetTester tester,
      Future<void> Function(String senha) aoApagar,
    ) async {
      final resultados = <bool?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => resultados.add(
                await showDialog<bool>(
                  context: context,
                  builder: (_) => ApagarContaDialog(aoApagar: aoApagar),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return resultados;
    }

    testWidgets('sem senha, pede a senha e não apaga', (tester) async {
      var chamadas = 0;
      await abrir(tester, (_) async => chamadas++);

      await tester.tap(find.text('Apagar minha conta'));
      await tester.pump();

      expect(find.text('Digite sua senha para confirmar.'), findsOneWidget);
      expect(chamadas, 0);
    });

    testWidgets('com a senha, apaga e fecha devolvendo true', (tester) async {
      final senhas = <String>[];
      final resultados = await abrir(tester, (s) async => senhas.add(s));

      await tester.enterText(find.byType(TextField), 'segredo123');
      await tester.tap(find.text('Apagar minha conta'));
      await tester.pumpAndSettle();

      expect(senhas, ['segredo123']);
      expect(resultados, [true]);
      expect(find.byType(ApagarContaDialog), findsNothing);
    });

    testWidgets('falha: mostra a mensagem e continua aberto', (tester) async {
      final resultados = await abrir(
        tester,
        (_) => Future.error(
          ApagamentoIncompleto(
            EtapaDoApagamento.senha,
            FirebaseAuthException(code: 'invalid-credential'),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'errada');
      await tester.tap(find.text('Apagar minha conta'));
      await tester.pumpAndSettle();

      expect(find.text('Senha incorreta.'), findsOneWidget);
      expect(find.byType(ApagarContaDialog), findsOneWidget);
      expect(resultados, isEmpty);
      // O botão volta a funcionar para tentar de novo.
      final botao = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(botao.onPressed, isNotNull);
    });

    testWidgets('enquanto apaga, o voltar não fecha', (tester) async {
      final pendente = Completer<void>();
      final resultados = await abrir(tester, (_) => pendente.future);

      await tester.enterText(find.byType(TextField), 'segredo123');
      await tester.tap(find.text('Apagar minha conta'));
      await tester.pump();
      expect(find.text('Apagando...'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(ApagarContaDialog), findsOneWidget);

      pendente.complete();
      await tester.pumpAndSettle();
      expect(resultados, [true]);
    });

    testWidgets('cancelar fecha devolvendo false', (tester) async {
      var chamadas = 0;
      final resultados = await abrir(tester, (_) async => chamadas++);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(resultados, [false]);
      expect(chamadas, 0);
    });
  });
}
