import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecomapbrasil/theme/app_theme.dart';

/// Contraste WCAG entre duas cores (1 a 21).
double contraste(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('Tema escuro', () {
    test('o tema escuro usa as cores escuras e o claro, as claras', () {
      final escuro = construirTema(escuro: true);
      final claro = construirTema();
      expect(escuro.brightness, Brightness.dark);
      expect(escuro.extension<Cores>(), Cores.escuro);
      expect(escuro.scaffoldBackgroundColor, Cores.escuro.papel);
      expect(claro.extension<Cores>(), Cores.claro);
      expect(claro.scaffoldBackgroundColor, AppCores.papel);
    });

    for (final (nome, c) in [
      ('claro', Cores.claro),
      ('escuro', Cores.escuro),
    ]) {
      test('texto do tema $nome tem 4,5:1 sobre o papel e o cartão', () {
        for (final fundo in [c.papel, c.cartao]) {
          final textos = [c.tinta, c.tinta2, c.tinta3, c.mata, c.terra];
          for (final texto in textos) {
            expect(
              contraste(texto, fundo),
              greaterThanOrEqualTo(4.5),
              reason: '$texto sobre $fundo',
            );
          }
        }
        expect(contraste(c.sobreDestaque, c.mata), greaterThanOrEqualTo(4.5));
      });
    }

    testWidgets('context.cores segue o tema do MaterialApp', (tester) async {
      late Cores lidas;
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTema(),
          darkTheme: construirTema(escuro: true),
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              lidas = context.cores;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(lidas, Cores.escuro);
    });
  });
}
