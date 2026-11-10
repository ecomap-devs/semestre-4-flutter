/// Como denunciar um crime ambiental, pelos canais oficiais — copia do
/// `src/dados/denuncia.ts` do site. Conferido em 29/10/2026 na pagina de
/// servico do gov.br, "Apresentar denúncia ambiental" (ultima modificacao la:
/// 03/09/2026). Telefone, horario ou endereco mudou? Troque no site e aqui,
/// com a data nova.
///
/// Ate 02/11/2026 o app mandava usar um aplicativo "Denúncia Ambiente", que nao
/// aparece em nenhum canal oficial; o site tinha trocado em 29/10.
library;

/// A pagina oficial de onde saem os canais.
const fonteDenuncia = (
  rotulo: 'gov.br, Apresentar denúncia ambiental',
  link: 'https://www.gov.br/pt-br/servicos/apresentar-denuncia-ambiental',
  conferidoEm: '29 de outubro de 2026',
);

/// Um canal de denuncia. O contato e tocavel: o numero abre o discador, e o
/// site abre no navegador. Ate 10/11/2026 o app nao abria links, e o canal
/// guardava o endereco por extenso (`endereco`) em vez do `link` do site.
class CanalDenuncia {
  const CanalDenuncia({
    required this.titulo,
    required this.contato,
    required this.link,
    required this.texto,
  });

  final String titulo;

  /// O que mostrar em destaque: o numero ou o nome do site.
  final String contato;

  /// `tel:` ou `https:`.
  final String link;
  final String texto;
}

const canaisDenuncia = <CanalDenuncia>[
  CanalDenuncia(
    titulo: 'Pela internet',
    contato: 'Fala.BR',
    link: 'https://falabr.cgu.gov.br/v2/',
    texto:
        'A plataforma de ouvidoria do governo federal, que encaminha ao Ibama. '
        'Pede login gov.br, e a denúncia identificada pode ser acompanhada até '
        'a resposta.',
  ),
  CanalDenuncia(
    titulo: 'Por telefone',
    contato: '0800 061 8080',
    link: 'tel:08000618080',
    texto:
        'Central de Atendimento do Ibama, ligação gratuita. De segunda a sexta, '
        'exceto feriados, das 7h às 19h.',
  ),
  CanalDenuncia(
    titulo: 'Está acontecendo agora',
    contato: '190',
    link: 'tel:190',
    texto:
        'Desmatamento, caça ou queimada em andamento é caso de polícia: a '
        'Polícia Militar aciona o policiamento ambiental do estado. Para fogo, '
        'os bombeiros atendem no 193.',
  ),
];

/// O que a pagina do gov.br pede para a denuncia nao ser arquivada.
const oQueInformar = <String>[
  'Município, estado e o endereço exato, com pontos de referência ou '
      'coordenadas',
  'Nome da propriedade, da estrada e o quilômetro, se houver',
  'O que está sendo destruído: mata, rio, animais',
  'Quem está fazendo, se souber, e veículos ou máquinas usados',
  'Fotos, vídeos ou áudios',
  'O protocolo, se já denunciou em outro órgão',
];

const sobreAnonimato =
    'Dá para denunciar sem se identificar. Nesse caso não há como acompanhar o '
    'andamento, e o Ibama não consegue pedir mais detalhes: sem as informações '
    'acima, a denúncia é arquivada.';
