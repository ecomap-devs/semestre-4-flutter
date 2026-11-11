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
  static const tinta3 = Color(0xFF7A8075); // legenda, data, texto de apoio

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
TextStyle estiloTitulo(
  TextStyle papel, {
  Color cor = AppCores.tinta,
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

ThemeData construirTema() {
  final cantos = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(raioPadrao),
  );
  final borda = OutlineInputBorder(
    borderRadius: BorderRadius.circular(raioPadrao),
    borderSide: const BorderSide(color: AppCores.linha),
  );
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppCores.mata,
      primary: AppCores.mata,
      surface: AppCores.papel,
      error: AppCores.terra,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: AppCores.papel,
    fontFamily: AppFontes.texto,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppCores.papel,
      foregroundColor: AppCores.tinta,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: AppCores.linha)),
    ),
    textTheme: Escala.textTheme(titulo: AppCores.tinta, corpo: AppCores.tinta2),
    dividerTheme: const DividerThemeData(color: AppCores.linha),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: AppCores.papel,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppCores.mataClara,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (estados) => Escala.labelMedium.copyWith(
          fontWeight: estados.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: estados.contains(WidgetState.selected)
              ? AppCores.tinta
              : AppCores.tinta3,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (estados) => IconThemeData(
          color: estados.contains(WidgetState.selected)
              ? AppCores.mata
              : AppCores.tinta3,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppCores.papel,
      indicatorColor: AppCores.mataClara,
      selectedIconTheme: IconThemeData(color: AppCores.mata),
      unselectedIconTheme: IconThemeData(color: AppCores.tinta3),
      selectedLabelTextStyle: Escala.labelMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppCores.tinta,
      ),
      unselectedLabelTextStyle: Escala.labelMedium.copyWith(
        color: AppCores.tinta3,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppCores.branco,
      hintStyle: const TextStyle(color: AppCores.tinta3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: borda,
      enabledBorder: borda,
      disabledBorder: borda,
      focusedBorder: borda.copyWith(
        borderSide: const BorderSide(color: AppCores.mata, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppCores.mata,
        foregroundColor: AppCores.branco,
        disabledBackgroundColor: AppCores.mata.withValues(alpha: 0.6),
        disabledForegroundColor: AppCores.branco,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: cantos,
        textStyle: Escala.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppCores.mata,
        side: const BorderSide(color: AppCores.mata),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: cantos,
        textStyle: Escala.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppCores.mata,
        textStyle: Escala.labelLarge,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppCores.mata,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppCores.papel,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppCores.branco,
      surfaceTintColor: Colors.transparent,
      shape: cantos,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppCores.branco,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppCores.mataNoite,
      contentTextStyle: Escala.bodyMedium.copyWith(color: AppCores.branco),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
