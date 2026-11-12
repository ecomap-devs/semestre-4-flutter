import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Aviso de sucesso (mata) ou de erro (terra), sem borda, como no site.
class AvisoDeFormulario extends StatelessWidget {
  const AvisoDeFormulario({super.key, required this.texto, required this.erro});

  final String texto;
  final bool erro;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: erro ? context.cores.terraClara : context.cores.mataClara,
        borderRadius: BorderRadius.circular(raioPadrao),
      ),
      child: Text(
        texto,
        style: Escala.bodyMedium.copyWith(
          color: erro ? context.cores.terra : context.cores.mataEscura,
        ),
      ),
    ),
  );
}
