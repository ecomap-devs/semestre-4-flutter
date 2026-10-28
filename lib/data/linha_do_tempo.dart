import 'package:flutter/foundation.dart';

import 'biomas_data.dart';
import 'prodes_data.dart';

/// Marco da linha do tempo da Home e do mapa.
@immutable
class Marco {
  const Marco(this.ano, this.titulo, this.texto);

  final int ano;
  final String titulo;
  final String texto;
}

/// "16.089": separador de milhar brasileiro, sem casas decimais.
String formatarMilhar(num valor) => valor.round().toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+$)'),
  (m) => '${m[1]}.',
);

String _km2(num valor) => '${formatarMilhar(valor)} km²';

/// A linha do tempo — a mesma do `dados/linhaDoTempo.ts` do site.
///
/// Ate 28/10/2026 era texto herdado do React, com erros: "Novo Codigo
/// Florestal" em 2013 (e de 2012) e um "recorde de 11.568 km² na Amazonia em
/// 2023", ano em que a taxa caiu. Agora os marcos com numero sao calculados do
/// PRODES, entao acompanham cada atualizacao. Os poucos escritos a mao sao
/// leis e acordos com data conhecida, e nao trazem numero. Recebe as taxas
/// para o teste poder passar uma serie propria.
List<Marco> calcularLinhaDoTempo(List<TaxaAnual> taxas) {
  final consolidadas = taxas.where((t) => !t.preliminar).toList();
  if (consolidadas.length < 3) {
    throw StateError('Taxas da Amazônia Legal incompletas em prodes_data.dart');
  }

  TaxaAnual maior(List<TaxaAnual> l) =>
      l.reduce((a, b) => b.km2 > a.km2 ? b : a);
  TaxaAnual menor(List<TaxaAnual> l) =>
      l.reduce((a, b) => b.km2 < a.km2 ? b : a);
  TaxaAnual? taxaEm(int ano) {
    for (final t in consolidadas) {
      if (t.ano == ano) return t;
    }
    return null;
  }

  final pior = maior(consolidadas);
  final minima = menor(consolidadas);
  final depoisDaMinima = consolidadas.where((t) => t.ano > minima.ano).toList();
  final picoRecente = depoisDaMinima.isEmpty ? null : maior(depoisDaMinima);
  final ultima = consolidadas.last;
  final anterior = consolidadas[consolidadas.length - 2];
  final estimativa = taxas.where((t) => t.preliminar).firstOrNull;

  /// O ultimo ano antes de `ano` com taxa igual ou maior: "o maior desde 2006".
  int? maiorDesde(int ano, int valor) =>
      consolidadas.where((t) => t.ano < ano && t.km2 >= valor).lastOrNull?.ano;

  final marcos = <Marco>[
    Marco(
      pior.ano,
      'Pior ano da série',
      'A Amazônia Legal perde ${_km2(pior.km2)} de floresta, a maior taxa já '
          'medida pelo INPE.',
    ),
  ];

  // Marcos de politica publica: datas de lei e de acordo, sem numero a
  // conferir.
  final taxa2004 = taxaEm(2004);
  marcos
    ..add(
      Marco(
        2004,
        'Começa o PPCDAm',
        'O governo federal lança o plano de combate ao desmatamento na '
            'Amazônia'
            '${taxa2004 == null ? '' : ', num ano de ${_km2(taxa2004.km2)} desmatados'}.',
      ),
    )
    ..add(
      const Marco(
        2006,
        'Moratória da Soja',
        'Empresas se comprometem a não comprar soja plantada em áreas '
            'desmatadas da Amazônia.',
      ),
    )
    ..add(
      const Marco(
        2012,
        'Novo Código Florestal',
        'A Lei 12.651 substitui o Código Florestal de 1965 e redefine as áreas '
            'que precisam ser preservadas.',
      ),
    )
    ..add(
      Marco(
        minima.ano,
        'Menor taxa da série',
        'O desmatamento na Amazônia Legal cai para ${_km2(minima.km2)}.',
      ),
    );

  if (picoRecente != null && picoRecente.km2 > minima.km2 * 1.5) {
    final desde = maiorDesde(picoRecente.ano, picoRecente.km2);
    marcos.add(
      Marco(
        picoRecente.ano,
        'O desmatamento volta a subir',
        'A Amazônia Legal perde ${_km2(picoRecente.km2)}'
            '${desde == null ? '' : ', o maior valor desde $desde'}.',
      ),
    );
  }

  // O ano em que o PRODES passou a contar mais da metade de um bioma como
  // desmatada. So vale se a serie comeca abaixo da metade: a Mata Atlantica ja
  // estava acima em 2000.
  for (final b in biomas) {
    final medido = prodes[b.nome];
    if (medido == null || medido.acumulado.isEmpty) continue;
    final metade = medido.areaKm2 / 2;
    if (medido.acumulado.first.km2 >= metade) continue;
    final cruzou = medido.acumulado.where((a) => a.km2 >= metade).firstOrNull;
    if (cruzou == null) continue;
    marcos.add(
      Marco(
        cruzou.fim,
        '${b.nome} passa da metade',
        'Mais da metade da vegetação nativa ${b.preposicao} ${b.nome} já foi '
            'desmatada, segundo o PRODES.',
      ),
    );
  }

  final variacao = ((ultima.km2 / anterior.km2 - 1) * 100).round();
  marcos.add(
    Marco(
      ultima.ano,
      'Último dado consolidado',
      'A Amazônia Legal perde ${_km2(ultima.km2)}, ${variacao.abs()}% '
          '${variacao <= 0 ? 'a menos' : 'a mais'} que no ano anterior.',
    ),
  );

  if (estimativa != null) {
    marcos.add(
      Marco(
        estimativa.ano,
        'Estimativa do INPE',
        'A taxa preliminar para a Amazônia Legal é de '
            '${_km2(estimativa.km2)}; o número final sai no ano seguinte.',
      ),
    );
  }

  // Mesmo ano: a ordem em que foram escritos acima (lei antes do numero). O
  // `sort` do Dart nao e estavel, entao o desempate vai explicito.
  final indexados = marcos.indexed.toList()
    ..sort((a, b) {
      final porAno = a.$2.ano.compareTo(b.$2.ano);
      return porAno != 0 ? porAno : a.$1.compareTo(b.$1);
    });
  return [for (final (_, m) in indexados) m];
}

/// Do mais antigo ao mais recente, para a Home.
final linhaDoTempo = calcularLinhaDoTempo(taxasAmazoniaLegal);

/// Os cinco mais recentes, do mais novo ao mais velho, para o painel do mapa.
final linhaDoTempoMapa = linhaDoTempo.reversed.take(5).toList();
