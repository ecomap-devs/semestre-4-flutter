import 'package:flutter/material.dart';

/// Cores do app — as mesmas variáveis do `globals.css` do site
/// (semestre-4-nextjs): tons de papel, mata e terra no lugar do verde #16a34a
/// e dos cinzas azulados herdados do React. Use sempre a constante, nunca o
/// hexadecimal solto, para que um ajuste aqui valha no app todo.
class AppCores {
  const AppCores._();

  static const papel = Color(0xFFF6F3EC); // fundo das telas
  static const papel2 = Color(
    0xFFECE7DB,
  ); // seção alternada, campo desabilitado
  static const branco = Color(0xFFFFFDF8); // cartão sobre o papel
  static const linha = Color(0xFFDDD6C6); // bordas e divisórias

  static const tinta = Color(0xFF1D2620); // títulos
  static const tinta2 = Color(0xFF4A5249); // texto corrido
  // Legenda, data, texto de apoio. Era 0xFF7A8075, com 3,7:1 sobre o papel;
  // desde 12/11/2026 passa de 4,5:1 sobre papel, papel2, cartão e mataClara.
  static const tinta3 = Color(0xFF646A5F);

  static const mata = Color(0xFF2F5233); // cor principal: botão, link, destaque
  static const mataEscura = Color(0xFF1F3A24); // faixa escura
  static const mataNoite = Color(0xFF16291A); // rodapé, fundo sob as fotos
  static const mataClara = Color(0xFFE3EADB); // aviso de sucesso, seleção

  static const terra = Color(0xFFA4472A); // perda, alerta, erro
  static const terraClara = Color(0xFFF3E1D8);
  static const ocre = Color(0xFFB8862B); // estrelas, atenção
  static const ocreClara = Color(0xFFF4E9CF);
  static const sol = Color(0xFFE3B553); // destaque sobre fundo escuro

  /// Texto claro sobre foto ou faixa escura (rgba(255,253,248,.78) no site).
  static const claroSuave = Color(0xC7FFFDF8);

  /// Escurecimento das fotos (rgb 16,24,18), em várias opacidades.
  static const sombraFoto = Color(0xFF101812);

  /// O véu atrás de diálogo e ficha: a tinta com 55%, como o
  /// rgba(29,38,32,.55) do site. Fixo de propósito: até 12/11/2026 era
  /// `context.cores.tinta`, que no tema escuro é quase branco e cobria a tela
  /// com um véu claro.
  static const veu = Color(0x8C1D2620);

  /// Vermelho dos alertas do DETER, no mapa e na legenda. Mais fechado que
  /// os tons dos biomas, para não se confundir com a Caatinga.
  static const alerta = Color(0xFFB4232A);

  /// Cores dos biomas: tons de terra e de mata, mais perto da paisagem de
  /// cada um. O Pantanal é azulado por ser a planície alagada. Valem para o
  /// mapa, a Home e as etiquetas — antes eram duas paletas diferentes.
  static const biomas = <String, Color>{
    'Amazônia': Color(0xFF2F5A32),
    'Cerrado': Color(0xFFC49A3A),
    'Caatinga': Color(0xFFB8653A),
    'Mata Atlântica': Color(0xFF6F9A5C),
    'Pantanal': Color(0xFF4F8299),
    'Pampa': Color(0xFFA7A35A),
  };

  /// Cor do texto do status, do mais grave ao menos grave. Antes cada status
  /// tinha um par de cores (fundo e texto do selo); o selo saiu. Os nomes sao
  /// os da lista nacional do MMA (`especies_data.dart`), e "Não ameaçada"
  /// para quem esta fora dela.
  static const status = <String, Color>{
    'Extinta': tinta,
    'Extinta na natureza': tinta,
    'Regionalmente extinta': tinta,
    'Criticamente em perigo': terra,
    'Em perigo': ocre,
    'Vulnerável': tinta3,
    'Não ameaçada': mata,
  };
}

