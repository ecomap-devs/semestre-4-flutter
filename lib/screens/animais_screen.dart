import 'package:flutter/material.dart';

import '../data/animais_data.dart';
import '../models/animal.dart';
import '../theme/app_theme.dart';
import '../widgets/animacao_na_tela.dart';
import '../widgets/charts/linha_chart.dart';
import '../widgets/imagem_com_reserva.dart';
import '../widgets/rolagem_suave.dart';

/// Busca sem acento e sem caixa: "onca" acha "Onça-pintada".
String normalizarBusca(String texto) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'aaaaaeeeeiiiiooooouuuucn';
  final minusculo = texto.toLowerCase();
  final saida = StringBuffer();
  for (final letra in minusculo.split('')) {
    final i = de.indexOf(letra);
    saida.write(i < 0 ? letra : para[i]);
  }
  return saida.toString();
}

/// Catalogo de especies ameacadas — a pagina Animais do site.
class AnimaisScreen extends StatefulWidget {
  const AnimaisScreen({super.key});

  @override
  State<AnimaisScreen> createState() => _AnimaisScreenState();
}

class _AnimaisScreenState extends State<AnimaisScreen> {
  final _busca = TextEditingController();

  String _bioma = 'Todos';
  String _status = 'Todos';
  bool _filtrosAbertos = false;

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  List<Animal> get _filtrados {
    final termo = normalizarBusca(_busca.text.trim());
    return animais.where((a) {
      final casaBusca =
          normalizarBusca(a.nome).contains(termo) ||
          normalizarBusca(a.bioma).contains(termo);
      final casaBioma = _bioma == 'Todos' || a.bioma == _bioma;
      final casaStatus = _status == 'Todos' || a.status == _status;
      return casaBusca && casaBioma && casaStatus;
    }).toList();
  }

