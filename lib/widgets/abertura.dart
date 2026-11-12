import 'package:flutter/material.dart';

import '../data/home_data.dart';
import '../theme/app_theme.dart';
import 'credito_da_foto.dart';
import 'imagem_com_reserva.dart';

/// Abertura da Home: fotos das especies ocupando a tela, trocando sozinhas,
/// com o titulo por cima — o `Slideshow` do site.
///
/// Zoom lento na foto da vez e indicadores que se enchem ate a proxima. Com
/// "remover animacoes" ligado no sistema as fotos nao trocam sozinhas: troca
/// so quem tocar nos indicadores ou deslizar a foto para o lado.
class Abertura extends StatefulWidget {
  const Abertura({
    super.key,
    required this.aoAbrirMapa,
    required this.aoVerEspecies,
    this.altura,
  });

  final VoidCallback aoAbrirMapa;
  final VoidCallback aoVerEspecies;

  /// Altura da abertura; sem ela, ocupa quase a tela toda.
  final double? altura;

  @override
  State<Abertura> createState() => _AberturaState();
}

const _duracaoSlide = Duration(milliseconds: 6000);
const _duracaoFade = Duration(milliseconds: 1200);

class _AberturaState extends State<Abertura>
    with SingleTickerProviderStateMixin {
  late final _relogio =
      AnimationController(vsync: this, duration: _duracaoSlide)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _irPara(_atual + 1);
        });

  int _atual = 0;
  int? _anterior;
  bool _semMovimento = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _semMovimento = MediaQuery.disableAnimationsOf(context);
    if (_semMovimento) {
      _relogio.stop();
    } else if (!_relogio.isAnimating) {
      _relogio.forward();
    }
  }

  @override
  void dispose() {
    _relogio.dispose();
    super.dispose();
  }

  void _irPara(int indice) {
    setState(() {
      _anterior = _atual;
      _atual = indice % slides.length;
    });
    if (!_semMovimento) _relogio.forward(from: 0);
  }

  void _pausar(bool pausado) {
    if (_semMovimento) return;
    pausado ? _relogio.stop() : _relogio.forward();
  }

  /// Deslizar para o lado troca a foto (11/11/2026); antes so as setas (no
  /// computador), os indicadores e o relogio trocavam. Para a esquerda vem a
  /// proxima, como num album. O relogio pausa enquanto o dedo esta na tela.
  double _arrastoX = 0;

  /// Distancia ou velocidade minimas para contar como deslizar, e nao toque.
  static const _distanciaMinima = 48.0;
  static const _velocidadeMinima = 300.0;

  void _soltarArrasto(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dx;
    final rapido = v.abs() > _velocidadeMinima;
    final sentido = rapido ? v : _arrastoX;
    final valeu = rapido || _arrastoX.abs() > _distanciaMinima;
    _arrastoX = 0;
    if (!valeu) {
      _pausar(false);
      return;
    }
    _irPara(sentido < 0 ? _atual + 1 : _atual - 1 + slides.length);
  }

  @override
  Widget build(BuildContext context) {
    final tela = MediaQuery.sizeOf(context);
    final mobile = Breakpoints.ehMobile(context);
    // Com o celular deitado nao cabem 520 dp: a abertura fica na altura da
    // tela e cresce so o que o texto pedir.
    final altura =
        widget.altura ??
        (Breakpoints.ehCelularDeitado(context)
            ? tela.height * .7
            : (tela.height * .82).clamp(520.0, 900.0));
    final margem = mobile ? 20.0 : 24.0;
    // O titulo acompanha a largura e a altura da tela, como o
    // clamp(36px, min(8vw, 12.5vh), 108px) do site.
    final tamanhoTitulo = [
      tela.width * .1,
      tela.height * .075,
      96.0,
    ].reduce((a, b) => a < b ? a : b).clamp(38.0, 96.0);

    return MouseRegion(
      onEnter: (_) => _pausar(true),
      onExit: (_) => _pausar(false),
      child: GestureDetector(
        onHorizontalDragStart: (_) => _pausar(true),
        onHorizontalDragUpdate: (d) => _arrastoX += d.delta.dx,
        onHorizontalDragEnd: _soltarArrasto,
        onHorizontalDragCancel: () {
          _arrastoX = 0;
          _pausar(false);
        },
        child: ColoredBox(
          // Fundo escuro por baixo das fotos: se o Supabase nao responder, o
          // texto claro continua legivel.
          color: AppCores.mataNoite,
          child: ClipRect(
            child: Stack(
              children: [
                for (final (i, s) in slides.indexed)
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: AnimatedOpacity(
                        opacity: i == _atual ? 1 : 0,
                        duration: _semMovimento ? Duration.zero : _duracaoFade,
                        curve: Curves.easeInOut,
                        child: AnimatedScale(
                          // Zoom lento na foto da vez; a que sai so volta ao
                          // tamanho quando outra entrar no lugar dela.
                          scale:
                              !_semMovimento && (i == _atual || i == _anterior)
                              ? 1.08
                              : 1,
                          duration: i == _atual
                              ? _duracaoSlide +
                                    const Duration(milliseconds: 1500)
                              : Duration.zero,
                          curve: Curves.easeOut,
                          child: ImagemComReserva(url: s.url, escura: true),
                        ),
                      ),
                    ),
                  ),
                // Escurece o topo e a base (para o texto); o meio aparece.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, .22, .4, 1],
                        colors: [
                          Color(0x8C101812),
                          Color(0x00101812),
                          Color(0x00101812),
                          Color(0xE0101812),
                        ],
                      ),
                    ),
                  ),
                ),
                // Altura minima, nao fixa: com fonte grande num celular pequeno
                // o texto nao cabe, e a abertura cresce em vez de estourar.
                //
                // Os indicadores e o credito vem no mesmo fluxo do texto, logo
                // abaixo dos botoes. Ate 11/11/2026 ficavam presos a 28 dp da
                // base, por cima, e com fonte grande o credito cobria o botao
                // "Especies ameacadas".
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: altura,
                    minWidth: double.infinity,
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(margem, 24, margem, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Texto(
                              tamanhoTitulo: tamanhoTitulo,
                              compacto: Breakpoints.ehCelularDeitado(context),
                              aoAbrirMapa: widget.aoAbrirMapa,
                              aoVerEspecies: widget.aoVerEspecies,
                            ),
                            const SizedBox(height: 24),
                            _Indicadores(
                              atual: _atual,
                              relogio: _relogio,
                              semMovimento: _semMovimento,
                              creditoAbaixo: mobile,
                              aoEscolher: _irPara,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!mobile) ...[
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _Seta(
                        icone: Icons.chevron_left,
                        rotulo: 'Foto anterior',
                        aoTocar: () => _irPara(_atual - 1 + slides.length),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _Seta(
                        icone: Icons.chevron_right,
                        rotulo: 'Próxima foto',
                        aoTocar: () => _irPara(_atual + 1),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Texto extends StatelessWidget {
  const _Texto({
    required this.tamanhoTitulo,
    required this.compacto,
    required this.aoAbrirMapa,
    required this.aoVerEspecies,
  });

  final double tamanhoTitulo;

  /// Celular deitado: espacos e subtitulo menores, para os botoes caberem na
  /// altura da tela.
  final bool compacto;
  final VoidCallback aoAbrirMapa;
  final VoidCallback aoVerEspecies;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'O desmatamento no Brasil é '),
              TextSpan(
                text: 'maior',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.underline,
                  decorationColor: AppCores.sol,
                  decorationThickness: 2.5,
                ),
              ),
              TextSpan(text: ' do que você imagina'),
            ],
          ),
          style:
              // O tamanho acompanha a largura e a altura da tela, como o
              // clamp() do site: e o unico texto fora dos degraus da Escala.
              estiloTitulo(
                Escala.destaque.copyWith(fontSize: tamanhoTitulo),
                cor: AppCores.branco,
                peso: FontWeight.w400,
                altura: 1.0,
              ).copyWith(
                letterSpacing: -tamanhoTitulo * .03,
                shadows: const [
                  Shadow(color: Color(0x59101812), blurRadius: 30),
                ],
              ),
        ),
      ),
      SizedBox(height: compacto ? 12 : 20),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Text(
          'Veja onde a floresta está sendo perdida e quais espécies estão '
          'ficando sem lugar para viver.',
          style: (compacto ? Escala.bodyLarge : Escala.titleMedium).copyWith(
          style: TextStyle(
            fontSize: compacto ? 16 : 19,
            height: 1.45,
            color: const Color(0xE0FFFDF8),
          ),
        ),
      ),
      SizedBox(height: compacto ? 16 : 28),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          BotaoClaro(
            rotulo: 'Abrir o mapa',
            icone: Icons.arrow_forward,
            aoTocar: aoAbrirMapa,
          ),
          BotaoVazado(rotulo: 'Espécies ameaçadas', aoTocar: aoVerEspecies),
        ],
      ),
    ],
  );
}

