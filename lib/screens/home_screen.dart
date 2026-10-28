import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/home_data.dart';
import '../data/linha_do_tempo.dart';
import '../models/animal.dart';
import '../services/reviews_service.dart';
import '../theme/app_theme.dart';
import '../widgets/abertura.dart';
import '../widgets/animacao_na_tela.dart';
import '../widgets/charts/barras_chart.dart';
import '../widgets/charts/mapa_biomas.dart';
import '../widgets/imagem_com_reserva.dart';
import '../widgets/reviews_section.dart';
import '../widgets/rolagem_suave.dart';

/// Home — a mesma pagina inicial do site (semestre-4-nextjs).
///
/// Ritmo da pagina: foto em tela cheia, faixa escura com os numeros, mapa no
/// papel, foto com uma frase, especies, dados, solucoes no escuro, avaliacoes
/// e a chamada final sobre foto. Alternar claro e escuro e o que da impacto
/// sem enfeite.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.usuario,
    required this.aoPedirLogin,
    required this.aoAbrirMapa,
    required this.aoAbrirAnimais,
    required this.aoAbrirFotos,
    this.avaliacoes,
  });

  final User? usuario;
  final VoidCallback aoPedirLogin;
  final VoidCallback aoAbrirMapa;
  final VoidCallback aoAbrirAnimais;
  final VoidCallback aoAbrirFotos;

  /// Serviço das avaliações; os testes passam um falso, sem Firestore.
  final ReviewsService? avaliacoes;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Largura maxima do conteudo, como o `maxWidth: 1120` do site.
const _larguraMaxima = 1120.0;

class _HomeScreenState extends State<HomeScreen> {
  final _secaoMapa = GlobalKey();
  final _secaoAnimais = GlobalKey();
  final _secaoDados = GlobalKey();
  final _secaoSolucoes = GlobalKey();

  void _irPara(GlobalKey secao) {
    final contexto = secao.currentContext;
    if (contexto == null) return;
    Scrollable.ensureVisible(
      contexto,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mico = slides.firstWhere((s) => s.rotulo == 'Mico-leão-dourado');
    final lobo = slides.firstWhere((s) => s.rotulo == 'Lobo-guará');

    return RolagemSuave(
      builder: (context, controlador) => Stack(
        children: [
          SingleChildScrollView(
            controller: controlador,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Abertura(
                  aoAbrirMapa: widget.aoAbrirMapa,
                  aoVerEspecies: () => _irPara(_secaoAnimais),
                ),
                const _Numeros(),
                _SecaoMapa(key: _secaoMapa, aoAbrirMapa: widget.aoAbrirMapa),
                _FaixaDeFoto(
                  foto: mico.url,
                  alinhamento: const Alignment(0, -.4),
                  child: const _FraseDoMico(),
                ),
                _Especies(
                  key: _secaoAnimais,
                  aoAbrirAnimais: widget.aoAbrirAnimais,
                  aoAbrirFotos: widget.aoAbrirFotos,
                ),
                _Dados(key: _secaoDados),
                _Solucoes(key: _secaoSolucoes),
                RevelarAoRolar(
                  child: ReviewsSection(
                    usuario: widget.usuario,
                    aoPedirLogin: widget.aoPedirLogin,
                    service: widget.avaliacoes,
                  ),
                ),
                _FaixaDeFoto(foto: lobo.url, child: const _Chamada()),
                _Rodape(
                  links: [
                    ('Mapa', () => _irPara(_secaoMapa)),
                    ('Espécies ameaçadas', () => _irPara(_secaoAnimais)),
                    ('Dados', () => _irPara(_secaoDados)),
                    ('Como ajudar', () => _irPara(_secaoSolucoes)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: _VoltarAoTopo(controlador: controlador),
          ),
        ],
      ),
    );
  }
}

/// Faixa de largura total com o conteudo centralizado e o respiro do site
/// (120 px no computador, 64 no celular).
class _Secao extends StatelessWidget {
  const _Secao({required this.child, this.cor});

  final Widget child;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.ehMobile(context);
    return ColoredBox(
      color: cor ?? AppCores.papel,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 20 : 24,
          vertical: mobile ? 64 : 112,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _larguraMaxima),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Titulo de secao grande, em serifa, e o paragrafo de abertura.
class _TituloSecao extends StatelessWidget {
  const _TituloSecao({
    required this.titulo,
    this.intro,
    this.escuro = false,
    this.espacoDepois = 56,
  });

  final String titulo;
  final String? intro;
  final bool escuro;
  final double espacoDepois;

  @override
  Widget build(BuildContext context) {
    final tamanho = Breakpoints.ehMobile(context) ? 36.0 : 52.0;
    return RevelarAoRolar(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              titulo,
              style: estiloTitulo(
                tamanho,
                cor: escuro ? AppCores.branco : AppCores.tinta,
                altura: 1.05,
              ),
            ),
          ),
          if (intro != null) ...[
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Text(
                intro!,
                style: TextStyle(
                  fontSize: 19,
                  height: 1.5,
                  color: escuro ? AppCores.claroSuave : AppCores.tinta2,
                ),
              ),
            ),
          ],
          SizedBox(height: espacoDepois),
        ],
      ),
    );
  }
}

