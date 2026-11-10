/// Dados da Home — os mesmos do `dados/inicio.ts` do site.
///
/// Os de desmatamento vem do PRODES (INPE), e a linha do tempo mora em
/// `linha_do_tempo.dart`. As especies e o numero de especies ameacadas vem da
/// lista nacional do MMA (`especies_data.dart`).
library;

import '../models/animal.dart';
import 'animais_data.dart';
import 'biomas_data.dart';
import 'especies_data.dart';
import 'linha_do_tempo.dart';
import 'prodes_data.dart';

/// Endereco do site, para o "Compartilhar" do fim da Home.
const enderecoDoSite = 'https://ecomapbrasil-17756.web.app';

/// Equipe do Projeto Interdisciplinar.
const equipe = <String>[
  'Vinicius',
  'Bruno',
  'Cesar',
  'João Flávio',
  'João Gabriel',
];

/// Uma foto da abertura, que troca sozinha, com o credito que a licenca pede.
class Slide {
  const Slide(this.url, this.rotulo, this.credito);
  final String url;
  final String rotulo;
  final Credito credito;
}

/// As fotos da abertura sao as do catalogo, com o mesmo credito. Ate
/// 10/11/2026 eram quatro arquivos do bucket `animals`, sem origem registrada;
/// desde entao vem do Wikimedia Commons, como no site.
final slides = <Slide>[
  for (final nome in const [
    'Onça-pintada',
    'Arara-azul-de-lear',
    'Lobo-guará',
    'Mico-leão-dourado',
  ])
    _slideDoCatalogo(nome),
];

Slide _slideDoCatalogo(String nome) {
  final animal = animais.firstWhere((a) => a.nome == nome);
  return Slide(animal.imagem, animal.nome, animal.credito!);
}

/// A foto da secao final da Home ("Passe adiante"), a mesma do site: queimada
/// perto da Flona do Jacunda (RO), em 07/08/2020. A licenca CC BY pede credito,
/// que aparece na propria secao.
const fotoDaChamadaFinal =
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/da/SOBREVVO_EM_RONDONIA_DIA_07-08-2020_%28FOTO_BRUNO_KELLY%29_%2835%29_%2850224380121%29.jpg/1920px-SOBREVVO_EM_RONDONIA_DIA_07-08-2020_%28FOTO_BRUNO_KELLY%29_%2835%29_%2850224380121%29.jpg';
const creditoDaChamadaFinal = Credito(
  autor: 'Bruno Kelly/Amazônia Real',
  licenca: 'CC BY 2.0',
  link: 'https://commons.wikimedia.org/wiki/File:SOBREVVO_EM_RONDONIA_DIA_07-08-2020_(FOTO_BRUNO_KELLY)_(35)_(50224380121).jpg',
);

/// Os quatro numeros da faixa escura. O valor e texto: o `Contador` conta so
/// a parte numerica e mantem o resto ("−20%", "6 biomas").
class Numero {
  const Numero(this.valor, this.rotulo);
  final String valor;
  final String rotulo;
}

/// As seis primeiras ameacadas do catalogo (a secao e "Espécies ameaçadas").
/// Ate 28/10/2026 a Home tinha a propria
/// lista, com fotos de sites de terceiros e uma "queda da populacao" sem
/// fonte em cada cartao.
final animaisDestaque = animais.where((a) => a.ehAmeacada).take(6).toList();

class Solucao {
  const Solucao(this.titulo, this.texto);
  final String titulo;
  final String texto;
}

const solucoes = <Solucao>[
  Solucao(
    'Consumo consciente',
    'Evite produtos que contribuem para o desmatamento, como carne de origem '
        'duvidosa, madeira ilegal e óleo de palma não sustentável.',
  ),
  Solucao(
    'Apoie organizações',
    'Contribua com instituições que trabalham para preservar os biomas '
        'brasileiros e combater o desmatamento ilegal.',
  ),
  Solucao(
    'Engajamento político',
    'Apoie políticas públicas e candidatos comprometidos com a preservação '
        'ambiental e o desenvolvimento sustentável.',
  ),
  Solucao(
    'Reflorestamento',
    'Participe de iniciativas de plantio de árvores nativas e recuperação de '
        'áreas degradadas em sua região.',
  ),
  Solucao(
    'Educação ambiental',
    'Divulgue informações sobre a importância da preservação e os impactos '
        'do desmatamento em sua comunidade.',
  ),
  // Ate 02/11/2026 mandava usar o aplicativo "Denúncia Ambiente", que nao
  // aparece em canal oficial nenhum. Os canais estao em `denuncia_data.dart`.
  Solucao(
    'Denuncie',
    'Viu desmatamento, caça ou queimada ilegal? O Ibama recebe a denúncia '
        'pela internet ou por telefone, e dá para não se identificar. Os '
        'canais estão logo abaixo.',
  ),
];

