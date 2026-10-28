import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/biomas_data.dart';
import '../data/linha_do_tempo.dart';
import '../models/bioma.dart';
import '../services/geojson_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animacao_na_tela.dart';

/// O fundo do mapa. Comeca no claro: biomas coloridos e alertas vermelhos
/// aparecem muito mais sobre ele do que sobre o satelite escuro.
enum _Fundo { claro, satelite }

/// Abaixo deste zoom o alerta vira ponto; a partir dele, o poligono aparece.
///
/// Com o Brasil inteiro na tela, um alerta de 70 ha tem menos de um pixel: o
/// poligono era desenhado, mas ninguem enxergava. No zoom 7 a maioria ja
/// tem forma visivel.
const _zoomDetalhe = 7.0;

const _centroBrasil = LatLng(-14, -52);

/// Os alertas ja preparados para desenhar, e o resumo para a legenda.
///
/// Montado uma vez quando o GeoJSON termina de carregar: sao 18 mil alertas,
/// e refazer as listas a cada movimento do mapa custaria quadros.
class _DadosMapa {
  _DadosMapa(List<AlertaDesmatamento> alertas)
    : total = alertas.length,
      areaHa = alertas.fold(0, (s, a) => s + a.areaHa),
      // Ano 0 e alerta sem data no arquivo: fica fora do periodo.
      anoMin = alertas
          .map((a) => a.ano)
          .where((a) => a > 0)
          .fold<int?>(null, (m, a) => m == null || a < m ? a : m),
      anoMax = alertas
          .map((a) => a.ano)
          .where((a) => a > 0)
          .fold<int?>(null, (m, a) => m == null || a > m ? a : m),
      poligonos = [
        for (final a in alertas)
          for (final parte in a.partes)
            Polygon(
              points: parte.contorno,
              holePointsList: parte.buracos,
              color: AppCores.alerta.withValues(alpha: 0.45),
              borderColor: AppCores.alerta,
              borderStrokeWidth: 0.5,
            ),
      ],
      pontos = [
        for (final a in alertas)
          CircleMarker(
            point: a.centro,
            radius: 2.2,
            color: AppCores.alerta.withValues(alpha: 0.75),
          ),
      ];

  final int total;
  final double areaHa;
  final int? anoMin;
  final int? anoMax;
  final List<Polygon> poligonos;
  final List<CircleMarker> pontos;
}