class _Indicadores extends StatelessWidget {
  const _Indicadores({
    required this.atual,
    required this.relogio,
    required this.semMovimento,
    required this.creditoAbaixo,
    required this.aoEscolher,
  });

  final int atual;
  final Animation<double> relogio;
  final bool semMovimento;

  /// No celular o nome do animal e o credito vao numa linha propria, abaixo
  /// das barras: ao lado delas sobravam poucos dp, e com fonte grande o
  /// credito quebrava em varias linhas por cima dos botoes.
  final bool creditoAbaixo;
  final ValueChanged<int> aoEscolher;

  @override
  Widget build(BuildContext context) {
    final barras = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, s) in slides.indexed)
          Semantics(
            button: true,
            selected: i == atual,
            label: 'Mostrar ${s.rotulo}',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => aoEscolher(i),
              // 48 dp de toque, como pede o Android; a barra continua fina.
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 23,
                ),
                child: SizedBox(
                  width: 40,
                  height: 2,
                  child: ColoredBox(
                    color: const Color(0x4DFFFDF8),
                    // A barra da foto da vez se enche ate a proxima.
                    child: i != atual
                        ? null
                        : AnimatedBuilder(
                            animation: relogio,
                            builder: (_, _) => FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: semMovimento ? 1 : relogio.value,
                              child: const ColoredBox(color: AppCores.branco),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    // O nome do animal da vez e o credito da foto, que a licenca CC pede a
    // vista (desde 10/11/2026 todas sao do Wikimedia Commons).
    final legenda = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            slides[atual].rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Escala.bodyMedium.copyWith(
            style: const TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Color(0xD9FFFDF8),
            ),
          ),
        ),
        CreditoDaFoto(credito: slides[atual].credito),
      ],
    );

    if (creditoAbaixo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [barras, legenda],
      );
    }
    return Row(
      children: [
        barras,
        const SizedBox(width: 16),
        Expanded(child: legenda),
      ],
    );
  }
}

