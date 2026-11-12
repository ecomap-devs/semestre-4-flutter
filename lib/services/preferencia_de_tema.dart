import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O tema que a pessoa escolheu no botão da barra: seguir o sistema, claro ou
/// escuro (12/11/2026).
///
/// Até então o app só seguia o sistema, e quem queria o escuro só no EcoMap
/// (ou o claro, no sol) não tinha como. O padrão continua sendo o sistema.
///
/// Fica guardado neste aparelho, sem conta: é preferência de tela, não de
/// pessoa, e vale antes do login.
class PreferenciaDeTema extends ValueNotifier<ThemeMode> {
  PreferenciaDeTema([super.inicial = ThemeMode.system]);

  static const chave = 'tema';

  /// Lê a escolha guardada. Sem nada guardado, ou sem acesso ao
  /// armazenamento, segue o sistema.
  static Future<PreferenciaDeTema> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return PreferenciaDeTema(_ler(prefs.getString(chave)));
    } catch (_) {
      return PreferenciaDeTema();
    }
  }

  static ThemeMode _ler(String? nome) => ThemeMode.values.firstWhere(
    (m) => m.name == nome,
    orElse: () => ThemeMode.system,
  );

  /// Troca o tema na hora e guarda a escolha. Se não conseguir guardar, a
  /// troca vale até fechar o app.
  Future<void> escolher(ThemeMode modo) async {
    value = modo;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(chave, modo.name);
    } catch (_) {}
  }
}
