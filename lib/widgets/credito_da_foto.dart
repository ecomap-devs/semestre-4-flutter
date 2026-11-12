import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../theme/app_theme.dart';
import 'texto_com_links.dart';

/// "Foto: **autor** · licenca · Wikimedia Commons" sobre fundo escuro, com o
/// autor levando a pagina da foto, como no site. As licencas Creative Commons
/// pedem o credito junto da foto: na abertura da Home e na faixa do mico.
class CreditoDaFoto extends StatelessWidget {
  const CreditoDaFoto({super.key, required this.credito});

  final Credito credito;

  @override
  Widget build(BuildContext context) => TextoComLinks(
    [
      const Trecho('Foto: '),
      Trecho(credito.autor, link: credito.link),
      Trecho(' · ${credito.licenca} · Wikimedia Commons'),
    ],
    estilo: Escala.labelSmall.copyWith(color: Color(0xB3FFFDF8)),
    corDoLink: const Color(0xD9FFFDF8),
  );
}