/// Mapa interativo dos biomas — porte do Mapa.jsx.
///
/// `flutter_map` e o irmao do Leaflet no Flutter: mesma ideia de camadas
/// sobre tiles, e roda igual na web e no celular. Os dois fundos sao da Esri
/// (o satelite e o mesmo da versao React, o World Imagery).
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _mapa = MapController();
  final _geo = GeoJsonService();

  late final Future<_DadosMapa> _dados;

  Bioma? _selecionado;
  bool _painelAberto = false;
  bool _detalhe = false;
  _Fundo _fundo = _Fundo.claro;

  @override
  void initState() {
    super.initState();
    _dados = _geo.carregar().then(_DadosMapa.new);
  }

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  /// Selecao vinda da lista: enquadra o bioma inteiro.
  ///
  /// Antes era `move(centro, 5)`: zoom fixo cortava a Amazonia e deixava o
  /// Pantanal minusculo. Enquadrar pelos limites serve aos dois.
  void _selecionar(Bioma b) {
    final ehMobile = Breakpoints.ehMobile(context);
    setState(() {
      _selecionado = b;
      // No celular o painel fecha, para o mapa aparecer com o bioma.
      if (ehMobile) _painelAberto = false;
    });
    _mapa.fitCamera(
      CameraFit.bounds(
        bounds: b.limites,
        // A ficha ocupa o pe da tela; o bioma fica acima dela.
        padding: EdgeInsets.fromLTRB(40, 70, 40, ehMobile ? 300 : 240),
      ),
    );
  }

  /// Toque no mapa: seleciona o bioma sob o dedo, ou limpa se caiu fora.
  ///
  /// No React o clique tambem dava `fitBounds`; aqui a camera fica parada,
  /// porque mover o mapa a cada toque atrapalha quem so quer ler a ficha —
  /// quem quer enquadrar o bioma escolhe na lista.
  void _tocarNoMapa(LatLng ponto) {
    final achado = Bioma.maisEspecificoEm(biomas, ponto);
    if (achado != _selecionado) setState(() => _selecionado = achado);
  }

  void _mudouCamera(MapCamera camera, bool _) {
    final detalhe = camera.zoom >= _zoomDetalhe;
    if (detalhe != _detalhe) setState(() => _detalhe = detalhe);
  }

  void _aproximar(double passo) => _mapa.move(
    _mapa.camera.center,
    (_mapa.camera.zoom + passo).clamp(2, 12).toDouble(),
  );

  // Cada fundo tem a sua `key`. Sem ela, trocar o fundo reaproveitava a mesma
  // camada e deixava o `flutter_map` recarregar os tiles no lugar — e no
  // celular (02/10/2026) o botao trocava o estado, mas a imagem nao mudava.
  // Com a key, a camada antiga sai inteira e a nova comeca do zero.
  List<Widget> _camadasDeFundo() => switch (_fundo) {
    _Fundo.claro => [
      TileLayer(
        key: const ValueKey('fundo-claro'),
        urlTemplate:
            'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
        userAgentPackageName: 'br.com.ecomapbrasil',
      ),
    ],
    _Fundo.satelite => [
      TileLayer(
        key: const ValueKey('fundo-satelite'),
        urlTemplate:
            'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'World_Imagery/MapServer/tile/{z}/{y}/{x}',
        userAgentPackageName: 'br.com.ecomapbrasil',
      ),
    ],
  };

  /// Nomes de cidades e fronteiras, por cima dos biomas e dos alertas — senao
  /// o preenchimento colorido apagaria os nomes.
  Widget _camadaDeNomes() => TileLayer(
    key: ValueKey('nomes-${_fundo.name}'),
    urlTemplate: switch (_fundo) {
      _Fundo.claro =>
        'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'Canvas/World_Light_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
      _Fundo.satelite =>
        'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
    },
    userAgentPackageName: 'br.com.ecomapbrasil',
  );

  /// Os seis biomas pelo limite do IBGE.
  ///
  /// Ate 01/10/2026 nao eram desenhados: os contornos eram retangulos
  /// herdados do React, e mostrar aquilo seria apresentar fronteira
  /// inventada. O preenchimento e fraco de proposito — o de 28% que existia
  /// antes abafava justamente o vermelho dos alertas. O selecionado ganha
  /// borda grossa e preenchimento mais forte.
  Widget _camadaDeBiomas() => PolygonLayer(
    polygons: [
      for (final b in biomas)
        for (final contorno in b.poligonos)
          Polygon(
            points: contorno,
            holePointsList: b.buracosDe(contorno),
            color: b.cor.withValues(alpha: b == _selecionado ? 0.30 : 0.12),
            borderColor: b.cor,
            borderStrokeWidth: b == _selecionado ? 3 : 1.2,
          ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final ehMobile = Breakpoints.ehMobile(context);
    final larguraPainel = Breakpoints.ehTablet(context) ? 260.0 : 320.0;

    final mapa = FutureBuilder<_DadosMapa>(
      future: _dados,
      builder: (context, snap) {
        final dados = snap.data;
        final carregando = snap.connectionState == ConnectionState.waiting;
        // A ficha do bioma toma o lugar da legenda, para nao se encavalarem.
        final mostrarLegenda = _selecionado == null;

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapa,
              options: MapOptions(
                initialCenter: _centroBrasil,
                initialZoom: ehMobile ? 3.4 : 4,
                minZoom: 2,
                maxZoom: 12,
                backgroundColor: AppCores.papel2,
                onTap: (_, ponto) => _tocarNoMapa(ponto),
                onPositionChanged: _mudouCamera,
              ),
              children: [
                ..._camadasDeFundo(),
                _camadaDeBiomas(),
                if (dados != null)
                  _detalhe
                      ? PolygonLayer(polygons: dados.poligonos)
                      : CircleLayer(circles: dados.pontos),
                _camadaDeNomes(),
              ],
            ),

            if (carregando || snap.hasError)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: _CartaoFlutuante(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Text(
                      snap.hasError
                          ? 'Não foi possível carregar os alertas'
                          : 'Carregando alertas...',
                      style: TextStyle(
                        fontSize: 14,
                        color: snap.hasError ? AppCores.terra : AppCores.tinta2,
                      ),
                    ),
                  ),
                ),
              ),

            Positioned(
              top: 12,
              right: 16,
              child: _BotaoFundo(
                fundo: _fundo,
                aoTocar: () => setState(
                  () => _fundo = _fundo == _Fundo.claro
                      ? _Fundo.satelite
                      : _Fundo.claro,
                ),
              ),
            ),

            // No celular o zoom e por pinca, e o +/− ficava escondido atras do
            // botao Biomas.
            if (!ehMobile)
              Positioned(
                left: 12,
                top: 12,
                child: _CartaoFlutuante(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Aproximar mapa',
                        onPressed: () => _aproximar(1),
                        icon: const Icon(Icons.add, color: AppCores.tinta),
                      ),
                      const SizedBox(width: 28, child: Divider(height: 1)),
                      IconButton(
                        tooltip: 'Afastar mapa',
                        onPressed: () => _aproximar(-1),
                        icon: const Icon(Icons.remove, color: AppCores.tinta),
                      ),
                    ],
                  ),
                ),
              ),

            if (mostrarLegenda)
              Positioned(
                left: 16,
                right: ehMobile ? 16 : null,
                bottom: ehMobile ? 84 : 32,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: _Legenda(dados: dados, detalhe: _detalhe),
                ),
              ),

            if (_selecionado != null)
              Positioned(
                left: 16,
                right: ehMobile ? 16 : null,
                bottom: ehMobile ? 84 : 32,
                child: EntradaSuave(
                  key: ValueKey(_selecionado!.nome),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 320,
                      maxHeight: MediaQuery.sizeOf(context).height * .4,
                    ),
                    child: SingleChildScrollView(
                      child: _FichaBioma(
                        bioma: _selecionado!,
                        aoFechar: () => setState(() => _selecionado = null),
                      ),
                    ),
                  ),
                ),
              ),

            if (ehMobile && !_painelAberto)
              Positioned(
                right: 16,
                bottom: 20,
                child: FilledButton.icon(
                  onPressed: () => setState(() => _painelAberto = true),
                  icon: const Icon(Icons.layers_outlined, size: 18),
                  label: const Text(
                    'Biomas',
                    semanticsLabel: 'Ver biomas e linha do tempo',
                  ),
                  style: FilledButton.styleFrom(
                    elevation: 3,
                    shadowColor: const Color(0x401D2620),
                  ),
                ),
              ),

            if (ehMobile)
              _PainelCelular(
                aberto: _painelAberto,
                selecionado: _selecionado,
                aoSelecionar: _selecionar,
                aoFechar: () => setState(() => _painelAberto = false),
              ),

            // A Esri pede o credito visivel sobre o mapa; IBGE e INPE sao as
            // fontes dos dados desenhados.
            if (!ehMobile || !_painelAberto)
              const Positioned(right: 6, bottom: 4, child: _Creditos()),
          ],
        );
      },
    );

    if (ehMobile) return mapa;

    return Row(
      children: [
        Expanded(child: mapa),
        const VerticalDivider(width: 1),
        SizedBox(
          width: larguraPainel,
          child: ColoredBox(
            color: AppCores.papel,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Biomas', style: estiloTitulo(18)),
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Escolha um para centralizar o mapa nele.',
                    style: TextStyle(fontSize: 14, color: AppCores.tinta3),
                  ),
                ),
                const SizedBox(height: 10),
                for (final b in biomas)
                  _ItemBioma(
                    bioma: b,
                    ativo: b == _selecionado,
                    compacto: larguraPainel < 300,
                    aoEscolher: () => _selecionar(b),
                  ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Linha do tempo', style: estiloTitulo(18)),
                ),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: _LinhaDoTempo(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "18262" vira "18.262": separador de milhar brasileiro.
String _milhar(num n) => n.round().toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+$)'),
  (m) => '${m[1]}.',
);

String _hectares(double ha) => ha >= 1000000
    ? '${(ha / 1000000).toStringAsFixed(1).replaceAll('.', ',')} mi ha'
    : '${_milhar(ha)} ha';

/// Cartao branco que flutua sobre o mapa: legenda, botoes, avisos.
class _CartaoFlutuante extends StatelessWidget {
  const _CartaoFlutuante({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppCores.branco,
      border: Border.all(color: AppCores.linha),
      borderRadius: BorderRadius.circular(raioPadrao),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F1D2620),
          blurRadius: 12,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class _Quadrado extends StatelessWidget {
  const _Quadrado(this.cor, {this.tamanho = 12});

  final Color cor;
  final double tamanho;

  @override
  Widget build(BuildContext context) => Container(
    width: tamanho,
    height: tamanho,
    decoration: BoxDecoration(
      color: cor,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.dados, required this.detalhe});

  final _DadosMapa? dados;
  final bool detalhe;

  static const _suave = TextStyle(
    fontSize: 13,
    height: 1.4,
    color: AppCores.tinta3,
  );

  @override
  Widget build(BuildContext context) {
    final d = dados;
    final periodo = d == null || d.anoMin == null
        ? null
        : d.anoMin == d.anoMax
        ? '${d.anoMin}'
        : '${d.anoMin}–${d.anoMax}';

    return _CartaoFlutuante(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4, right: 8),
                child: _Quadrado(AppCores.alerta),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alertas de desmatamento',
                      style: TextStyle(fontSize: 15, color: AppCores.tinta),
                    ),
                    Text(
                      d == null
                          ? 'DETER-B / INPE'
                          : 'DETER-B / INPE'
                                '${periodo == null ? '' : ' · $periodo'}'
                                ' · ${_milhar(d.total)} alertas'
                                ' · ${_hectares(d.areaHa)}',
                      style: _suave,
                    ),
                    Text(
                      detalhe
                          ? 'Cada mancha é a área desmatada detectada.'
                          : 'Cada ponto é um alerta. Aproxime para ver a área.',
                      style: _suave,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Biomas, pelo limite do IBGE', style: _suave),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 2,
            children: [
              for (final b in biomas)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Quadrado(b.cor, tamanho: 10),
                    const SizedBox(width: 5),
                    Text(
                      b.nome,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppCores.tinta2,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Creditos extends StatelessWidget {
  const _Creditos();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppCores.branco.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text(
      'Mapa: Esri · Biomas: IBGE · Alertas: INPE',
      style: TextStyle(fontSize: 10, color: AppCores.tinta2),
    ),
  );
}

/// Alterna entre o mapa claro e a imagem de satelite.
class _BotaoFundo extends StatelessWidget {
  const _BotaoFundo({required this.fundo, required this.aoTocar});

  final _Fundo fundo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final claro = fundo == _Fundo.claro;
    return Semantics(
      button: true,
      label: claro ? 'Mostrar imagem de satélite' : 'Mostrar mapa',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: aoTocar,
          borderRadius: BorderRadius.circular(raioPadrao),
          child: _CartaoFlutuante(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  claro ? Icons.satellite_alt_outlined : Icons.map_outlined,
                  size: 18,
                  color: AppCores.mata,
                ),
                const SizedBox(width: 8),
                Text(
                  claro ? 'Satélite' : 'Mapa',
                  style: const TextStyle(fontSize: 15, color: AppCores.tinta),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Um bioma na lista do painel: amostra de cor, nome e quanto foi desmatado.
class _ItemBioma extends StatelessWidget {
  const _ItemBioma({
    required this.bioma,
    required this.ativo,
    required this.compacto,
    required this.aoEscolher,
  });

  final Bioma bioma;
  final bool ativo;
  final bool compacto;
  final VoidCallback aoEscolher;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Semantics(
      button: true,
      selected: ativo,
      child: InkWell(
        onTap: aoEscolher,
        borderRadius: BorderRadius.circular(raioPadrao),
        hoverColor: AppCores.papel2,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: EdgeInsets.symmetric(
            horizontal: compacto ? 10 : 12,
            vertical: compacto ? 8 : 9,
          ),
          decoration: BoxDecoration(
            color: ativo ? AppCores.branco : Colors.transparent,
            borderRadius: BorderRadius.circular(raioPadrao),
            border: Border.all(
              color: ativo ? AppCores.tinta3 : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              _Quadrado(bioma.cor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bioma.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compacto ? 15 : 16,
                    color: AppCores.tinta,
                  ),
                ),
              ),
              Text(
                '${bioma.percentualDesmatado}% desmatado',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppCores.tinta3,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LinhaDoTempo extends StatelessWidget {
  const _LinhaDoTempo();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 5),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: AppCores.linha)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in linhaDoTempoMapa)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -5.5,
                top: 5,
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
                padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
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

/// Painel que sobe do pe da tela no celular, com as abas Biomas e Linha do
/// tempo. Revisao de 01/10/2026: antes, no celular, a unica forma de escolher
/// um bioma era acertar o dedo no ponto certo do mapa — sem alternativa para
/// leitor de tela.
class _PainelCelular extends StatefulWidget {
  const _PainelCelular({
    required this.aberto,
    required this.selecionado,
    required this.aoSelecionar,
    required this.aoFechar,
  });

  final bool aberto;
  final Bioma? selecionado;
  final ValueChanged<Bioma> aoSelecionar;
  final VoidCallback aoFechar;

  @override
  State<_PainelCelular> createState() => _PainelCelularState();
}

class _PainelCelularState extends State<_PainelCelular> {
  bool _linhaDoTempo = false;

  @override
  Widget build(BuildContext context) {
    final duracao = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 300);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedSlide(
        offset: widget.aberto ? Offset.zero : const Offset(0, 1),
        duration: duracao,
        curve: Curves.easeOutCubic,
        child: Visibility(
          visible: widget.aberto,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .6,
            ),
            decoration: const BoxDecoration(
              color: AppCores.papel,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(top: BorderSide(color: AppCores.linha)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x261D2620),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  label: 'Fechar painel',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: widget.aoFechar,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppCores.linha,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppCores.linha)),
                  ),
                  child: Row(
                    children: [
                      _Aba(
                        rotulo: 'Biomas',
                        ativa: !_linhaDoTempo,
                        aoTocar: () => setState(() => _linhaDoTempo = false),
                      ),
                      const SizedBox(width: 20),
                      _Aba(
                        rotulo: 'Linha do tempo',
                        ativa: _linhaDoTempo,
                        aoTocar: () => setState(() => _linhaDoTempo = true),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                    child: _linhaDoTempo
                        ? const Padding(
                            padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
                            child: _LinhaDoTempo(),
                          )
                        : Column(
                            children: [
                              for (final b in biomas)
                                _ItemBioma(
                                  bioma: b,
                                  ativo: b == widget.selecionado,
                                  compacto: true,
                                  aoEscolher: () => widget.aoSelecionar(b),
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Aba extends StatelessWidget {
  const _Aba({
    required this.rotulo,
    required this.ativa,
    required this.aoTocar,
  });

  final String rotulo;
  final bool ativa;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: ativa,
    child: InkWell(
      onTap: aoTocar,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: ativa ? AppCores.mata : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: ativa ? FontWeight.w600 : FontWeight.w400,
            color: ativa ? AppCores.tinta : AppCores.tinta3,
          ),
        ),
      ),
    ),
  );
}

/// O que o site mostra no balao ao clicar num bioma: nome, area, quanto foi
/// desmatado e a descricao.
class _FichaBioma extends StatelessWidget {
  const _FichaBioma({required this.bioma, required this.aoFechar});

  final Bioma bioma;
  final VoidCallback aoFechar;

  @override
  Widget build(BuildContext context) => _CartaoFlutuante(
    padding: const EdgeInsets.fromLTRB(16, 6, 6, 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Quadrado(bioma.cor),
            const SizedBox(width: 8),
            Expanded(child: Text(bioma.nome, style: estiloTitulo(19))),
            IconButton(
              onPressed: aoFechar,
              icon: const Icon(Icons.close, size: 18),
              color: AppCores.tinta3,
              tooltip: 'Fechar',
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LinhaFicha(rotulo: 'Área total', valor: bioma.areaFormatada),
              const SizedBox(height: 5),
              _LinhaFicha(
                rotulo: 'Desmatamento',
                valor: '${bioma.percentualDesmatado}%',
                destaque: true,
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                bioma.descricao,
                style: const TextStyle(fontSize: 14, color: AppCores.tinta2),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LinhaFicha extends StatelessWidget {
  const _LinhaFicha({
    required this.rotulo,
    required this.valor,
    this.destaque = false,
  });

  final String rotulo;
  final String valor;
  final bool destaque;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        rotulo,
        style: const TextStyle(fontSize: 14, color: AppCores.tinta3),
      ),
      Text(
        valor,
        style: TextStyle(
          fontSize: 14,
          fontWeight: destaque ? FontWeight.w600 : FontWeight.w400,
          color: destaque ? AppCores.terra : AppCores.tinta2,
        ),
      ),
    ],
  );
}