/// Cores que mudam com o tema claro ou escuro do sistema.
///
/// Até 11/11/2026 o app só tinha tema claro, e quem usava o celular no escuro
/// abria uma tela de papel quase branco (auditoria de responsividade da
/// v1.3.0). Tudo que fica sobre o papel ou o cartão usa estas cores, por
/// `context.cores`; o que fica sobre foto ou faixa escura (abertura, rodapé,
/// faixas da Início) continua em [AppCores], porque já é escuro nos dois temas.
///
/// O escuro não é o claro invertido: o fundo é a mata de noite, e o texto é o
/// papel do tema claro. A mata, a terra e o ocre clareiam para manter o
/// contraste de texto (4,5:1 ou mais sobre o fundo e sobre o cartão).
@immutable
class Cores extends ThemeExtension<Cores> {
  const Cores({
    required this.papel,
    required this.papel2,
    required this.cartao,
    required this.linha,
    required this.tinta,
    required this.tinta2,
    required this.tinta3,
    required this.mata,
    required this.mataEscura,
    required this.mataClara,
    required this.terra,
    required this.terraClara,
    required this.ocre,
    required this.ocreClara,
    required this.sobreDestaque,
  });

  final Color papel; // fundo das telas
  final Color papel2; // seção alternada, campo desabilitado
  final Color cartao; // cartão sobre o papel (o `branco` do tema claro)
  final Color linha; // bordas e divisórias
  final Color tinta; // títulos
  final Color tinta2; // texto corrido
  final Color tinta3; // legenda, data, texto de apoio
  final Color mata; // botão, link, destaque
  final Color mataEscura; // texto de sucesso
  final Color mataClara; // fundo de sucesso, seleção
  final Color terra; // perda, alerta, erro
  final Color terraClara;
  final Color ocre; // estrelas, atenção
  final Color ocreClara;

  /// Texto e ícone sobre um fundo cheio de [mata] ou [terra]: botão,
  /// filtro ativo. No claro é o branco; no escuro, a mata fica clara e o texto
  /// por cima precisa ser escuro.
  final Color sobreDestaque;

  static const claro = Cores(
    papel: AppCores.papel,
    papel2: AppCores.papel2,
    cartao: AppCores.branco,
    linha: AppCores.linha,
    tinta: AppCores.tinta,
    tinta2: AppCores.tinta2,
    tinta3: AppCores.tinta3,
    mata: AppCores.mata,
    mataEscura: AppCores.mataEscura,
    mataClara: AppCores.mataClara,
    terra: AppCores.terra,
    terraClara: AppCores.terraClara,
    ocre: AppCores.ocre,
    ocreClara: AppCores.ocreClara,
    sobreDestaque: AppCores.branco,
  );

  static const escuro = Cores(
    papel: Color(0xFF131814),
    papel2: Color(0xFF1B221D),
    cartao: Color(0xFF1F2721),
    linha: Color(0xFF333D35),
    tinta: Color(0xFFECE8DE),
    tinta2: Color(0xFFC5C7BD),
    tinta3: Color(0xFF979C90),
    mata: Color(0xFF8FBF8A),
    mataEscura: Color(0xFFB5D6AE),
    mataClara: Color(0xFF24362A),
    terra: Color(0xFFE08A6C),
    terraClara: Color(0xFF3A231B),
    ocre: Color(0xFFD9AE57),
    ocreClara: Color(0xFF3A2F17),
    sobreDestaque: Color(0xFF10170F),
  );

  /// Cor do texto do status, do mais grave ao menos grave — a mesma ordem de
  /// [AppCores.status], com os tons deste tema.
  Color status(String status) => switch (status) {
    'Extinta' || 'Extinta na natureza' || 'Regionalmente extinta' => tinta,
    'Criticamente em perigo' => terra,
    'Em perigo' => ocre,
    'Não ameaçada' => mata,
    _ => tinta3,
  };

