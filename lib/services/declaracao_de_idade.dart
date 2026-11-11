import 'package:shared_preferences/shared_preferences.dart';

/// Quem já declarou ter 18 anos ou mais para usar a identificação por foto,
/// por conta, neste aparelho (11/11/2026).
///
/// Os termos da Gemini API (em vigor desde 23/03/2026) exigem 18 anos e não
/// aceitam app de acesso provável por menores. A pergunta não prova a idade:
/// é a trava por autodeclaração escolhida pelo grupo, que deixa claro a quem
/// usa que o recurso é só para adultos. O site guarda a mesma resposta no
/// `localStorage` (`src/lib/idade.ts`).
///
/// Só o "sim" fica guardado, com a data. O "não" vale para a visita: guardá-lo
/// deixaria preso para sempre quem tocou errado.
class DeclaracaoDeIdade {
  const DeclaracaoDeIdade();

  static String chave(String uid) => 'maior_de_18:$uid';

  /// Se a conta [uid] já disse ter 18 anos ou mais neste aparelho. Sem acesso
  /// ao armazenamento, vale `false`: a pergunta aparece de novo.
  Future<bool> declarou(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(chave(uid)) != null;
    } catch (_) {
      return false;
    }
  }

  /// Guarda o "tenho 18 anos ou mais" de [uid], com a data da resposta.
  Future<void> registrar(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chave(uid), DateTime.now().toUtc().toIso8601String());
  }
}
