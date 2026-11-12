import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/widgets/voltar_para_o_inicio.dart';

/// Uma casca mínima com as quatro abas, no lugar da `AppShell`, que monta a
/// Home com o Firestore.
class _Casca extends StatefulWidget {
  const _Casca();

  @override
  State<_Casca> createState() => _CascaState();
}

class _CascaState extends State<_Casca> {
  int indice = 0;

  @override
  Widget build(BuildContext context) => VoltarParaOInicio(
    noInicio: indice == 0,
    irParaOInicio: () => setState(() => indice = 0),
    child: Scaffold(
      body: Center(child: Text('aba $indice')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: (i) => setState(() => indice = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.pets), label: 'Animais'),
          NavigationDestination(icon: Icon(Icons.photo_camera), label: 'Fotos'),
        ],
      ),
    ),
  );
}

void main() {
  // O Voltar do sistema fechava o app de qualquer aba até 11/11/2026. Agora,
  // fora do Início, ele leva ao Início; só dali o app fecha.

  /// Conta os pedidos de fechar o app que chegam ao Android.
  List<String> escutarFechamento(WidgetTester tester) {
    final pedidos = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (chamada) async {
        if (chamada.method == 'SystemNavigator.pop') {
          pedidos.add(chamada.method);
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
    return pedidos;
  }

  for (final aba in ['Mapa', 'Animais', 'Fotos']) {
    testWidgets('Voltar em $aba leva ao Início sem fechar o app', (
      tester,
    ) async {
      final fechou = escutarFechamento(tester);
      await tester.pumpWidget(const MaterialApp(home: _Casca()));
      await tester.tap(find.text(aba));
      await tester.pumpAndSettle();
      expect(find.text('aba 0'), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('aba 0'), findsOneWidget);
      expect(fechou, isEmpty);
    });
  }

  testWidgets('Voltar no Início fecha o app', (tester) async {
    final fechou = escutarFechamento(tester);
    await tester.pumpWidget(const MaterialApp(home: _Casca()));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(fechou, ['SystemNavigator.pop']);
  });

  testWidgets('dois Voltar fora do Início: o primeiro volta, o segundo fecha', (
    tester,
  ) async {
    final fechou = escutarFechamento(tester);
    await tester.pumpWidget(const MaterialApp(home: _Casca()));
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('aba 0'), findsOneWidget);
    expect(fechou, isEmpty);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(fechou, ['SystemNavigator.pop']);
  });
}
