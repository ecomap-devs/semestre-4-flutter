import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Foto de rede que, se falhar, cai num fundo liso com o icone de animal — o
/// `ImagemComReserva` do site.
///
/// As fotos vem do Supabase e de sites de terceiros e podem falhar (offline,
/// bucket movido, link fora do ar). Nunca mostra o icone de erro do Flutter.
class ImagemComReserva extends StatelessWidget {
  const ImagemComReserva({
    super.key,
    required this.url,
    this.alinhamento = Alignment.center,
    this.escura = false,
  });

  final String url;
  final Alignment alinhamento;

  /// Reserva escura, para foto que fica sob texto claro: se o Supabase nao
  /// responder, o texto continua legivel.
  final bool escura;

  @override
  Widget build(BuildContext context) {
    final reserva = ColoredBox(
      color: escura ? AppCores.mataNoite : AppCores.papel2,
      child: escura
          ? const SizedBox.expand()
          : const Center(
              child: Icon(Icons.pets, size: 34, color: AppCores.tinta3),
            ),
    );
    return Image.network(
      url,
      fit: BoxFit.cover,
      alignment: alinhamento,
      width: double.infinity,
      height: double.infinity,
      frameBuilder: (_, filho, quadro, sincrono) => sincrono || quadro != null
          ? filho
          : ColoredBox(
              color: escura ? AppCores.mataNoite : AppCores.papel2,
              child: const SizedBox.expand(),
            ),
      errorBuilder: (_, _, _) => reserva,
    );
  }
}