  @override
  Cores copyWith({
    Color? papel,
    Color? papel2,
    Color? cartao,
    Color? linha,
    Color? tinta,
    Color? tinta2,
    Color? tinta3,
    Color? mata,
    Color? mataEscura,
    Color? mataClara,
    Color? terra,
    Color? terraClara,
    Color? ocre,
    Color? ocreClara,
    Color? sobreDestaque,
  }) => Cores(
    papel: papel ?? this.papel,
    papel2: papel2 ?? this.papel2,
    cartao: cartao ?? this.cartao,
    linha: linha ?? this.linha,
    tinta: tinta ?? this.tinta,
    tinta2: tinta2 ?? this.tinta2,
    tinta3: tinta3 ?? this.tinta3,
    mata: mata ?? this.mata,
    mataEscura: mataEscura ?? this.mataEscura,
    mataClara: mataClara ?? this.mataClara,
    terra: terra ?? this.terra,
    terraClara: terraClara ?? this.terraClara,
    ocre: ocre ?? this.ocre,
    ocreClara: ocreClara ?? this.ocreClara,
    sobreDestaque: sobreDestaque ?? this.sobreDestaque,
  );

  @override
  Cores lerp(Cores? outro, double t) {
    if (outro == null) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return Cores(
      papel: m(papel, outro.papel),
      papel2: m(papel2, outro.papel2),
      cartao: m(cartao, outro.cartao),
      linha: m(linha, outro.linha),
      tinta: m(tinta, outro.tinta),
      tinta2: m(tinta2, outro.tinta2),
      tinta3: m(tinta3, outro.tinta3),
      mata: m(mata, outro.mata),
      mataEscura: m(mataEscura, outro.mataEscura),
      mataClara: m(mataClara, outro.mataClara),
      terra: m(terra, outro.terra),
      terraClara: m(terraClara, outro.terraClara),
      ocre: m(ocre, outro.ocre),
      ocreClara: m(ocreClara, outro.ocreClara),
      sobreDestaque: m(sobreDestaque, outro.sobreDestaque),
    );
  }
}

/// `context.cores.tinta` no lugar de `AppCores.tinta`, para seguir o tema.
extension CoresDoTema on BuildContext {
  Cores get cores => Theme.of(this).extension<Cores>() ?? Cores.claro;

  /// Tema escuro ligado (pelo sistema).
  bool get temaEscuro => Theme.of(this).brightness == Brightness.dark;
}

/// Famílias de fonte declaradas no `pubspec.yaml`.
class AppFontes {
  const AppFontes._();

  static const titulo = 'Fraunces';
  static const texto = 'SourceSans3';
}

/// Raio padrão de cantos (`--raio` do site).
const raioPadrao = 6.0;

/// Escala tipográfica do app, nos papéis do Material 3.
///
/// Até 11/11/2026 cada texto escolhia o `fontSize` à mão: eram 125, de 10 a
/// 52, sem papel nenhum (auditoria de responsividade da v1.3.0). Agora todo
/// texto usa um destes papéis, e o `textTheme` do tema é feito deles, então os
/// componentes do Material (diálogos, campos, menus) seguem a mesma escala.
///
/// Display, headline e `titleLarge` são títulos, em Fraunces com peso médio;
/// o resto é Source Sans. Os tamanhos são os do app, não os do Material: o
/// papel diz para que serve o texto, e o tamanho vem do desenho que já existia.
/// Nada fixa o `textScaler`: a fonte do sistema continua valendo para todos.
class Escala {
  const Escala._();

  /// Título de seção grande, no desktop.
  static const displayLarge = TextStyle(
    fontFamily: AppFontes.titulo,
    fontSize: 48,
    fontWeight: FontWeight.w500,
    height: 1.05,
    letterSpacing: -0.72, // -1,5% do tamanho
  );

  /// Título de seção no tablet; número de destaque.
  static const displayMedium = TextStyle(
    fontFamily: AppFontes.titulo,
    fontSize: 40,
    fontWeight: FontWeight.w500,
    height: 1.05,
    letterSpacing: -0.6, // -1,5% do tamanho
  );

  /// Título de seção no celular.
  static const displaySmall = TextStyle(
    fontFamily: AppFontes.titulo,
    fontSize: 34,
    fontWeight: FontWeight.w500,
    height: 1.05,
    letterSpacing: -0.51, // -1,5% do tamanho
  );

  /// Título de página e de diálogo grande.
  static const headlineLarge = TextStyle(
    fontFamily: AppFontes.titulo,
    fontSize: 32,
    fontWeight: FontWeight.w500,
    height: 1.1,
    letterSpacing: -0.48, // -1,5% do tamanho
  );

