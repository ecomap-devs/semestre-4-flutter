// GERADO por tool/legal/copiar.mjs a partir do src/dados/legal.ts do
// semestre-4-nextjs. Nao edite a mao: mude o texto no site e copie de novo.
//
// A politica de privacidade e os termos de uso valem para o site e para o app.

import '../models/documento_legal.dart';

/// A data da versao em vigor dos dois documentos.
const atualizadoEm = '10 de novembro de 2026';

/// Onde fazer pedidos sobre dados: issue publica, com o modelo que avisa para
/// nao escrever dado pessoal.
const contatoDados =
    'https://github.com/ecomap-devs/semestre-4-nextjs/issues/new?template=pedido-de-dados.md';

const privacidade = DocumentoLegal(
  titulo: 'Política de privacidade',
  descricao: 'O que o EcoMapBrasil guarda sobre você, onde fica, quem mais recebe e como pedir para ver, corrigir ou apagar.',
  abertura: 'Vale para o site [ecomapbrasil-17756.web.app](https://ecomapbrasil-17756.web.app) e para o app Android. Sem conta, nada sobre você fica com a gente; com conta, esta página diz exatamente o que fica, onde e até quando.',
  secoes: [
    SecaoLegal(
      id: 'quem-somos',
      titulo: 'Quem cuida dos seus dados',
      blocos: [
        ParagrafoLegal(
          'O EcoMapBrasil é o Projeto Interdisciplinar de cinco estudantes do curso de Desenvolvimento de Software Multiplataforma da FATEC: Vinicius, Bruno, Cesar, João Flávio e João Gabriel. É um projeto acadêmico, sem fins lucrativos e sem anúncios. O grupo decide o que o site e o app fazem com os dados: na Lei Geral de Proteção de Dados (LGPD, Lei 13.709/2018), é o **controlador**.',
        ),
        ParagrafoLegal(
          'Para qualquer pedido sobre os seus dados, veja [Seus direitos e como pedir](#direitos).',
        ),
      ],
    ),
    SecaoLegal(
      id: 'resumo',
      titulo: 'Em resumo',
      blocos: [
        ListaLegal([
          '**Sem conta**, dá para usar o mapa, os gráficos, o catálogo de espécies, o quiz e a seção de denúncia, e nada sobre você fica com a gente.',
          '**Não usamos** cookies de rastreamento, ferramentas de audiência nem anúncios, e não vendemos nem cedemos dados para marketing.',
          '**A avaliação é pública**: o nome, a foto de perfil, a nota e o comentário aparecem para qualquer pessoa, mesmo sem login.',
          '**A foto de identificação** vai para o Gemini, do Google, sem a localização e os outros metadados, e não fica guardada com a gente.',
          '**Para apagar** a conta, uma avaliação ou a foto de perfil, hoje é preciso pedir à equipe: o site e o app ainda não têm esse botão.',
        ]),
      ],
    ),
    SecaoLegal(
      id: 'o-que-guardamos',
      titulo: 'O que guardamos, onde e até quando',
      blocos: [
        TabelaLegal(
          colunas: ['Dado', 'Onde fica', 'Quem vê', 'Até quando'],
          linhas: [
            [
              'E-mail e senha',
              'Firebase Authentication, do Google. A senha fica só como um código (hash) que não permite recuperá-la',
              'Você. A equipe vê o e-mail no painel do Firebase; a senha, ninguém',
              'Até a conta ser apagada',
            ],
            [
              'Nome e foto de perfil',
              'Firebase Authentication e o documento `usuarios/{sua conta}` do Firestore, com a data do cadastro',
              'O documento, só você. O nome e a foto também aparecem em público junto da sua avaliação',
              'Até a conta ser apagada',
            ],
            [
              'Arquivo da foto de perfil',
              'Bucket `avatars` do Supabase Storage, gravado pela função `enviar-avatar`: uma foto por conta, redesenhada em até 512 px e sem metadados, inclusive a localização',
              'Qualquer pessoa que tenha o endereço do arquivo',
              'Até você pedir para apagar',
            ],
            [
              'Avaliação: nota, comentário, nome, foto, datas e o identificador da sua conta',
              'Coleção `avaliacoes` do Firestore',
              'Qualquer pessoa, mesmo sem login',
              'Até você pedir para apagar. Dá para editar quando quiser',
            ],
            [
              'Uso da identificação por foto: o identificador da conta e quantas fotos você mandou no minuto e no dia',
              'Tabela `uso_identificacao` do Supabase',
              'Só a equipe',
              'Uma linha por conta, sobrescrita a cada uso e apagada com a conta',
            ],
            [
              'Uso do envio da foto de perfil: o identificador da conta e quantas fotos de perfil você mandou no dia',
              'Tabela `uso_avatar` do Supabase',
              'Só a equipe',
              'Uma linha por conta, sobrescrita a cada envio e apagada com a conta',
            ],
            [
              'Foto enviada para identificação',
              'Não fica com a gente: a função `identificar-animal`, no Supabase, repassa a foto ao Gemini e devolve a resposta',
              'O Google, como explicado em [Com quem os dados passam](#compartilhamento)',
              'Pelas regras do Google',
            ],
            [
              'Login aberto',
              'No seu navegador (IndexedDB, base `firebaseLocalStorageDb`) ou no armazenamento do app no celular',
              'Só você, no seu aparelho',
              'Até você sair da conta',
            ],
            [
              'Registros técnicos: endereço IP, navegador, horário e o endereço pedido',
              'Registros (logs) do Firebase Hosting e do Supabase',
              'Os provedores e a equipe, para corrigir erros e conter abuso',
              'Pelos prazos de cada provedor',
            ],
          ],
        ),
      ],
    ),
    SecaoLegal(
      id: 'para-que',
      titulo: 'Para que usamos',
      blocos: [
        ListaLegal([
          '**Conta e avaliações**: para criar a sua conta, mostrar quem avaliou e deixar só você mexer na sua avaliação. É o serviço que você pediu ao se cadastrar (LGPD, art. 7º, V).',
          '**Identificação por foto**: para dizer qual animal está na foto, que é o que você pediu ao enviá-la (art. 7º, V).',
          '**Contadores de uso**: para limitar cada conta a 5 fotos por minuto e 30 por dia na identificação, para a cota gratuita do Gemini não acabar para todos, e a 5 fotos de perfil por dia, para o espaço de armazenamento do projeto não ser tomado por envios em massa. É o legítimo interesse do projeto em manter os recursos funcionando (art. 7º, IX).',
          '**Registros técnicos**: segurança e correção de erros (art. 7º, IX).',
          'Nunca para publicidade, perfil de comportamento ou venda de dados.',
        ]),
      ],
    ),
    SecaoLegal(
      id: 'compartilhamento',
      titulo: 'Com quem os dados passam',
      blocos: [
        ParagrafoLegal(
          'O EcoMapBrasil não tem servidor próprio: funciona sobre os serviços abaixo, que recebem dados para fazer o trabalho deles. Os servidores podem ficar fora do Brasil (transferência internacional, LGPD, art. 33), e cada serviço tem a própria política de privacidade.',
        ),
        TabelaLegal(
          colunas: ['Serviço', 'Para quê', 'O que recebe'],
          linhas: [
            [
              '[Google Firebase](https://firebase.google.com/support/privacy): Authentication, Firestore e Hosting',
              'A conta, as avaliações e a hospedagem do site',
              'E-mail, nome, foto, avaliações e os registros técnicos de quem abre o site',
            ],
            [
              '[Supabase](https://supabase.com/privacy): Storage, Edge Functions e banco',
              'As fotos das espécies e de perfil, a identificação por foto e o contador de uso',
              'A foto de perfil, a foto de identificação (só de passagem), o identificador da conta e registros técnicos',
            ],
            [
              '[Google Gemini](https://ai.google.dev/gemini-api/terms), pela cota gratuita da API',
              'Dizer qual animal está na foto',
              'A foto, reduzida a 1024 px e sem metadados. **Na cota gratuita, o Google usa o que recebe para melhorar os produtos dele, e revisores humanos podem ver o conteúdo.** Por isso, não envie fotos de pessoas, documentos ou qualquer coisa pessoal',
            ],
            [
              '[Esri](https://www.esri.com/en-us/privacy/overview), ArcGIS Online',
              'Os fundos do mapa, claro e satélite',
              'Seu endereço IP e a área do mapa que você vê, como em qualquer mapa da web',
            ],
            [
              '[Wikimedia Commons](https://foundation.wikimedia.org/wiki/Policy:Privacy_policy)',
              'Parte das fotos das espécies e a foto da seção final da página inicial',
              'Seu endereço IP, como em qualquer imagem da web',
            ],
            [
              '[GitHub](https://docs.github.com/pt/site-policy/privacy-policies/github-general-privacy-statement)',
              'O código do projeto e o canal de pedidos',
              'O que você escrever numa issue, que é pública',
            ],
          ],
        ),
      ],
    ),
    SecaoLegal(
      id: 'o-que-nao-fazemos',
      titulo: 'O que o site e o app não fazem',
      blocos: [
        ListaLegal([
          'Não usam cookies de rastreamento, Google Analytics nem outra ferramenta de audiência, e não mostram anúncios. A única coisa que o site grava no seu navegador é o login, enquanto você estiver na conta.',
          'Não pedem a sua localização. O mapa mostra o Brasil inteiro, não onde você está.',
          'O app não pede acesso a contatos, localização ou microfone. A câmera e a galeria abrem pelo seletor do próprio Android, só quando você escolhe tirar ou enviar uma foto.',
          'O quiz não grava nada: o placar some quando você sai da página.',
          'Compartilhar e copiar o link usam o seu próprio aparelho; nada passa pela equipe.',
        ]),
      ],
    ),
    SecaoLegal(
      id: 'direitos',
      titulo: 'Seus direitos e como pedir',
      blocos: [
        ParagrafoLegal(
          'Pela LGPD (art. 18), você pode pedir para confirmar se temos dados seus, ver quais são, corrigir, apagar, saber com quem foram compartilhados e levá-los para outro serviço.',
        ),
        ParagrafoLegal(
          'No próprio site e no app você já edita a sua avaliação. Apagar a conta, a avaliação ou a foto de perfil, por enquanto, só a equipe consegue.',
        ),
        ParagrafoLegal(
          '**Como pedir:** abra uma [issue no GitHub](https://github.com/ecomap-devs/semestre-4-nextjs/issues/new?template=pedido-de-dados.md) **sem escrever e-mail, nome completo ou outro dado pessoal**, porque a issue é pública. Diga só o que você quer, por exemplo "apagar a minha conta". A equipe responde ali mesmo, em até 15 dias, e combina como confirmar que a conta é sua sem expor nada.',
        ),
        ParagrafoLegal(
          'Se achar que o pedido não foi atendido, você também pode reclamar à [Autoridade Nacional de Proteção de Dados (ANPD)](https://www.gov.br/anpd).',
        ),
      ],
    ),
    SecaoLegal(
      id: 'idade',
      titulo: 'Idade',
      blocos: [
        ListaLegal([
          '**Identificação por foto: só a partir de 18 anos.** É uma exigência dos [termos do Gemini](https://ai.google.dev/gemini-api/terms), o serviço do Google que reconhece o animal.',
          '**Conta e avaliações**: quem tem menos de 18 anos precisa da autorização de um responsável.',
          'Sem conta, o site e o app servem para qualquer idade.',
        ]),
      ],
    ),
    SecaoLegal(
      id: 'seguranca',
      titulo: 'Segurança',
      blocos: [
        ListaLegal([
          'Tudo trafega por HTTPS.',
          'As regras do banco deixam só você criar, editar ou apagar a sua avaliação e ler o seu perfil, e conferem o formato de cada campo.',
          'A foto de perfil só sobe com a conta conectada, por uma função no servidor que confere se o arquivo é mesmo uma imagem e limita os envios por dia. Ela fica no bucket do próprio projeto, e um arquivo enviado não pode ser sobrescrito.',
          'A função de identificação só aceita pedido de quem está logado, e a chave do Gemini fica no servidor, nunca no site ou no app.',
          'Se acontecer um incidente com os seus dados, avisamos nesta página e à ANPD, como a LGPD manda.',
        ]),
      ],
    ),
    SecaoLegal(
      id: 'mudancas',
      titulo: 'Mudanças nesta política',
      blocos: [
        ParagrafoLegal(
          'Quando o site ou o app passarem a guardar ou enviar algo novo, esta página muda junto, e a data no alto também. O histórico de cada versão fica [no GitHub](https://github.com/ecomap-devs/semestre-4-nextjs/commits/main/src/dados/legal.ts). Veja também os [termos de uso](/termos).',
        ),
      ],
    ),
  ],
);

