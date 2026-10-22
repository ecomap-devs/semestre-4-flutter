import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Especie ameacada do catalogo.
///
/// Campos espelham `allAnimals` do Animais.jsx.
@immutable
class Animal {
  const Animal({
    required this.nome,
    required this.status,
    required this.bioma,
    required this.regiao,
    required this.populacao,
    required this.descricao,
    required this.imagem,
    required this.tendencia,
    required this.anos,
    required this.ameacas,
  });

  final String nome;
  final String status;
  final String bioma;
  final String regiao;

  /// Populacao estimada atual, em individuos.
  final int populacao;
  final String descricao;
  final String imagem;

  /// Serie populacional por ano, para o grafico de tendencia.
  final List<int> tendencia;
  final List<String> anos;
  final List<String> ameacas;

  /// Cor do texto do status, como no site (`corDoStatus`).
  Color get corStatus => AppCores.status[status] ?? AppCores.tinta3;

  /// Variacao do primeiro ao ultimo ano da serie, em %. Negativo = declinio.
  double get variacaoPercentual {
    if (tendencia.length < 2) return 0;
    final inicio = tendencia.first;
    if (inicio == 0) return 0;
    return ((tendencia.last - inicio) / inicio) * 100;
  }

  /// `true` quando a serie termina acima de onde comecou — caso do
  /// mico-leao-dourado, o unico do catalogo em recuperacao.
  bool get emRecuperacao => variacaoPercentual > 0;

  /// Cor da tendencia: mata se a populacao subiu, terra se caiu mais da
  /// metade, ocre no meio-termo. A mesma regra do `corDaTendencia` do site.
  Color get corTendencia {
    if (emRecuperacao) return AppCores.mata;
    if (variacaoPercentual < -50) return AppCores.terra;
    return AppCores.ocre;
  }

  /// "+525%" ou "−75%", com o sinal de menos tipografico (−), nao o hifen.
  String get variacaoFormatada {
    final v = variacaoPercentual.round();
    return '${v >= 0 ? '+' : '−'}${v.abs()}%';
  }

  String get populacaoFormatada {
    if (populacao == 0) return 'Extinta na natureza';
    if (populacao >= 1000) {
      final milhares = populacao / 1000;
      final txt = milhares.toStringAsFixed(
        milhares.truncateToDouble() == milhares ? 0 : 1,
      );
      return '$txt mil indivíduos'.replaceAll('.', ',');
    }
    return '$populacao indivíduos';
  }

  /// "6.500": a populacao com separador de milhar brasileiro.
  String get populacaoComMilhar => populacao.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]}.',
  );
}
