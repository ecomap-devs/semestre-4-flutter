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

  /// Vermelho dos alertas do DETER-B, no mapa e na legenda. Mais fechado que
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
  /// tinha um par de cores (fundo e texto do selo); o selo saiu.
  static const status = <String, Color>{
    'Extinta na natureza': tinta,
    'Criticamente ameaçada': terra,
    'Em perigo': ocre,
    'Vulnerável': tinta3,
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

/// Título em serifa, com peso médio: o 800 em tudo era o que mais dava cara
/// de modelo pronto.
TextStyle estiloTitulo(
  double tamanho, {
  Color cor = AppCores.tinta,
  FontWeight peso = FontWeight.w500,
  double altura = 1.1,
}) => TextStyle(
  fontFamily: AppFontes.titulo,
  fontSize: tamanho,
  fontWeight: peso,
  color: cor,
  height: altura,
  letterSpacing: -tamanho * 0.015,
);

/// Larguras de quebra herdadas do `useWindowSize()` da versao React.
class Breakpoints {
  const Breakpoints._();
  static const mobile = 768.0;
  static const tablet = 1024.0;

  static bool ehMobile(BuildContext c) => MediaQuery.sizeOf(c).width < mobile;
  static bool ehTablet(BuildContext c) {
    final l = MediaQuery.sizeOf(c).width;
    return l >= mobile && l < tablet;
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
    textTheme: base.textTheme.apply(
      bodyColor: AppCores.tinta2,
      displayColor: AppCores.tinta,
    ),
    dividerTheme: const DividerThemeData(color: AppCores.linha),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: AppCores.papel,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppCores.mataClara,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (estados) => TextStyle(
          fontSize: 13,
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
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppCores.papel,
      indicatorColor: AppCores.mataClara,
      selectedIconTheme: IconThemeData(color: AppCores.mata),
      unselectedIconTheme: IconThemeData(color: AppCores.tinta3),
      selectedLabelTextStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppCores.tinta,
      ),
      unselectedLabelTextStyle: TextStyle(fontSize: 13, color: AppCores.tinta3),
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
        textStyle: const TextStyle(
          fontFamily: AppFontes.texto,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppCores.mata,
        side: const BorderSide(color: AppCores.mata),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: cantos,
        textStyle: const TextStyle(
          fontFamily: AppFontes.texto,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppCores.mata,
        textStyle: const TextStyle(
          fontFamily: AppFontes.texto,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
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
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppCores.mataNoite,
      contentTextStyle: TextStyle(
        fontFamily: AppFontes.texto,
        fontSize: 15,
        color: AppCores.branco,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