// ── Desmatamento, calculado do PRODES (prodes_data.dart) ──
//
// Ate 28/10/2026 estes numeros eram de referencia, herdados do React ("+30%
// na ultima decada", Amazonia com 780 mil km² desmatados). Agora saem do que o
// INPE mediu.

/// 2025 -> "ago/2024 a jul/2025": o ano do PRODES vai de agosto a julho.
String _periodoPorExtenso(int fim) => 'ago/${fim - 1} a jul/$fim';

/// O periodo mais recente que os seis biomas ja tem consolidado. Cada bioma e
/// mapeado no seu ritmo, e somar anos diferentes daria um total que nao existe.
final int _fimComum = () {
  final candidatos = [
    for (final p in prodes['Amazônia']?.anos ?? const <PeriodoProdes>[])
      if (biomas.every((b) => prodes[b.nome]?.noPeriodo(p.fim) != null)) p.fim,
  ];
  if (candidatos.isEmpty) {
    throw StateError('PRODES sem um período comum aos seis biomas');
  }
  return candidatos.reduce((a, b) => a > b ? a : b);
}();

double _totalNoPeriodo(int fim) =>
    biomas.fold(0, (s, b) => s + (prodes[b.nome]?.noPeriodo(fim) ?? 0));

/// Variacao do total dos seis biomas sobre o periodo anterior, em %; `null`
/// quando algum bioma nao foi medido no anterior.
int? get _variacao {
  final temAnterior = biomas.every(
    (b) => prodes[b.nome]?.noPeriodo(_fimComum - 1) != null,
  );
  if (!temAnterior) return null;
  return ((_totalNoPeriodo(_fimComum) / _totalNoPeriodo(_fimComum - 1) - 1) *
          100)
      .round();
}

final numeros = <Numero>[
  Numero(
    formatarMilhar(_totalNoPeriodo(_fimComum)),
    'km² de vegetação nativa desmatados nos seis biomas de '
    '${_periodoPorExtenso(_fimComum)}',
  ),
  if (_variacao case final v?)
    Numero(
      // Sinal de menos tipografico (−), nao o hifen.
      '${v > 0
          ? '+'
          : v < 0
          ? '−'
          : ''}${v.abs()}%',
      'no desmatamento dos seis biomas em relação a '
          '${_periodoPorExtenso(_fimComum - 1)}',
    ),
  Numero(
    formatarMilhar(listaNacional.ameacadas),
    'Espécies da fauna ameaçadas de extinção no Brasil, segundo a lista '
    'nacional do MMA',
  ),
  const Numero('6 biomas', 'Biomas brasileiros afetados pelo desmatamento'),
];

/// Area ja desmatada por bioma, em mil km² — a serie do grafico de barras,
/// da maior para a menor.
class ValorBioma {
  const ValorBioma(this.nome, this.valor);
  final String nome;
  final int valor;
}

final areaPorBioma = [
  for (final b in biomas)
    ValorBioma(b.nome, ((prodes[b.nome]?.acumuladoKm2 ?? 0) / 1000).round()),
]..sort((a, b) => b.valor.compareTo(a.valor));

/// Quanto cada bioma perdeu no periodo comum mais recente, do que mais perdeu
/// ao que menos perdeu. Substituiu a "comparacao por regiao" do React, cujos
/// percentuais nao vinham de fonte nenhuma.
final ultimoPeriodo = (
  rotulo: _periodoPorExtenso(_fimComum),
  biomas: [
    for (final b in biomas)
      (nome: b.nome, km2: prodes[b.nome]?.noPeriodo(_fimComum) ?? 0.0),
  ]..sort((a, b) => b.km2.compareTo(a.km2)),
);

const _meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// "16 de outubro de 2026", para a nota de fonte.
final dadosAtualizadosEm = () {
  final d = DateTime.parse(prodesAtualizadoEm);
  return '${d.day} de ${_meses[d.month - 1]} de ${d.year}';
}();
