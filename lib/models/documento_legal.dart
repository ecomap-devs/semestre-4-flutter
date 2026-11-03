import 'package:flutter/foundation.dart';

/// A politica de privacidade e os termos de uso, como o `src/dados/legal.ts`
/// do site os guarda. Os textos usam a mesma marcacao minima: **negrito**,
/// `codigo` e [texto](endereco).
@immutable
sealed class BlocoLegal {
  const BlocoLegal();
}

final class ParagrafoLegal extends BlocoLegal {
  const ParagrafoLegal(this.texto);
  final String texto;
}

final class ListaLegal extends BlocoLegal {
  const ListaLegal(this.itens);
  final List<String> itens;
}

final class TabelaLegal extends BlocoLegal {
  const TabelaLegal({required this.colunas, required this.linhas});
  final List<String> colunas;
  final List<List<String>> linhas;
}

@immutable
class SecaoLegal {
  const SecaoLegal({
    required this.id,
    required this.titulo,
    required this.blocos,
  });

  /// O mesmo `id` da ancora do site (`/privacidade#direitos`).
  final String id;
  final String titulo;
  final List<BlocoLegal> blocos;
}

@immutable
class DocumentoLegal {
  const DocumentoLegal({
    required this.titulo,
    required this.descricao,
    required this.abertura,
    required this.secoes,
  });

  final String titulo;
  final String descricao;
  final String abertura;
  final List<SecaoLegal> secoes;
}
