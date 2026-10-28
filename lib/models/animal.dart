import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estimativa de populacao publicada, sempre com quem a fez.
@immutable
class Populacao {
  const Populacao({
    required this.texto,
    required this.fonte,
    required this.link,
  });

  /// "menos de 300 na Mata Atlântica".
  final String texto;
  final String fonte;
  final String link;
}

/// Autor e licenca de uma foto de terceiros, que as licencas Creative Commons
/// exigem mostrar.
@immutable
class Credito {
  const Credito({
    required this.autor,
    required this.licenca,
    required this.link,
  });

  final String autor;

  /// "CC BY-SA 4.0".
  final String licenca;

  /// Pagina do arquivo no Wikimedia Commons.
  final String link;
}

/// Status de quem esta fora da lista nacional de especies ameacadas.
const naoAmeacada = 'Não ameaçada';

/// Especie do catalogo, ameacada ou nao — o `Animal` do `dados/animais.ts` do site.
///
/// Ate 28/10/2026 cada especie trazia populacao e uma serie de 2000 a 2024 sem
/// fonte, e um grafico de tendencia feito com ela. Agora o status vem da lista
/// nacional do MMA e da IUCN (`especies_data.dart`), e a populacao so aparece
/// onde ha estimativa publicada. Desde 28/10/2026 o catalogo tem tambem
/// especies fora da lista nacional, com o status [naoAmeacada].
@immutable
class Animal {
  const Animal({
    required this.nome,
    required this.cientifico,
    required this.status,
    required this.iucn,
    required this.bioma,
    required this.regiao,
    required this.descricao,
    required this.imagem,
    required this.ameacas,
    this.credito,
    this.populacao,
  });

  final String nome;

  /// Nome cientifico; e a chave em `statusEspecies`.
  final String cientifico;

  /// Status na lista nacional, pelo nome usado no site ("Em perigo"), ou
  /// [naoAmeacada].
  final String status;

  /// Categoria global da IUCN; `null` quando a IUCN nao avaliou.
  final String? iucn;
  final String bioma;
  final String regiao;
  final String descricao;
  final String imagem;
  final List<String> ameacas;

  /// So nas fotos de terceiros; as do bucket `animals` sao do projeto.
  final Credito? credito;
  final Populacao? populacao;

  /// Na lista nacional, em qualquer categoria.
  bool get ehAmeacada => status != naoAmeacada;

  /// Cor do texto do status, como no site (`corDoStatus`).
  Color get corStatus => AppCores.status[status] ?? AppCores.tinta3;

  /// "Quase ameaçada", ou "não avaliada" quando a IUCN nao avaliou.
  String get iucnOuNaoAvaliada => iucn ?? 'não avaliada';
}