  /// Nome na ficha da espécie, título de cartão grande.
  static const headlineMedium = TextStyle(
    fontFamily: AppFontes.titulo,
    fontSize: 26,
    fontWeight: FontWeight.w500,
    height: 1.1,
    letterSpacing: -0.39, // -1,5% do tamanho
  );

  /// Título de cartão e de diálogo.
  static const headlineSmall = TextStyle(
    fontFamily: AppFontes.titulo,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.1,
    letterSpacing: -0.36, // -1,5% do tamanho
  );

  /// Título de painel e de bloco ("Biomas", "Linha do tempo").
  static const titleLarge = TextStyle(
    fontFamily: AppFontes.titulo,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.1,
    letterSpacing: -0.3, // -1,5% do tamanho
  );

  /// Texto de abertura, abaixo de um título; botão grande sobre foto.
  static const titleMedium = TextStyle(
    fontFamily: AppFontes.texto,
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  /// Rótulo forte de item de lista.
  static final titleSmall = Escala.labelLarge;

  /// Texto corrido.
  static const bodyLarge = TextStyle(
    fontFamily: AppFontes.texto,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  /// Texto de apoio em cartões e listas.
  static const bodyMedium = TextStyle(
    fontFamily: AppFontes.texto,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  /// Texto secundário: data, fonte, legenda de gráfico.
  static const bodySmall = TextStyle(
    fontFamily: AppFontes.texto,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Botões e abas.
  static const labelLarge = TextStyle(
    fontFamily: AppFontes.texto,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Etiqueta, legenda do mapa, rótulo da barra de navegação.
  static const labelMedium = TextStyle(
    fontFamily: AppFontes.texto,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  /// Crédito de foto e de mapa.
  static const labelSmall = TextStyle(
    fontFamily: AppFontes.texto,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// Título sobre foto ou faixa escura, no tablet e no desktop. Fica acima dos
  /// papéis do Material, que param no `displayLarge`: só para estes lugares.
  static const destaque = TextStyle(
    fontFamily: AppFontes.titulo,
    fontSize: 64,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: -0.96, // -1,5% do tamanho
  );

  /// Os números grandes da Home ("1,5 mi ha"). Também acima do Material.
  static const numero = TextStyle(
    fontFamily: AppFontes.titulo,
    fontSize: 88,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: -1.32, // -1,5% do tamanho
  );

  /// O `TextTheme` do tema, com as cores de texto do app.
  static TextTheme textTheme({required Color titulo, required Color corpo}) =>
      TextTheme(
        displayLarge: displayLarge.copyWith(color: titulo),
        displayMedium: displayMedium.copyWith(color: titulo),
        displaySmall: displaySmall.copyWith(color: titulo),
        headlineLarge: headlineLarge.copyWith(color: titulo),
        headlineMedium: headlineMedium.copyWith(color: titulo),
        headlineSmall: headlineSmall.copyWith(color: titulo),
        titleLarge: titleLarge.copyWith(color: titulo),
        titleMedium: titleMedium.copyWith(color: titulo),
        titleSmall: titleSmall.copyWith(color: titulo),
        bodyLarge: bodyLarge.copyWith(color: corpo),
        bodyMedium: bodyMedium.copyWith(color: corpo),
        bodySmall: bodySmall.copyWith(color: corpo),
        labelLarge: labelLarge.copyWith(color: titulo),
        labelMedium: labelMedium.copyWith(color: corpo),
        labelSmall: labelSmall.copyWith(color: corpo),
      );
}

/// Título em serifa, com peso médio: o 800 em tudo era o que mais dava cara
/// de modelo pronto. O tamanho vem de um papel da [Escala].
///
/// A cor é obrigatória: um padrão fixo deixava o título escuro sobre o fundo
/// escuro do tema da noite. Use `context.cores.tinta` sobre o papel.
TextStyle estiloTitulo(
  TextStyle papel, {
  required Color cor,
  FontWeight peso = FontWeight.w500,
  double? altura,
}) => papel.copyWith(
  fontFamily: AppFontes.titulo,
  fontWeight: peso,
  color: cor,
  height: altura,
);

/// Larguras de quebra herdadas do `useWindowSize()` da versao React.
///
/// Ate 11/11/2026 o celular era decidido so pela largura, e um celular deitado
/// (cerca de 915x412 dp) ganhava o layout de tablet: trilho lateral, painel de
/// 320 dp no Mapa e a abertura da Home com os botoes fora da tela. Agora conta
/// tambem o lado menor da tela: abaixo de [ladoMenorDeTablet] e celular, em pe
/// ou deitado (o limite e o da classe "compacta" do Material).
class Breakpoints {
  const Breakpoints._();
  static const mobile = 768.0;
  static const tablet = 1024.0;
  static const ladoMenorDeTablet = 600.0;

  static bool ehMobile(BuildContext c) => ehMobileEm(MediaQuery.sizeOf(c));
  static bool ehTablet(BuildContext c) => ehTabletEm(MediaQuery.sizeOf(c));

  /// O mesmo que [ehMobile], para um tamanho dado (e para os testes).
  static bool ehMobileEm(Size tela) =>
      tela.width < mobile || tela.shortestSide < ladoMenorDeTablet;

  static bool ehTabletEm(Size tela) => !ehMobileEm(tela) && tela.width < tablet;

  /// Celular deitado: layout de celular, mas com pouca altura para a
  /// abertura, a legenda e os paineis.
  static bool ehCelularDeitado(BuildContext c) {
    final tela = MediaQuery.sizeOf(c);
    return ehMobileEm(tela) && tela.width > tela.height;
  }
}

/// Tema do app. [escuro] liga as cores de [Cores.escuro]; o `MaterialApp`
/// monta os dois e o sistema escolhe.
ThemeData construirTema({bool escuro = false}) {
  final c = escuro ? Cores.escuro : Cores.claro;
  final cantos = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(raioPadrao),
  );
  final borda = OutlineInputBorder(
    borderRadius: BorderRadius.circular(raioPadrao),
    borderSide: BorderSide(color: c.linha),
  );
  final base = ThemeData(
    brightness: escuro ? Brightness.dark : Brightness.light,
    extensions: [c],
    colorScheme: ColorScheme.fromSeed(
      brightness: escuro ? Brightness.dark : Brightness.light,
      seedColor: AppCores.mata,
      onPrimary: c.sobreDestaque,
      onSurface: c.tinta,
      surfaceContainerHighest: c.papel2,
      primary: c.mata,
      surface: c.papel,
      error: c.terra,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: c.papel,
    fontFamily: AppFontes.texto,
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: c.papel,
      foregroundColor: c.tinta,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: c.linha)),
    ),
    textTheme: Escala.textTheme(titulo: c.tinta, corpo: c.tinta2),
    dividerTheme: DividerThemeData(color: c.linha),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: c.papel,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.mataClara,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (estados) => Escala.labelMedium.copyWith(
          fontWeight: estados.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: estados.contains(WidgetState.selected) ? c.tinta : c.tinta3,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (estados) => IconThemeData(
          color: estados.contains(WidgetState.selected) ? c.mata : c.tinta3,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.papel,
      indicatorColor: c.mataClara,
      selectedIconTheme: IconThemeData(color: c.mata),
      unselectedIconTheme: IconThemeData(color: c.tinta3),
      selectedLabelTextStyle: Escala.labelMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: c.tinta,
      ),
      unselectedLabelTextStyle: Escala.labelMedium.copyWith(color: c.tinta3),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.cartao,
      hintStyle: TextStyle(color: c.tinta3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: borda,
      enabledBorder: borda,
      disabledBorder: borda,
      focusedBorder: borda.copyWith(
        borderSide: BorderSide(color: c.mata, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.mata,
        foregroundColor: c.sobreDestaque,
        disabledBackgroundColor: c.mata.withValues(alpha: 0.6),
        disabledForegroundColor: c.sobreDestaque,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: cantos,
        textStyle: Escala.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.mata,
        side: BorderSide(color: c.mata),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: cantos,
        textStyle: Escala.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.mata,
        textStyle: Escala.labelLarge,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.mata),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.papel,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.cartao,
      surfaceTintColor: Colors.transparent,
      shape: cantos,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.cartao,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppCores.mataNoite,
      contentTextStyle: Escala.bodyMedium.copyWith(color: c.papel),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