  void _limpar() {
    _busca.clear();
    setState(() {
      _bioma = 'Todos';
      _status = 'Todos';
    });
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;
    final mobile = Breakpoints.ehMobile(context);
    final margem = mobile ? 16.0 : 24.0;

    return RolagemSuave(
      builder: (_, controlador) => CustomScrollView(
        controller: controlador,
        slivers: [
          const SliverToBoxAdapter(child: _Abertura()),
          PinnedHeaderSliver(
            child: _BarraDeFiltros(
              busca: _busca,
              bioma: _bioma,
              status: _status,
              quantidade: lista.length,
              abertos: _filtrosAbertos,
              aoBuscar: () => setState(() {}),
              aoMudarBioma: (b) => setState(() => _bioma = b),
              aoMudarStatus: (s) => setState(() => _status = s),
              aoAbrirFiltros: () =>
                  setState(() => _filtrosAbertos = !_filtrosAbertos),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              margem,
              mobile ? 28 : 48,
              margem,
              mobile ? 56 : 80,
            ),
            sliver: lista.isEmpty
                ? SliverToBoxAdapter(child: _Vazio(aoLimpar: _limpar))
                : SliverLayoutBuilder(
                    builder: (context, c) {
                      final largura = c.crossAxisExtent.clamp(0.0, 1120.0);
                      final colunas = mobile
                          ? 1
                          : (largura / 300).floor().clamp(1, 3);
                      final espaco = mobile ? 16.0 : 32.0;
                      final linhas = (lista.length / colunas).ceil();
                      return SliverList.separated(
                        itemCount: linhas,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: mobile ? 40 : 56),
                        itemBuilder: (_, linha) => Center(
                          child: SizedBox(
                            width: largura,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var j = 0; j < colunas; j++) ...[
                                  if (j > 0) SizedBox(width: espaco),
                                  Expanded(
                                    child: linha * colunas + j < lista.length
                                        ? RevelarAoRolar(
                                            key: ValueKey(
                                              lista[linha * colunas + j].nome,
                                            ),
                                            atraso: Duration(
                                              milliseconds: j * 80,
                                            ),
                                            child: _CartaoAnimal(
                                              animal:
                                                  lista[linha * colunas + j],
                                              aoTocar: () => _abrirFicha(
                                                lista[linha * colunas + j],
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppCores.linha)),
              ),
              padding: EdgeInsets.symmetric(horizontal: margem, vertical: 20),
              child: const Text(
                '© 2025 EcoMapBrasil · Dados de conservação baseados em IUCN, '
                'ICMBio e WWF Brasil.',
                style: TextStyle(fontSize: 14, color: AppCores.tinta3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirFicha(Animal a) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppCores.branco,
      barrierColor: AppCores.tinta.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controlador) =>
            _FichaAnimal(animal: a, controlador: controlador),
      ),
    );
  }
}

/// Abertura sobre a foto da primeira especie, como as faixas de foto da Home.
class _Abertura extends StatelessWidget {
  const _Abertura();

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.ehMobile(context);
    final resumo = [
      (animais.length, 'espécies listadas'),
      (
        animais.where((a) => a.status == 'Criticamente ameaçada').length,
        'criticamente ameaçadas',
      ),
      (
        animais.where((a) => a.status == 'Extinta na natureza').length,
        'extinta na natureza',
      ),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: mobile ? 420 : 520),
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: ImagemComReserva(
                url: animais.first.imagem,
                alinhamento: const Alignment(0, -.3),
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
                  stops: [0, .55, 1],
                  colors: [
                    Color(0xEB101812),
                    Color(0x73101812),
                    Color(0x33101812),
                  ],
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: mobile ? 420 : 520),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: mobile
                      ? const EdgeInsets.fromLTRB(16, 48, 16, 32)
                      : const EdgeInsets.fromLTRB(24, 80, 24, 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Espécies que o desmatamento está levando embora',
                          style: estiloTitulo(
                            mobile ? 38 : 64,
                            cor: AppCores.branco,
                            altura: 1.02,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Text(
                          'Cada uma depende de um pedaço de mata que está '
                          'sumindo. Toque numa espécie para ver como a '
                          'população dela mudou desde '
                          '${animais.first.anos.first}.',
                          style: TextStyle(
                            fontSize: mobile ? 17 : 20,
                            height: 1.45,
                            color: const Color(0xD9FFFDF8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 32,
                        runSpacing: 8,
                        children: [
                          for (final (valor, rotulo) in resumo)
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$valor  ',
                                    style: estiloTitulo(
                                      mobile ? 30 : 40,
                                      cor: AppCores.sol,
                                    ),
                                  ),
                                  TextSpan(text: rotulo),
                                ],
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppCores.claroSuave,
                              ),
                            ),
                        ],
                      ),
                    ],
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

class _BarraDeFiltros extends StatelessWidget {
  const _BarraDeFiltros({
    required this.busca,
    required this.bioma,
    required this.status,
    required this.quantidade,
    required this.abertos,
    required this.aoBuscar,
    required this.aoMudarBioma,
    required this.aoMudarStatus,
    required this.aoAbrirFiltros,
  });

  final TextEditingController busca;
  final String bioma;
  final String status;
  final int quantidade;
  final bool abertos;
  final VoidCallback aoBuscar;
  final ValueChanged<String> aoMudarBioma;
  final ValueChanged<String> aoMudarStatus;
  final VoidCallback aoAbrirFiltros;

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.ehMobile(context);
    final temFiltro = bioma != 'Todos' || status != 'Todos';
    final contador = Text(
      '$quantidade espécie${quantidade == 1 ? '' : 's'}',
      style: const TextStyle(fontSize: 15, color: AppCores.tinta3),
    );

    final campo = TextField(
      controller: busca,
      onChanged: (_) => aoBuscar(),
      style: const TextStyle(fontSize: 16, color: AppCores.tinta),
      decoration: InputDecoration(
        hintText: 'Buscar espécie ou bioma',
        isDense: true,
        prefixIcon: const Icon(Icons.search, size: 20, color: AppCores.tinta3),
        suffixIcon: busca.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Limpar a busca',
                onPressed: () {
                  busca.clear();
                  aoBuscar();
                },
              ),
      ),
    );

    final biomas = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final b in biomasFiltro)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _Filtro(
                rotulo: b,
                ativo: bioma == b,
                aoTocar: () => aoMudarBioma(b),
              ),
            ),
        ],
      ),
    );

    final seletorStatus = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppCores.branco,
        border: Border.all(color: AppCores.linha),
        borderRadius: BorderRadius.circular(raioPadrao),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: status,
          isExpanded: true,
          dropdownColor: AppCores.branco,
          style: const TextStyle(
            fontFamily: AppFontes.texto,
            fontSize: 15,
            color: AppCores.tinta2,
          ),
          onChanged: (s) => aoMudarStatus(s ?? 'Todos'),
          items: [
            for (final s in statusFiltro)
              DropdownMenuItem(
                value: s,
                child: Text(s == 'Todos' ? 'Qualquer status' : s),
              ),
          ],
        ),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppCores.papel,
        border: Border(bottom: BorderSide(color: AppCores.linha)),
      ),
      padding: mobile
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: campo),
                  const SizedBox(width: 10),
                  if (mobile)
                    // Encolhe em vez de estourar quando a fonte do sistema
                    // esta grande.
                    Flexible(
                      child: OutlinedButton.icon(
                        onPressed: aoAbrirFiltros,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          backgroundColor: abertos
                              ? AppCores.papel2
                              : AppCores.branco,
                          foregroundColor: temFiltro
                              ? AppCores.mata
                              : AppCores.tinta2,
                          side: BorderSide(
                            color: temFiltro ? AppCores.mata : AppCores.linha,
                          ),
                          textStyle: const TextStyle(
                            fontFamily: AppFontes.texto,
                            fontSize: 15,
                          ),
                        ),
                        icon: const Icon(Icons.tune, size: 18),
                        label: Text(
                          'Filtros',
                          overflow: TextOverflow.ellipsis,
                          semanticsLabel: temFiltro
                              ? 'Filtros (com filtro ativo)'
                              : 'Filtros',
                        ),
                      ),
                    )
                  else
                    contador,
                ],
              ),
              if (!mobile) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(flex: 2, child: biomas),
                    const SizedBox(width: 16),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: seletorStatus,
                      ),
                    ),
                  ],
                ),
              ] else if (abertos) ...[
                const SizedBox(height: 12),
                biomas,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: seletorStatus),
                    const SizedBox(width: 10),
                    contador,
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Filtro extends StatelessWidget {
  const _Filtro({
    required this.rotulo,
    required this.ativo,
    required this.aoTocar,
  });

  final String rotulo;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: ativo,
    child: InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 36),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: ativo ? AppCores.mata : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: ativo ? AppCores.mata : AppCores.linha),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            fontSize: 15,
            color: ativo ? AppCores.branco : AppCores.tinta2,
          ),
        ),
      ),
    ),
  );
}