class _Seta extends StatelessWidget {
  const _Seta({
    required this.icone,
    required this.rotulo,
    required this.aoTocar,
  });

  final IconData icone;
  final String rotulo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: aoTocar,
    tooltip: rotulo,
    icon: Icon(icone, color: AppCores.branco),
    style: IconButton.styleFrom(
      backgroundColor: const Color(0x40000000),
      hoverColor: const Color(0x40000000),
      fixedSize: const Size(44, 44),
    ),
  );
}

/// Botao claro sobre foto: fundo de papel, texto em tinta (`.botao-claro`).
class BotaoClaro extends StatelessWidget {
  const BotaoClaro({
    super.key,
    required this.rotulo,
    required this.aoTocar,
    this.icone,
    this.iconeAntes = false,
  });

  final String rotulo;
  final VoidCallback aoTocar;
  final IconData? icone;

  /// O icone vai antes do rotulo ("Compartilhar") ou depois ("Abrir →").
  final bool iconeAntes;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: aoTocar,
    style: FilledButton.styleFrom(
      backgroundColor: AppCores.branco,
      foregroundColor: AppCores.tinta,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      textStyle: Escala.titleMedium.copyWith(fontWeight: FontWeight.w600),
    ),
    child: _RotuloComIcone(rotulo: rotulo, icone: icone, antes: iconeAntes),
  );
}

/// Botao vazado sobre foto: so o contorno claro (`.botao-vazado`).
class BotaoVazado extends StatelessWidget {
  const BotaoVazado({
    super.key,
    required this.rotulo,
    required this.aoTocar,
    this.icone,
  });

  final String rotulo;
  final VoidCallback aoTocar;
  final IconData? icone;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: aoTocar,
    style: OutlinedButton.styleFrom(
      foregroundColor: AppCores.branco,
      side: const BorderSide(color: Color(0x80FFFDF8)),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      textStyle: Escala.titleMedium.copyWith(fontWeight: FontWeight.w600),
    ),
    child: _RotuloComIcone(rotulo: rotulo, icone: icone, antes: true),
  );
}

class _RotuloComIcone extends StatelessWidget {
  const _RotuloComIcone({
    required this.rotulo,
    required this.icone,
    required this.antes,
  });

  final String rotulo;
  final IconData? icone;
  final bool antes;

  @override
  Widget build(BuildContext context) {
    final i = icone;
    if (i == null) return Text(rotulo);
    final simbolo = Icon(i, size: 18);
    final texto = Flexible(child: Text(rotulo));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: antes
          ? [simbolo, const SizedBox(width: 8), texto]
          : [texto, const SizedBox(width: 8), simbolo],
    );
  }
}