/// Grade simples: [colunas] por linha, sem altura fixa (cada linha cresce
/// com o conteudo, ao contrario do `GridView`).
class _Grade extends StatelessWidget {
  const _Grade({
    required this.colunas,
    required this.children,
    this.espacoH = 32,
    this.espacoV = 48,
  });

  final int colunas;
  final List<Widget> children;
  final double espacoH;
  final double espacoV;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i += colunas) ...[
        if (i > 0) SizedBox(height: espacoV),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = i; j < i + colunas; j++) ...[
              if (j > i) SizedBox(width: espacoH),
              Expanded(
                child: j < children.length
                    ? children[j]
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ],
    ],
  );
}

class _Numeros extends StatelessWidget {
  const _Numeros();

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.ehMobile(context);
    return _Secao(
      cor: AppCores.mataNoite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TituloSecao(
            titulo: 'O tamanho do problema, em quatro números',
            escuro: true,
            espacoDepois: 56,
          ),
          _Grade(
            colunas: mobile ? 1 : 2,
            espacoH: 72,
            espacoV: mobile ? 44 : 64,
            children: [
              for (final (i, n) in numeros.indexed)
                RevelarAoRolar(
                  atraso: Duration(milliseconds: i * 120),
                  child: Container(
                    padding: const EdgeInsets.only(top: 20),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppCores.sol, width: 2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Contador(
                            valor: n.valor,
                            estilo: estiloTitulo(
                              mobile ? 60 : 88,
                              cor: AppCores.branco,
                              peso: FontWeight.w400,
                              altura: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          n.rotulo,
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.4,
                            color: AppCores.claroSuave,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecaoMapa extends StatelessWidget {
  const _SecaoMapa({super.key, required this.aoAbrirMapa});

  final VoidCallback aoAbrirMapa;

  @override
  Widget build(BuildContext context) {
    final texto = RevelarAoRolar(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TituloSecao(
            titulo: 'Seis biomas, seis histórias de perda',
            intro:
                'O mapa interativo junta os alertas de desmatamento do '
                'DETER-B ao limite oficial de cada bioma, do IBGE.',
            espacoDepois: 16,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: const Text(
              'Escolha um bioma na lista para ir até ele e ver quanto já foi '
              'desmatado.',
              style: TextStyle(
                fontSize: 19,
                height: 1.5,
                color: AppCores.tinta2,
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: aoAbrirMapa,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text('Abrir o mapa interativo')),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );

    return _Secao(
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth < 860
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  texto,
                  const SizedBox(height: 40),
                  const Center(child: MapaBiomas()),
                ],
              )
            : Row(
                children: [
                  Expanded(flex: 10, child: texto),
                  const SizedBox(width: 72),
                  const Expanded(flex: 11, child: Center(child: MapaBiomas())),
                ],
              ),
      ),
    );
  }
}

/// Faixa de foto de ponta a ponta com uma frase so.
class _FaixaDeFoto extends StatelessWidget {
  const _FaixaDeFoto({
    required this.foto,
    required this.child,
    this.alinhamento = Alignment.center,
  });

  final String foto;
  final Alignment alinhamento;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.ehMobile(context);
    final altura = (MediaQuery.sizeOf(context).height * .85).clamp(
      460.0,
      760.0,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: altura),
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: ImagemComReserva(
                url: foto,
                alinhamento: alinhamento,
                escura: true,
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0, .5, 1],
                  colors: [
                    Color(0xE6101812),
                    Color(0x66101812),
                    Color(0x26101812),
                  ],
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: altura),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: mobile ? 20 : 24,
                  vertical: mobile ? 64 : 96,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _larguraMaxima),
                    child: SizedBox(
                      width: double.infinity,
                      child: RevelarAoRolar(child: child),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FraseDoMico extends StatelessWidget {
  const _FraseDoMico();

  @override
  Widget build(BuildContext context) {
    final tamanho = Breakpoints.ehMobile(context) ? 36.0 : 64.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Text.rich(
            const TextSpan(
              children: [
                TextSpan(text: 'Restam cerca de '),
                TextSpan(
                  text: '4.800',
                  style: TextStyle(color: AppCores.sol),
                ),
                TextSpan(text: ' micos-leões-dourados na natureza.'),
              ],
            ),
            style: estiloTitulo(
              tamanho,
              cor: AppCores.branco,
              peso: FontWeight.w400,
              altura: 1.05,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Mico-leão-dourado, Mata Atlântica · censo de 2023 da Associação '
          'Mico-Leão-Dourado',
          style: TextStyle(fontSize: 18, color: AppCores.claroSuave),
        ),
      ],
    );
  }
}

class _Especies extends StatelessWidget {
  const _Especies({
    super.key,
    required this.aoAbrirAnimais,
    required this.aoAbrirFotos,
  });

  final VoidCallback aoAbrirAnimais;
  final VoidCallback aoAbrirFotos;

  @override
  Widget build(BuildContext context) => _Secao(
    cor: AppCores.papel2,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TituloSecao(
          titulo: 'Espécies ameaçadas',
          intro:
              'Seis espécies da lista nacional de fauna ameaçada e o que está '
              'acontecendo com cada uma.',
        ),
        LayoutBuilder(
          builder: (context, c) {
            final colunas = (c.maxWidth / 300).floor().clamp(1, 3);
            return _Grade(
              colunas: colunas,
              espacoV: 56,
              children: [
                for (final (i, a) in animaisDestaque.indexed)
                  RevelarAoRolar(
                    atraso: Duration(milliseconds: (i % colunas) * 120),
                    child: _CartaoDestaque(animal: a),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 56),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: aoAbrirAnimais,
              child: const Text('Ver todas as espécies'),
            ),
            OutlinedButton.icon(
              onPressed: aoAbrirFotos,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Identificar um animal por foto'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CartaoDestaque extends StatelessWidget {
  const _CartaoDestaque({required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(raioPadrao),
        child: AspectRatio(
          // Foto inteira, no mesmo 4:3 do catalogo. Ate 28/10/2026 era
          // recortada em 4:5 e trazia por cima uma "queda da populacao" sem
          // fonte.
          aspectRatio: 4 / 3,
          child: ColoredBox(
            color: AppCores.linha,
            child: ImagemComReserva(url: animal.imagem, ajuste: BoxFit.contain),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Text(
        animal.status,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: animal.corStatus,
        ),
      ),
      const SizedBox(height: 4),
      Text(animal.nome, style: estiloTitulo(26)),
      const SizedBox(height: 8),
      Text(
        animal.descricao,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: AppCores.tinta2,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '${animal.bioma} · no mundo (IUCN): ${animal.iucnOuNaoAvaliada}',
        style: const TextStyle(fontSize: 14, color: AppCores.tinta3),
      ),
    ],
  );
}

class _Dados extends StatelessWidget {
  const _Dados({super.key});

  static TextStyle get _subtitulo => estiloTitulo(24);

  @override
  Widget build(BuildContext context) {
    final graficos = RevelarAoRolar(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Área desmatada por bioma', style: _subtitulo),
          const SizedBox(height: 24),
          const BarrasChart(),
          const SizedBox(height: 42),
          Text('Desmatado no último ano medido', style: _subtitulo),
          const SizedBox(height: 6),
          Text(
            'De ${ultimoPeriodo.rotulo}',
            style: const TextStyle(fontSize: 15, color: AppCores.tinta3),
          ),
          const SizedBox(height: 20),
          const _UltimoPeriodo(),
        ],
      ),
    );
    final tempo = RevelarAoRolar(
      atraso: const Duration(milliseconds: 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Linha do tempo', style: _subtitulo),
          const SizedBox(height: 24),
          const _LinhaDoTempo(),
        ],
      ),
    );

    return _Secao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TituloSecao(
            titulo: 'Como o desmatamento avançou',
            intro:
                'Área já desmatada em cada bioma e os anos que marcaram essa '
                'história.',
          ),
          LayoutBuilder(
            builder: (context, c) => c.maxWidth < 860
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [graficos, const SizedBox(height: 48), tempo],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: graficos),
                      const SizedBox(width: 72),
                      Expanded(flex: 5, child: tempo),
                    ],
                  ),
          ),
          const SizedBox(height: 40),
          Text(
            'Desmatamento: PRODES/INPE, pelo TerraBrasilis, atualizado em '
            '$dadosAtualizadosEm. Área dos biomas: IBGE (2019). Na linha do '
            'tempo, as taxas são as oficiais da Amazônia Legal.',
            style: const TextStyle(fontSize: 14, color: AppCores.tinta3),
          ),
        ],
      ),
    );
  }
}

/// O desmatamento de cada bioma no periodo mais recente do PRODES — o
/// `UltimoPeriodo` do site.
class _UltimoPeriodo extends StatelessWidget {
  const _UltimoPeriodo();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => _Grade(
      colunas: (c.maxWidth / 160).floor().clamp(1, 3),
      espacoV: 16,
      children: [
        for (final b in ultimoPeriodo.biomas)
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppCores.linha)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${formatarMilhar(b.km2)} '),
                      TextSpan(
                        text: 'km²',
                        style: estiloTitulo(18, cor: AppCores.tinta2),
                      ),
                    ],
                  ),
                  style: estiloTitulo(32).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  b.nome,
                  style: const TextStyle(fontSize: 14, color: AppCores.tinta3),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _LinhaDoTempo extends StatelessWidget {
  const _LinhaDoTempo();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 6),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: AppCores.linha)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in linhaDoTempo)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -5.5,
                top: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppCores.papel,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppCores.mata, width: 2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 0, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.ano}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppCores.tinta3,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      item.titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppCores.tinta,
                      ),
                    ),
                    Text(
                      item.texto,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: AppCores.tinta2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

class _Solucoes extends StatelessWidget {
  const _Solucoes({super.key});

  @override
  Widget build(BuildContext context) => _Secao(
    cor: AppCores.mataEscura,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TituloSecao(
          titulo: 'O que dá para fazer',
          intro:
              'Ninguém resolve isso sozinho, mas cada uma destas atitudes '
              'conta.',
          escuro: true,
          espacoDepois: 64,
        ),
        LayoutBuilder(
          builder: (context, c) {
            final colunas = (c.maxWidth / 300).floor().clamp(1, 3);
            return _Grade(
              colunas: colunas,
              espacoH: 48,
              espacoV: 56,
              children: [
                for (final (i, s) in solucoes.indexed)
                  RevelarAoRolar(
                    atraso: Duration(milliseconds: (i % colunas) * 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (i + 1).toString().padLeft(2, '0'),
                          style: estiloTitulo(
                            56,
                            cor: AppCores.sol,
                            peso: FontWeight.w400,
                            altura: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s.titulo,
                          style: estiloTitulo(24, cor: AppCores.branco),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.texto,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppCores.claroSuave,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _Chamada extends StatelessWidget {
  const _Chamada();

  @override
  Widget build(BuildContext context) {
    final tamanho = Breakpoints.ehMobile(context) ? 48.0 : 80.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Passe adiante.',
            style: estiloTitulo(tamanho, cor: AppCores.branco, altura: 1.05),
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: const Text(
            'Quanto mais gente souber o tamanho do problema, mais difícil '
            'fica ignorá-lo.',
            style: TextStyle(
              fontSize: 20,
              height: 1.45,
              color: Color(0xD9FFFDF8),
            ),
          ),
        ),
        const SizedBox(height: 36),
        const _BotaoCompartilhar(),
      ],
    );
  }
}

/// Copia o endereco do site. O app nao tem o pacote de compartilhamento do
/// sistema; copiar o link funciona em qualquer aparelho sem dependencia nova.
class _BotaoCompartilhar extends StatefulWidget {
  const _BotaoCompartilhar();

  @override
  State<_BotaoCompartilhar> createState() => _BotaoCompartilharState();
}

class _BotaoCompartilharState extends State<_BotaoCompartilhar> {
  bool _copiado = false;
  Timer? _desfazer;

  @override
  void dispose() {
    _desfazer?.cancel();
    super.dispose();
  }

  Future<void> _copiar() async {
    await Clipboard.setData(const ClipboardData(text: enderecoDoSite));
    if (!mounted) return;
    setState(() => _copiado = true);
    _desfazer?.cancel();
    _desfazer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _copiado = false);
    });
  }

  @override
  Widget build(BuildContext context) => BotaoClaro(
    rotulo: _copiado ? 'Link copiado' : 'Copiar o link do site',
    icone: _copiado ? Icons.check : Icons.share_outlined,
    iconeAntes: true,
    aoTocar: _copiar,
  );
}

class _Rodape extends StatelessWidget {
  const _Rodape({required this.links});

  final List<(String, VoidCallback)> links;

  static const _tituloColuna = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppCores.branco,
  );
  static const _texto = TextStyle(
    fontSize: 15,
    height: 1.6,
    color: Color(0xB3FFFDF8),
  );

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.ehMobile(context);
    final nomes = equipe.sublist(0, equipe.length - 1).join(', ');

    final marca = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset('assets/img/logo.png', height: 28),
            const SizedBox(width: 8),
            Text('EcoMapBrasil', style: estiloTitulo(19, cor: AppCores.branco)),
          ],
        ),
        const SizedBox(height: 12),
        // A equipe era uma lista solta no rodape; o nome de cada um basta.
        Text(
          'Feito por $nomes e ${equipe.last}, no Projeto Interdisciplinar da '
          'FATEC.',
          style: _texto,
        ),
      ],
    );
    final noApp = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('No app', style: _tituloColuna),
        const SizedBox(height: 8),
        for (final (rotulo, aoTocar) in links)
          InkWell(
            onTap: aoTocar,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(rotulo, style: _texto),
            ),
          ),
      ],
    );
    const contato = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contato', style: _tituloColuna),
        SizedBox(height: 8),
        Text('Matão, São Paulo', style: _texto),
        SelectableText('github.com/ecomap-devs', style: _texto),
      ],
    );

    return ColoredBox(
      color: AppCores.mataNoite,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          mobile ? 20 : 24,
          64,
          mobile ? 20 : 24,
          mobile ? 88 : 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _larguraMaxima),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (mobile) ...[
                  marca,
                  const SizedBox(height: 32),
                  noApp,
                  const SizedBox(height: 24),
                  contato,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: marca),
                      const SizedBox(width: 40),
                      Expanded(child: noApp),
                      const SizedBox(width: 40),
                      const Expanded(child: contato),
                    ],
                  ),
                const SizedBox(height: 40),
                const Divider(color: Color(0x1FFFFDF8), height: 1),
                const SizedBox(height: 24),
                const Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    Text(
                      '© 2025 EcoMapBrasil',
                      style: TextStyle(fontSize: 13, color: Color(0xB3FFFDF8)),
                    ),
                    Text(
                      'Dados de fontes públicas: INPE, IBGE e MapBiomas '
                      'Alerta.',
                      style: TextStyle(fontSize: 13, color: Color(0xB3FFFDF8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botao redondo que aparece depois de rolar um pouco e volta ao topo.
class _VoltarAoTopo extends StatefulWidget {
  const _VoltarAoTopo({required this.controlador});

  final ScrollController controlador;

  @override
  State<_VoltarAoTopo> createState() => _VoltarAoTopoState();
}

class _VoltarAoTopoState extends State<_VoltarAoTopo> {
  bool _visivel = false;

  @override
  void initState() {
    super.initState();
    widget.controlador.addListener(_aoRolar);
  }

  @override
  void dispose() {
    widget.controlador.removeListener(_aoRolar);
    super.dispose();
  }

  void _aoRolar() {
    final visivel =
        widget.controlador.hasClients && widget.controlador.offset > 600;
    if (visivel != _visivel) setState(() => _visivel = visivel);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visivel) return const SizedBox.shrink();
    return Material(
      color: AppCores.branco,
      shape: const CircleBorder(side: BorderSide(color: AppCores.linha)),
      elevation: 2,
      shadowColor: const Color(0x331D2620),
      child: IconButton(
        tooltip: 'Voltar ao topo',
        icon: const Icon(Icons.arrow_upward, size: 20, color: AppCores.tinta),
        onPressed: () => widget.controlador.animateTo(
          0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? const Duration(milliseconds: 1)
              : const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        ),
      ),
    );
  }
}