class _CartaoAnimal extends StatelessWidget {
  const _CartaoAnimal({required this.animal, required this.aoTocar});

  final Animal animal;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Ver ficha de ${animal.nome}',
    child: InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(raioPadrao),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(raioPadrao),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ImagemComReserva(url: animal.imagem),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            animal.status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: animal.corStatus,
            ),
          ),
          const SizedBox(height: 2),
          Text(animal.nome, style: estiloTitulo(22)),
          const SizedBox(height: 2),
          Text(
            animal.bioma,
            style: const TextStyle(fontSize: 14, color: AppCores.tinta3),
          ),
          const SizedBox(height: 8),
          Text(
            animal.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppCores.tinta2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'População',
                style: TextStyle(fontSize: 14, color: AppCores.tinta3),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: animal.populacao == 0
                            ? 'extinta · '
                            : '${animal.populacaoComMilhar} indivíduos · ',
                      ),
                      TextSpan(
                        text: animal.variacaoFormatada,
                        style: TextStyle(
                          color: animal.corTendencia,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14, color: AppCores.tinta2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          LinhaChart(
            valores: animal.tendencia,
            rotulos: animal.anos,
            cor: animal.corTendencia,
          ),
          const SizedBox(height: 10),
          const ExcludeSemantics(
            child: Text(
              'Ver ficha →',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppCores.mata,
                decoration: TextDecoration.underline,
                decorationColor: Color(0x592F5233),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FichaAnimal extends StatelessWidget {
  const _FichaAnimal({required this.animal, required this.controlador});

  final Animal animal;
  final ScrollController controlador;

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.ehMobile(context);
    final periodo = '${animal.anos.first}–${animal.anos.last}';
    final dados = [
      (
        'População estimada',
        animal.populacao == 0 ? 'Extinta' : animal.populacaoComMilhar,
        animal.populacao == 0 ? AppCores.terra : AppCores.tinta,
      ),
      ('Variação ($periodo)', animal.variacaoFormatada, animal.corTendencia),
    ];

    return ListView(
      controller: controlador,
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: mobile ? 200 : 300,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImagemComReserva(url: animal.imagem),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: AppCores.branco,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppCores.tinta,
                    tooltip: 'Fechar',
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: mobile
              ? const EdgeInsets.fromLTRB(18, 20, 18, 28)
              : const EdgeInsets.fromLTRB(32, 28, 32, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                animal.status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: animal.corStatus,
                ),
              ),
              const SizedBox(height: 4),
              Semantics(
                header: true,
                child: Text(animal.nome, style: estiloTitulo(mobile ? 26 : 32)),
              ),
              const SizedBox(height: 4),
              Text(
                '${animal.bioma} · ${animal.regiao}',
                style: const TextStyle(fontSize: 15, color: AppCores.tinta3),
              ),
              const SizedBox(height: 16),
              Text(
                animal.descricao,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.55,
                  color: AppCores.tinta2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, (rotulo, valor, cor)) in dados.indexed) ...[
                    if (i > 0) const SizedBox(width: 24),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppCores.linha),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              valor,
                              style: estiloTitulo(mobile ? 26 : 30, cor: cor),
                            ),
                            Text(
                              rotulo,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppCores.tinta3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Text('População de $periodo', style: estiloTitulo(18)),
              const SizedBox(height: 10),
              LinhaChart(
                valores: animal.tendencia,
                rotulos: animal.anos,
                cor: animal.corTendencia,
                altura: 90,
              ),
              const SizedBox(height: 24),
              Text('Principais ameaças', style: estiloTitulo(18)),
              const SizedBox(height: 8),
              for (final ameaca in animal.ameacas)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    '•  $ameaca',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppCores.tinta2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio({required this.aoLimpar});

  final VoidCallback aoLimpar;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nenhuma espécie encontrada com esses filtros.',
              style: TextStyle(fontSize: 18, color: AppCores.tinta),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: aoLimpar,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontFamily: AppFontes.texto,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              child: const Text('Limpar a busca e os filtros'),
            ),
          ],
        ),
      ),
    ),
  );
}
