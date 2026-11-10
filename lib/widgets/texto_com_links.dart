import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../services/abrir_link.dart';
import '../theme/app_theme.dart';

/// Um pedaco de [TextoComLinks]: texto puro ou, com [link], um link.
@immutable
class Trecho {
  const Trecho(this.texto, {this.link});

  final String texto;

  /// `https:` ou `tel:`. Sem ele, o trecho e texto comum.
  final String? link;
}

/// Uma frase com links no meio, como os creditos das fotos e as fontes:
/// "Foto: **autor** · CC BY 4.0 · Wikimedia Commons", com o autor tocavel.
///
/// Os trechos vem prontos, e nao de uma marcacao `[texto](endereco)` como a do
/// `TextoMarcado`: os enderecos do Wikimedia tem parenteses
/// (`..._(FOTO_BRUNO_KELLY)_(35)...`), e a marcacao cortaria o link no primeiro.
///
/// Os toques vivem num estado proprio para os reconhecedores serem descartados
/// com o widget.
class TextoComLinks extends StatefulWidget {
  const TextoComLinks(
    this.trechos, {
    super.key,
    required this.estilo,
    this.corDoLink = AppCores.mata,
  });

  final List<Trecho> trechos;
  final TextStyle estilo;

  /// A cor dos links. Sobre fundo escuro, um claro; no resto, o verde do app.
  final Color corDoLink;

  @override
  State<TextoComLinks> createState() => _TextoComLinksState();
}

class _TextoComLinksState extends State<TextoComLinks> {
  final _toques = <TapGestureRecognizer>[];

  void _descartarToques() {
    for (final t in _toques) {
      t.dispose();
    }
    _toques.clear();
  }

  @override
  void dispose() {
    _descartarToques();
    super.dispose();
  }

  /// Um reconhecedor novo para [link], guardado para ser descartado depois.
  TapGestureRecognizer _toque(String link) {
    final toque = TapGestureRecognizer()
      ..onTap = () => abrirLink(context, link);
    _toques.add(toque);
    return toque;
  }

  @override
  Widget build(BuildContext context) {
    _descartarToques();
    return Text.rich(
      TextSpan(
        style: widget.estilo,
        children: [
          for (final t in widget.trechos)
            if (t.link case final link?)
              TextSpan(
                text: t.texto,
                recognizer: _toque(link),
                style: TextStyle(
                  color: widget.corDoLink,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: widget.corDoLink,
                ),
              )
            else
              TextSpan(text: t.texto),
        ],
      ),
    );
  }
}
