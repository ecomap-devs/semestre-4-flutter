/// Dados estaticos da Home — os mesmos do `dados/inicio.ts` do site.
///
/// Sao valores de referencia herdados do React, nao numeros oficiais (README,
/// "Sobre os dados").
library;

const _supabaseAnimais =
    'https://wqvxjttidoxcblkfjoaf.supabase.co/storage/v1/object/public/animals';

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

/// Fotos da abertura, que trocam sozinhas.
class Slide {
  const Slide(this.url, this.rotulo);
  final String url;
  final String rotulo;
}

const slides = <Slide>[
  Slide('$_supabaseAnimais/onca-pintada.png', 'Onça-pintada'),
  Slide('$_supabaseAnimais/arara-azul-de-lear_01_0.png', 'Arara-azul'),
  Slide('$_supabaseAnimais/lobo-guara.png', 'Lobo-guará'),
  Slide('$_supabaseAnimais/micoleao-cke.png', 'Mico-leão-dourado'),
];

/// Os quatro numeros da faixa escura. O valor e texto: o `Contador` conta so
/// a parte numerica e mantem o resto ("+30%", "1,5 mi ha").
class Numero {
  const Numero(this.valor, this.rotulo);
  final String valor;
  final String rotulo;
}

const numeros = <Numero>[
  Numero('+30%', 'Aumento no desmatamento na última década'),
  Numero('1,5 mi ha', 'Área queimada anualmente no Brasil'),
  Numero('1.173', 'Espécies animais ameaçadas de extinção'),
  Numero('6 biomas', 'Biomas brasileiros afetados pelo desmatamento'),
];

/// Especie em destaque na Home, com a queda da populacao sobre a foto.
class AnimalDestaque {
  const AnimalDestaque({
    required this.nome,
    required this.status,
    required this.descricao,
    required this.bioma,
    required this.populacao,
    required this.imagem,
  });

  final String nome;
  final String status;
  final String descricao;
  final String bioma;

  /// Variacao da populacao, como "-60%".
  final String populacao;

  /// Links diretos para sites de terceiros, como no React. Se algum sair do
  /// ar, o cartao cai num placeholder.
  final String imagem;
}

const animaisDestaque = <AnimalDestaque>[
  AnimalDestaque(
    nome: 'Onça-pintada',
    status: 'Criticamente ameaçada',
    descricao:
        'Perdeu 50% de seu habitat na Mata Atlântica nos últimos 15 anos.',
    bioma: 'Mata Atlântica',
    populacao: '-60%',
    imagem: 'https://static.biologianet.com/2020/05/onca-pintada.jpg',
  ),
  AnimalDestaque(
    nome: 'Arara-azul',
    status: 'Em perigo',
    descricao:
        'Apenas 6.500 indivíduos restantes devido à perda de habitat no '
        'Pantanal.',
    bioma: 'Pantanal',
    populacao: '-40%',
    imagem:
        'https://imagens.ebc.com.br/7mrmO9tFuEk0CPiJHKLEqTCk9R4=/1170x700/'
        'smart/https://agenciabrasil.ebc.com.br/sites/default/files/'
        'thumbnails/image/2024/09/18/arara-azul-de-lear_01_0.jpg'
        '?itok=wDa3CBCI',
  ),
  AnimalDestaque(
    nome: 'Mico-leão-dourado',
    status: 'Criticamente ameaçada',
    descricao:
        'Restam apenas 2.500 indivíduos na natureza devido ao desmatamento.',
    bioma: 'Mata Atlântica',
    populacao: '-70%',
    imagem: 'https://static.todamateria.com.br/upload/mi/co/micoleao-cke.jpg',
  ),
  AnimalDestaque(
    nome: 'Lobo-guará',
    status: 'Vulnerável',
    descricao: 'Perdeu 30% de seu habitat no Cerrado nos últimos 20 anos.',
    bioma: 'Cerrado',
    populacao: '-35%',
    imagem:
        'https://s3.static.brasilescola.uol.com.br/be/2020/08/lobo-guara.jpg',
  ),
  AnimalDestaque(
    nome: 'Tucano-de-bico-preto',
    status: 'Em perigo',
    descricao: 'População em declínio devido à fragmentação florestal.',
    bioma: 'Amazônia',
    populacao: '-25%',
    imagem:
        'https://www.parquedasaves.com.br/wp-content/uploads/2019/08/'
        'large-6.jpg',
  ),
  AnimalDestaque(
    nome: 'Perereca-verde-da-mata',
    status: 'Criticamente ameaçada',
    descricao: 'Endêmica de pequenas áreas ameaçadas pelo desmatamento.',
    bioma: 'Mata Atlântica',
    populacao: '-80%',
    imagem:
        'https://portal.pcs.ifsuldeminas.edu.br/images/campus_pocos_caldas/'
        'noticias/2020/junho/20200630/perereca-folhagem/figura_1.jpg',
  ),
];

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
  Solucao(
    'Denuncie',
    'Use aplicativos como "Denúncia Ambiente" para reportar atividades '
        'ilegais de desmatamento que você identificar.',
  ),
];

class ItemLinhaTempo {
  const ItemLinhaTempo(this.ano, this.titulo, this.texto);
  final String ano;
  final String titulo;
  final String texto;
}

const linhaDoTempo = <ItemLinhaTempo>[
  ItemLinhaTempo(
    '2005',
    'Pampa sofre impactos crescentes',
    'Expansão agropecuária avança sobre os campos nativos',
  ),
  ItemLinhaTempo(
    '2010',
    'Caatinga afetada',
    'Caatinga tem 45% de sua área original desmatada',
  ),
  ItemLinhaTempo(
    '2013',
    'Novo Código Florestal',
    'Brasil aprova novo Código Florestal com impacto nos biomas',
  ),
  ItemLinhaTempo(
    '2015',
    'Queimadas no Pantanal',
    'Pantanal perde 12% de sua área para queimadas',
  ),
  ItemLinhaTempo(
    '2018',
    'Mata Atlântica reduzida',
    'Mata Atlântica tem apenas 12,4% de sua cobertura original',
  ),
  ItemLinhaTempo(
    '2020',
    'Perdas no Cerrado',
    'Cerrado perde 7.340 km² de vegetação nativa',
  ),
  ItemLinhaTempo(
    '2022',
    'Seca no Pantanal',
    'Pantanal enfrenta pior seca em décadas',
  ),
  ItemLinhaTempo(
    '2023',
    'Recorde de desmatamento',
    'Recorde de desmatamento na Amazônia: 11.568 km²',
  ),
];

/// Area desmatada por bioma, em mil km² — a serie do grafico de barras.
class ValorBioma {
  const ValorBioma(this.nome, this.valor);
  final String nome;
  final int valor;
}

const areaPorBioma = <ValorBioma>[
  ValorBioma('Amazônia', 780),
  ValorBioma('Cerrado', 520),
  ValorBioma('Mata Atlântica', 320),
  ValorBioma('Caatinga', 150),
  ValorBioma('Pantanal', 90),
  ValorBioma('Pampa', 60),
];

/// Percentual desmatado por regiao.
const comparacaoRegional = <(String, int)>[
  ('Norte (Amazônia)', 78),
  ('Centro-Oeste (Cerrado/Pantanal)', 45),
  ('Nordeste (Caatinga)', 15),
  ('Sudeste/Sul (Mata Atlântica/Pampa)', 32),
];
