/// Status de conservacao das especies do catalogo — copia do
/// `src/dados/especies.ts` do site, que o `scripts/especies/gerar.mjs` de la
/// gera. Nao edite a mao: quando o site atualizar, copie de novo.
///
/// Lista nacional: CSV de fauna ameacada do Portal de Dados Abertos do MMA (a
/// avaliacao da Portaria MMA nº 148/2022). Lista Vermelha da IUCN: pela API do
/// GBIF.
library;

/// A lista nacional de fauna ameacada, no CSV mais recente do MMA.
const listaNacional = (
  // Ano da avaliacao no CSV do MMA.
  ano: 2021,

  // Quando o MMA publicou o CSV no portal.
  publicadaEm: '2023-06-16',

  // Especies e subespecies da fauna em CR, EN ou VU.
  ameacadas: 1259,
  fonte: 'dados.mma.gov.br/dataset/especies-ameacadas',
);

/// Categoria na lista nacional (EX, EW, RE, CR, EN ou VU; `null` = fora da
/// lista) e na IUCN (`null` = nao avaliada), pelo nome cientifico.
const statusEspecies = <String, ({String? nacional, String? iucn})>{
  'Panthera onca': (nacional: 'VU', iucn: 'NT'),
  'Anodorhynchus leari': (nacional: 'EN', iucn: 'EN'),
  'Leontopithecus rosalia': (nacional: 'EN', iucn: 'EN'),
  'Chrysocyon brachyurus': (nacional: 'VU', iucn: 'NT'),
  'Myrmecophaga tridactyla': (nacional: 'VU', iucn: 'VU'),
  'Inia geoffrensis': (nacional: 'EN', iucn: 'EN'),
  'Cyanopsitta spixii': (nacional: 'CR', iucn: 'EW'),
  'Saguinus bicolor': (nacional: 'CR', iucn: 'CR'),
  'Ateles marginatus': (nacional: 'EN', iucn: 'EN'),
  'Guaruba guarouba': (nacional: 'VU', iucn: 'VU'),
  'Trichechus inunguis': (nacional: 'VU', iucn: 'VU'),
  'Harpia harpyja': (nacional: 'VU', iucn: 'VU'),
  'Bradypus variegatus': (nacional: null, iucn: 'LC'),
  'Ara chloropterus': (nacional: null, iucn: 'LC'),
  'Eunectes murinus': (nacional: null, iucn: 'LC'),
  'Mergus octosetaceus': (nacional: 'CR', iucn: 'CR'),
  'Priodontes maximus': (nacional: 'VU', iucn: 'VU'),
  'Tapirus terrestris': (nacional: 'VU', iucn: 'VU'),
  'Speothos venaticus': (nacional: 'VU', iucn: 'NT'),
  'Ramphastos toco': (nacional: null, iucn: 'LC'),
  'Cariama cristata': (nacional: null, iucn: 'LC'),
  'Ara ararauna': (nacional: null, iucn: 'LC'),
  'Brachyteles hypoxanthus': (nacional: 'CR', iucn: 'CR'),
  'Aburria jacutinga': (nacional: 'EN', iucn: null),
  'Leopardus guttulus': (nacional: 'VU', iucn: 'VU'),
  'Ramphastos dicolorus': (nacional: null, iucn: 'LC'),
  'Cyanocorax caeruleus': (nacional: null, iucn: 'NT'),
  'Nasua nasua': (nacional: null, iucn: 'LC'),
  'Antilophia bokermanni': (nacional: 'CR', iucn: 'CR'),
  'Tolypeutes tricinctus': (nacional: 'EN', iucn: 'VU'),
  'Kerodon rupestris': (nacional: 'VU', iucn: 'LC'),
  'Callithrix jacchus': (nacional: null, iucn: 'LC'),
  'Patagioenas picazuro': (nacional: null, iucn: 'LC'),
  'Caracara plancus': (nacional: null, iucn: 'LC'),
  'Blastocerus dichotomus': (nacional: 'VU', iucn: 'VU'),
  'Pteronura brasiliensis': (nacional: 'VU', iucn: null),
  'Jabiru mycteria': (nacional: null, iucn: 'LC'),
  'Caiman yacare': (nacional: null, iucn: 'LC'),
  'Hydrochoerus hydrochaeris': (nacional: null, iucn: 'LC'),
  'Xanthopsar flavus': (nacional: 'VU', iucn: 'EN'),
  'Gubernatrix cristata': (nacional: 'CR', iucn: 'EN'),
  'Ctenomys flamarioni': (nacional: 'EN', iucn: 'EN'),
  'Rhea americana': (nacional: null, iucn: 'NT'),
  'Vanellus chilensis': (nacional: null, iucn: 'LC'),
  'Lycalopex gymnocercus': (nacional: null, iucn: 'LC'),
};

/// Nome das categorias da lista nacional, como o site as mostra.
const nomeNacional = <String, String>{
  'EX': 'Extinta',
  'EW': 'Extinta na natureza',
  'RE': 'Regionalmente extinta',
  'CR': 'Criticamente em perigo',
  'EN': 'Em perigo',
  'VU': 'Vulnerável',
};

/// Nome das categorias da IUCN em portugues, como o ICMBio as traduz.
const nomeIucn = <String, String>{
  'EX': 'Extinta',
  'EW': 'Extinta na natureza',
  'CR': 'Criticamente em perigo',
  'EN': 'Em perigo',
  'VU': 'Vulnerável',
  'NT': 'Quase ameaçada',
  'LC': 'Menos preocupante',
  'DD': 'Dados insuficientes',
};