const termos = DocumentoLegal(
  titulo: 'Termos de uso',
  descricao: 'As regras para usar o EcoMapBrasil: o que ele é e o que não é, a conta, as avaliações, a identificação por foto e os créditos dos dados.',
  abertura: 'Valem para o site e para o app Android. Ao usar o EcoMapBrasil, e principalmente ao criar uma conta, você concorda com estes termos e com a [política de privacidade](/privacidade).',
  secoes: [
    SecaoLegal(
      id: 'o-que-e',
      titulo: 'O que é o EcoMapBrasil',
      blocos: [
        ParagrafoLegal(
          'Um projeto acadêmico de cinco estudantes da FATEC, o Projeto Interdisciplinar do curso de Desenvolvimento de Software Multiplataforma, sem fins lucrativos e sem anúncios. **Não é um serviço do governo**, do INPE, do Ministério do Meio Ambiente nem de nenhum órgão ambiental.',
        ),
        ParagrafoLegal(
          'Os números vêm de fontes públicas e oficiais, mas chegam aqui com atraso (o site os atualiza uma vez por mês) e podem ter erro de cópia ou de cálculo nosso. Para estudo, citação ou qualquer decisão, confira na fonte, que o site indica junto de cada número.',
        ),
      ],
    ),
    SecaoLegal(
      id: 'conta',
      titulo: 'Conta',
      blocos: [
        ListaLegal([
          'É preciso ter conta, com e-mail e senha, para avaliar e para identificar animais por foto.',
          'Use um nome que não se passe por outra pessoa. A senha é sua responsabilidade: não a compartilhe.',
          'Quem tem menos de 18 anos só pode criar conta com a autorização de um responsável.',
          'Para apagar a conta, veja [como pedir](/privacidade#direitos).',
        ]),
      ],
    ),
    SecaoLegal(
      id: 'avaliacoes',
      titulo: 'Avaliações',
      blocos: [
        ParagrafoLegal(
          'Cada conta tem uma avaliação, que aparece em público com o seu nome e a sua foto de perfil. Você pode editá-la quando quiser. Não é permitido publicar:',
        ),
        ListaLegal([
          'ofensa, discriminação, ameaça ou assédio;',
          'dados pessoais de outra pessoa, como telefone, endereço ou documento;',
          'propaganda, corrente ou link para golpe ou programa malicioso;',
          'qualquer coisa ilegal.',
        ]),
        ParagrafoLegal(
          'A equipe pode apagar a avaliação que descumprir estas regras e, se acontecer de novo, a conta.',
        ),
      ],
    ),
    SecaoLegal(
      id: 'identificacao',
      titulo: 'Identificação por foto',
      blocos: [
        ListaLegal([
          '**Só a partir de 18 anos**, por exigência dos [termos do Gemini](https://ai.google.dev/gemini-api/terms), o serviço do Google que reconhece o animal.',
          '**A resposta é de uma inteligência artificial e pode estar errada.** Não use para decidir se um animal é peçonhento ou perigoso, nem como motivo para chegar perto, tocar, capturar ou alimentar. Em caso de acidente com animal, procure atendimento médico na hora.',
          'Não envie fotos de pessoas, documentos ou qualquer coisa pessoal: a foto vai para o Google, que pode usá-la (veja a [política de privacidade](/privacidade#compartilhamento)).',
          'Cada conta pode enviar até 5 fotos por minuto e 30 por dia. O recurso usa a cota gratuita do Gemini e pode ficar fora do ar quando ela acaba.',
        ]),
      ],
    ),
    SecaoLegal(
      id: 'denuncias',
      titulo: 'Denúncias',
      blocos: [
        ParagrafoLegal(
          'O EcoMapBrasil **não recebe denúncias**. A seção [Como denunciar](/#denuncie) leva aos canais oficiais (Fala.BR, Central de Atendimento do Ibama e 190), que são do governo e têm as próprias regras.',
        ),
      ],
    ),
    SecaoLegal(
      id: 'creditos',
      titulo: 'Dados, fotos e créditos',
      blocos: [
        ParagrafoLegal(
          'O código do [site](https://github.com/ecomap-devs/semestre-4-nextjs/blob/main/LICENSE) e do [app](https://github.com/ecomap-devs/semestre-4-flutter/blob/main/LICENSE) é aberto, sob a licença MIT. Os dados e as imagens são de terceiros e seguem as licenças deles:',
        ),
        TabelaLegal(
          colunas: ['Conteúdo', 'De quem', 'Licença'],
          linhas: [
            [
              'Desmatamento (PRODES) e alertas (DETER)',
              '[INPE, pelo TerraBrasilis](https://terrabrasilis.dpi.inpe.br)',
              '[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.pt-br)',
            ],
            [
              'Limites dos biomas',
              '[IBGE](https://geoftp.ibge.gov.br/informacoes_ambientais/estudos_ambientais/biomas/vetores/)',
              'Dado público, usado com a fonte',
            ],
            [
              'Lista nacional de fauna ameaçada',
              '[Ministério do Meio Ambiente](https://dados.mma.gov.br/dataset/especies-ameacadas)',
              '[CC BY](https://opendefinition.org/licenses/cc-by/)',
            ],
            [
              'Categoria global das espécies',
              'IUCN (2026), The IUCN Red List of Threatened Species, versão 2026-1, [pelo GBIF](https://www.gbif.org/dataset/19491596-35ae-4a91-9a98-85cf505f1bd3)',
              '[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.pt-br)',
            ],
            [
              'Fotos das espécies com crédito na ficha',
              'Autores do [Wikimedia Commons](https://commons.wikimedia.org)',
              'A de cada foto, indicada na ficha',
            ],
            [
              'Foto da seção final da página inicial',
              '[Bruno Kelly/Amazônia Real, pelo Wikimedia Commons](https://commons.wikimedia.org/wiki/File:SOBREVVO_EM_RONDONIA_DIA_07-08-2020_%28FOTO_BRUNO_KELLY%29_%2835%29_%2850224380121%29.jpg)',
              '[CC BY 2.0](https://creativecommons.org/licenses/by/2.0/deed.pt-br)',
            ],
            [
              'Fundos do mapa',
              '[Esri](https://www.esri.com) e parceiros',
              '[Termos da Esri](https://www.esri.com/en-us/legal/terms/full-master-agreement)',
            ],
            [
              'Estimativas de população',
              'A fonte de cada uma, citada na ficha da espécie',
              'Citadas, não reproduzidas',
            ],
          ],
        ),
        ParagrafoLegal(
          'As fotos das espécies sem crédito na ficha vieram das versões dos semestres anteriores, e a origem de cada uma está sendo revista. Se alguma for sua e você quiser crédito ou remoção, [abra uma issue](https://github.com/ecomap-devs/semestre-4-nextjs/issues/new?template=pedido-de-dados.md).',
        ),
      ],
    ),
    SecaoLegal(
      id: 'disponibilidade',
      titulo: 'Disponibilidade e responsabilidade',
      blocos: [
        ListaLegal([
          'O EcoMapBrasil é oferecido como está, de graça, sem garantia de que vai estar sempre no ar ou sem erro. Ele roda nos planos gratuitos dos serviços que usa, e algum recurso pode parar por um tempo.',
          'O projeto pode mudar ou ser encerrado, como qualquer projeto acadêmico.',
          'Os links para outros sites (fontes, canais de denúncia, fotos) levam a serviços que não controlamos.',
          'Nada aqui tira direitos que a lei brasileira garante a você.',
        ]),
      ],
    ),
    SecaoLegal(
      id: 'mudancas',
      titulo: 'Mudanças, contato e lei',
      blocos: [
        ParagrafoLegal(
          'Quando estes termos mudarem, a data no alto muda junto, e o histórico fica [no GitHub](https://github.com/ecomap-devs/semestre-4-nextjs/commits/main/src/dados/legal.ts). Dúvidas: [abra uma issue](https://github.com/ecomap-devs/semestre-4-nextjs/issues/new).',
        ),
        ParagrafoLegal(
          'Estes termos seguem a lei brasileira, em especial o Marco Civil da Internet (Lei 12.965/2014) e a LGPD (Lei 13.709/2018).',
        ),
      ],
    ),
  ],
);
