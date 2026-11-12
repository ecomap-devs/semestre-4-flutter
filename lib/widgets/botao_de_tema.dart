import 'package:flutter/material.dart';

import '../services/preferencia_de_tema.dart';
import '../theme/app_theme.dart';

/// Botão da barra do topo que escolhe o tema: sistema, claro ou escuro.
///
/// O ícone mostra a escolha atual; o menu marca a opção ativa.
class BotaoDeTema extends StatelessWidget {
  const BotaoDeTema({super.key, required this.tema});

  final PreferenciaDeTema tema;

  static const opcoes = <({ThemeMode modo, IconData icone, String rotulo})>[
    (
      modo: ThemeMode.system,
      icone: Icons.brightness_auto_outlined,
      rotulo: 'Seguir o sistema',
    ),
    (modo: ThemeMode.light, icone: Icons.light_mode_outlined, rotulo: 'Claro'),
    (modo: ThemeMode.dark, icone: Icons.dark_mode_outlined, rotulo: 'Escuro'),
  ];

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: tema,
    builder: (context, atual, _) {
      final escolhida = opcoes.firstWhere((o) => o.modo == atual);
      return PopupMenuButton<ThemeMode>(
        tooltip: 'Tema: ${escolhida.rotulo}',
        icon: Icon(escolhida.icone, color: context.cores.tinta),
        initialValue: atual,
        onSelected: tema.escolher,
        itemBuilder: (_) => [
          for (final o in opcoes)
            CheckedPopupMenuItem(
              value: o.modo,
              checked: o.modo == atual,
              child: Text(o.rotulo),
            ),
        ],
      );
    },
  );
}
