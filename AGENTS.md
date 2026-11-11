# AGENTS.md — regras do EcoMapBrasil

Regras para quem mexe neste repositório: os cinco do grupo e qualquer assistente
de IA (Claude Code, Copilot, Codex, Gemini). Vale para todos igualmente.

---

## O projeto em três linhas

App Android em Flutter sobre desmatamento e fauna ameaçada nos biomas brasileiros. O
site é o [semestre-4-nextjs](https://github.com/ecomap-devs/semestre-4-nextjs), no mesmo backend. Projeto Interdisciplinar da FATEC, migrado de uma versão React do
semestre anterior. Backend: Firebase (Auth, Firestore) e Supabase (Storage).

---

## 🔴 Regra número um: credenciais

**Nenhuma chave, token ou segredo entra no código-fonte. Nunca.**

As credenciais vivem em `env.json`, que está no `.gitignore`, e chegam ao app por
`--dart-define-from-file`. Os nomes das variáveis estão em `env.example.json`.

```bash
flutter run   --dart-define-from-file=env.json
flutter build apk --dart-define-from-file=env.json
```

Já está no `.gitignore`, e **não tire de lá**:

| Arquivo | Por quê |
|---|---|
| `env.json` | As credenciais |
| `lib/firebase_options.dart` | O `flutterfire configure` gera com as chaves dentro |
| `android/app/google-services.json` | Idem |
| `ios/Runner/GoogleService-Info.plist` | Idem |
| `android/key.properties`, `*.jks`, `*.keystore` | Assinatura de release |

**Uma exceção, e é de propósito:** `android/keystore/debug.jks` **é versionado**. Sem
um keystore de debug compartilhado, cada pessoa assinaria com o próprio
`~/.android/debug.keystore` e teria um SHA-1 diferente — e como a chave de API do
Firebase é restrita por package + SHA-1, o login quebraria para quem não estivesse na
lista, em silêncio, aparecendo como erro genérico de autenticação. Keystore de debug
não é segredo: assina apenas desenvolvimento, não publica nada, e a senha `android` é
a convenção documentada do Android. O de **release nunca entra no repositório**.

Se rodar `flutterfire configure`, os arquivos vão aparecer na sua máquina — é
esperado, e eles não sobem. **Não force o commit deles.**

### As regras ficam versionadas

As Firestore Rules estão em [`firestore.rules`](firestore.rules), não só no console.
Coleção nova **nasce fechada** (`allow read, write: if false`) — para liberar, a
regra entra no arquivo e é revisada no PR, **com caso novo em
`firestore-testes/regras.test.js`**. Cada regra de "nega" de lá corresponde a um ataque
concreto; os da revisão de 01/10/2026 estão todos lá.

```bash
cd firestore-testes && npm install && npm test   # emulador; precisa de Java 21+
firebase deploy --only firestore:rules           # só depois do merge
```

As regras valem também para o site (semestre-4-nextjs): mudança que exija outro formato
de escrita precisa sair nos dois clientes **antes** de as regras novas serem publicadas.

### O que "segredo" quer dizer aqui

A `apiKey` do Firebase e a `anon key` do Supabase são **públicas por design**: vão
para o bundle web e para o APK de qualquer jeito, e APK é descompilável. Tirá-las
do código evita vazamento no repositório, mas **não protege dado nenhum**.

Quem protege são as **Firestore Rules** e o **RLS do Supabase**. Se você for mexer
em como o app lê ou escreve dados, a pergunta certa é *"a regra está fechada?"*,
não *"a chave está escondida?"*.

O que **nunca** pode chegar ao cliente, em `env.json` ou fora dele: `service_role`
do Supabase, service account do Firebase, qualquer token de API paga. Esses só
vivem em servidor.

---

## Antes de abrir PR

Rode os três, nesta ordem. É o mesmo que a CI roda — falhar aqui é falhar lá.

```bash
dart format lib test
flutter analyze     # tem que dar "No issues found!"
flutter test        # tem que passar inteiro
```

`lib test`, e não `.`: é o que a CI confere, e depois de um build Android o `.` entra
em `build/` e tropeça em caminho longo no Windows.

`flutter analyze` limpo não é meta, é piso. Não abra PR com warning novo.

---

## Como escrever código aqui

### Idioma
- **Código em português**: classes, métodos, variáveis, campos (`Bioma`, `carregar()`,
  `percentualDesmatado`).
- **Exceção**: o que vem de API externa mantém o nome de lá (`Timestamp`,
  `photoURL`, `uid`, as chaves do GeoJSON como `AREAHA` e `ANODETEC`).
- Comentários e documentação em português.

### Estrutura de pastas
```
lib/
├── config/     credenciais e configuração
├── data/       dados estáticos (catálogo, biomas, textos da Home)
├── models/     classes de domínio + parsers
├── services/   Firebase, Supabase, leitura de arquivo
├── screens/    uma tela por arquivo
├── widgets/    componentes reutilizáveis; charts/ para os gráficos
└── theme/      cores e breakpoints
```

Arquivo novo vai na pasta que corresponde ao papel dele. Se não couber em nenhuma,
provavelmente o papel está confuso — repense antes de criar pasta nova.

### Convenções que este código já segue

**Widget que não muda é `const`.** O analyzer cobra, e é o que evita rebuild à toa.

**Modelo é imutável.** `@immutable`, campos `final`, construtor `const` quando dá.

**Parser não estoura, devolve `null`.** Veja `AlertaDesmatamento.doGeoJson`: o
GeoJSON tem 15 MB e 40 mil features; uma malformada não pode derrubar o mapa
inteiro. Prefira pular o registro ruim a explodir a tela.

**Imagem de rede sempre tem `errorBuilder`.** As fotos vêm do Supabase e do
Wikimedia Commons e podem falhar (offline, bucket movido, arquivo renomeado). Cai num placeholder, nunca no ícone de erro cinza
do Flutter.

**Gráfico é `CustomPainter`, não biblioteca.** Foi decisão de projeto, herdada do
SVG escrito à mão da versão React. Se precisar de um gráfico novo, pinte no canvas
como os que já existem em `lib/widgets/charts/` (barras e o mapa dos biomas).

**Foto que sai do aparelho passa por `semMetadados`.** O `image_picker` copia o EXIF,
GPS incluído, para a foto reduzida. Avatar, identificação e qualquer upload novo de foto
chamam `semMetadados` (`lib/services/sem_metadados.dart`) antes de enviar; a política
de privacidade promete isso.

**Trabalho pesado sai da thread da UI.** O GeoJSON é parseado em `compute()`. Se
adicionar processamento caro, siga o mesmo caminho.

**Erro de rede vira mensagem em português.** Veja `AuthService.mensagemDeErro()`.
Nunca mostre o código cru do Firebase para quem usa o app.

### Responsividade
Use `Breakpoints.ehMobile(context)` (`app_theme.dart`), não `MediaQuery` solto.
Mobile = `NavigationBar`; desktop = `NavigationRail`. Grades calculam colunas a
partir da largura disponível, com `LayoutBuilder`.

---

## Testes

Teste novo em `test/`. Cubra pelo menos:

- **Cálculo** — os números da Home e a linha do tempo tirados do PRODES, formatação,
  agregação.
- **Parser** — o caminho feliz **e** o dado malformado. Todo parser deste repo tem
  teste de entrada inválida, e é assim que continua.
- **Integridade dos dados** — se você adicionar espécie ou bioma, os testes de
  "toda espécie tem status gerado", "foto de terceiros sempre tem autor, licença e
  link" e "anel fecha" já cobrem, mas confira se passam. Espécie nova precisa estar
  também no `especies.ts` do site, e foto de fora do Supabase precisa de `credito`.

Não precisa testar layout pixel a pixel. Teste comportamento: o widget dispara o
callback? A tela de erro lista o que falta?

As Edge Functions e o SQL dos limites por pessoa têm testes em Deno, também na CI (job
`Edge Function`): a corrida dos modelos, o envio da foto de perfil e o apagamento da conta
com `fetch` falso, a conferência do ID token com chaves geradas no teste, e o SQL num
Postgres em WebAssembly com os papéis do Supabase. Mexeu em `supabase/`, rode:

```bash
deno fmt --check supabase
deno check supabase/functions/identificar-animal/index.ts supabase/functions/enviar-avatar/index.ts \
  supabase/functions/apagar-conta/index.ts
deno test --allow-read --allow-env supabase
```

---

## Git

### Branches
A `main` **é protegida de verdade** — não é só convenção. O GitHub recusa push
direto e exige, antes do merge:

| Regra | Valor |
|---|---|
| Pull request obrigatório | sim |
| Aprovações necessárias | **1** |
| Review antiga é descartada ao subir commit novo | sim |
| Checks que precisam passar | `Análise e testes`, `Build APK` |
| Conversas do review resolvidas | sim |
| Force push e deleção da branch | bloqueados |

> **Uma saída de emergência, e ela é consciente:** a proteção **não se aplica a
> administradores da organização**. É o que permite corrigir a `main` quando algo
> quebra e não há ninguém acordado para aprovar. Use isso como exceção — se virar
> hábito, o processo acima deixa de existir na prática.

Não exigimos que a branch esteja atualizada com a `main` antes do merge: num grupo
de cinco isso obrigaria a um rebase a cada merge alheio, e o custo não compensa.

Trabalhe em branch e abra PR.

```
feat/nome-curto      funcionalidade nova
fix/nome-curto       correção
docs/nome-curto      documentação
```

### Commits
Mensagem em português, imperativo, explicando **o porquê** quando não for óbvio.

```
Adicionar filtro por região no catálogo

O filtro por bioma não bastava: três espécies do Sudeste ficavam
espalhadas entre Mata Atlântica e Cerrado, e quem busca por região
não encontrava.
```

Um commit por ideia. Não misture correção de bug com refatoração.

### Pull requests
- Descreva o que muda e por quê.
- A CI precisa passar (análise, testes e APK).
- O APK de cada PR fica como artefato da CI: dá para instalar e testar antes de aprovar.
- Peça revisão de pelo menos uma pessoa do grupo.

---

## CI e deploy

Tudo automático, em `.github/workflows/`:

| Quando | O que acontece |
|---|---|
| Push ou PR | `dart format`, `flutter analyze`, `flutter test`, build do APK e testes das regras do Firestore |
| Tag `v*.*.*` | `flutter test`, APK de release assinado e release com o APK e as notas dos PRs |

**Para lançar uma versão, siga o [RELEASES.md](RELEASES.md).** Em resumo: num PR, suba
`version` no `pubspec.yaml` (`1.1.0+2`: o número depois do `+` tem que crescer, senão o Android
recusa a atualização); depois do merge, crie a tag `v1.1.0` na `main` pelo `git`, não pelo botão
do GitHub. Tag com hífen (`v1.1.0-rc.1`) é ensaio e vira rascunho. O app não se atualiza sozinho,
e os dados copiados do site vão dentro do APK: para chegarem a quem usa, precisam de uma release.
A chave de assinatura fica no ambiente `release` do GitHub, e ninguém precisa dela para lançar.

O APK debug fica anexado à execução da CI por 14 dias — dá para baixar e instalar
no celular sem ter Flutter montado.

**Este repositório não publica nada no Firebase Hosting** desde 01/10/2026: o endereço
principal é do site em Next.js, e um `firebase deploy` daqui o derrubaria. Por isso o
`firebase.json` não tem mais a seção `hosting`. O único deploy que sai daqui é o das
regras: `firebase deploy --only firestore:rules`.

---

## Para assistentes de IA

Tudo acima vale. Além disso:

- **Não invente dado ambiental.** Os números deste repo vêm do PRODES, do MMA e da
  IUCN, copiados do site (README, "Sobre os dados"). Se precisar de número novo, peça
  a fonte — não preencha com estimativa plausível. `prodes_data.dart`,
  `especies_data.dart`, `denuncia_data.dart` e `assets/data/alertas-desmatamento.json`
  não se editam à mão: copie do site. `legal_data.dart` (privacidade e termos) sai de
  `node tool/legal/copiar.mjs <pasta do semestre-4-nextjs>`. Mudou o que o app guarda ou
  envia? O texto muda no `src/dados/legal.ts` do site, no mesmo par de PRs.
- **Não crie `firebase_options.dart` com chaves dentro**, nem sugira `flutterfire
  configure` sem avisar que o arquivo é ignorado de propósito.
- **Não suba nada** (`git push`, `firebase deploy`) sem pedido explícito. Isso inclui tag: uma
  tag `v*.*.*` na `main` publica uma versão do app.
- **Rode `flutter analyze` e `flutter test`** antes de dizer que terminou, e relate
  o resultado real — inclusive quando falha.
- **Build passar não prova que credencial chegou.** Variável ausente vira `undefined`
  e compila liso. Para provar, tire o `env.json`, rebuilde, e confirme que o valor
  sumiu do bundle. Foi assim que a versão React falhava calada.
- Se uma suspeita sua não se confirmar no código, diga isso em vez de manter o
  achado mais vistoso. Achado falso contamina a confiança nos verdadeiros.

---

## Pendências conhecidas

- 🟢 **Chave Android restrita** por package + SHA-1 de debug e de release (feito em
  08/09). Se algum dia o keystore de release for regerado, **o SHA-1 novo precisa
  entrar na chave** ou o login para de funcionar no APK assinado.
- 🟢 **`firestore.rules` publicadas** (08/09) e versionadas. O arquivo é a fonte:
  mudou regra, muda o arquivo e sai no PR. Para publicar:
  `firebase deploy --only firestore:rules`.
- 🟢 **E-mail do usuário fora do Firestore** (09/09). `usuarios/{uid}` não guarda mais
  `email`, e a leitura passou a ser só do dono. A premissa que sustentava a alternativa
  cara — "a avaliação precisa de nome e foto daqui" — era falsa: **nada no app lê essa
  coleção**; `ReviewsService.publicar` copia `displayName` e `photoURL` do Auth. **Falta
  limpar os documentos antigos**, que ainda têm o e-mail gravado; parar de escrever não
  apaga o que já está lá.
- 🟡 **GeoJSON do DETER de 15 MB embarcado** nos assets (02/11/2026): cerca de 2 MB
  compactado no APK e 40 mil alertas no mapa, o dobro do arquivo antigo. O mapa funcionou
  num celular de verdade em 04/11/2026. Se pesar, as saídas são ler o arquivo do próprio site
  (sempre atual, sem copiar) ou simplificar mais os polígonos.
- 🟡 **Dados copiados do site** (28/10/2026; alertas e denúncia em 02/11/2026).
  Desmatamento (PRODES), status das espécies (MMA, IUCN), alertas (DETER) e canais de
  denúncia têm fonte, mas `prodes_data.dart`, `especies_data.dart`, `denuncia_data.dart`
  e o arquivo dos alertas são cópia do que o site gera e não se atualizam sozinhos. O
  PR do site de 29/10 (DETER, denúncia) ficou sem gêmeo aqui até 02/11. Falta um jeito de copiar
  automaticamente, ou de o app ler o mesmo arquivo do site. A política e os termos já são
  gerados por script (`tool/legal/copiar.mjs`).
- 🟢 **Todas as fotos das espécies são do Wikimedia Commons, com `credito`** (10/11/2026).
  Até aqui, sete vinham do bucket `animals` sem origem registrada; pelo nome dos arquivos,
  eram cópia das imagens de terceiros que o React usava (Biologia Net, Toda Matéria, Brasil
  Escola, Agência Brasil). A abertura da Home e a faixa do mico saem do catálogo e mostram o
  crédito sobre a foto (`CreditoDaFoto`). Os arquivos antigos saem do bucket depois que uma
  versão nova do app estiver publicada: as versões anteriores ainda os pedem.
- 🟡 **Identificação por foto e idade.** Os termos do Gemini proíbem a API em serviço
  provável de ser acessado por menores de 18. A tela Fotos e os termos avisam; não há
  trava.
- 🟡 **Identificação por foto** (aba Fotos, 01/10/2026). O app chama a Edge Function
  `supabase/functions/identificar-animal`, que confere o ID token do Firebase e consulta
  o **Gemini** pelo nível gratuito do Google AI Studio. A chave é **secret do Supabase**
  (`GEMINI_API_KEY`), nunca vai para o `env.json`. `GEMINI_MODEL` e
  `GEMINI_MODEL_RESERVA` trocam o modelo sem republicar; o padrão é apelido, porque
  versão fixa envelhece — o `gemini-2.5-flash` já dava 404 em 01/10/2026. O principal é o
  `gemini-flash-lite-latest` (1,8 s no teste de 02/10/2026) e o reserva, o
  `gemini-flash-latest`. A demora do nível gratuito é **fila**, não modelo (o mesmo lite
  levou 1,8 s e 20 s em testes seguidos): se o principal não responde em 6 s, o reserva é
  chamado junto e vale a primeira resposta boa — nos casos lentos, a foto gasta duas
  consultas da cota. Teto de 50 s por chamada; a resposta traz `_diagnostico` com o tempo
  de cada chamada ao Gemini.
  Começou com o Cloud Vision, abandonado porque exige faturamento, e o faturamento do
  Google Cloud no Brasil pedia CNPJ. Dois cuidados do nível gratuito: o
  Google pode usar as fotos enviadas (a tela avisa) e a cota é por minuto e por dia —
  como o cadastro é aberto, qualquer conta nova consegue gastá-la.
  **Limite por pessoa desde 28/10/2026:** 5 identificações por minuto e 30 por dia
  (`LIMITE_POR_MINUTO` e `LIMITE_POR_DIA` mudam sem republicar), contadas pelo uid em
  `supabase/limite-identificacao.sql`. Só pedido aceito conta. Pedido acima do limite
  volta 429 com `limite-minuto` ou `limite-dia`, e o app e o site mostram mensagens
  diferentes da cota do Gemini (`cota`). Sem a tabela, a função recusa tudo com 503:
  **o SQL entra antes da função nova**. Limite que fica: muitas contas novas ainda
  somam, porque o cadastro continua aberto.
- 🟢 **Foto de perfil pela Edge Function `enviar-avatar`** (10/11/2026, publicada e
  fechada no mesmo dia). O bucket `avatars` aceitava envio direto de qualquer pessoa, até
  sem login, sem limite de quantidade. Agora a foto passa pela função, que confere o ID token
  do Firebase, o tipo pelos bytes, 1 MB e 5 fotos por pessoa por dia
  (`LIMITE_AVATAR_POR_DIA` muda sem republicar), contadas em `supabase/limite-avatar.sql`.
  `supabase/avatars-so-pela-funcao.sql` já foi aplicado: o bucket não tem política de envio,
  e o APK 1.0.0 cadastra sem foto. Mudou `supabase/functions/enviar-avatar/`? Publique de
  novo à mão: `supabase functions deploy enviar-avatar --no-verify-jwt`.
- 🟢 **Botão de apagar conta** (11/11/2026), no menu da conta do app e do site, com a senha de
  novo. Apaga a foto de perfil e as linhas de limite pela função `apagar-conta` (que exige
  login de até 5 minutos), as avaliações, o perfil e, por último, a conta no Auth; se uma etapa
  falha, as seguintes não rodam. Até aqui só a equipe apagava, por pedido numa issue. Para
  publicar: a função e as regras (`usuarios/{uid}` passou a aceitar `delete` do dono) **antes**
  do site e da versão do app com o botão. Apagar só a avaliação ou só a foto ainda é pela equipe.
- 🟢 **O app já foi executado** (09/09/2026), no navegador e no emulador Android, sem
  exceção nas telas. Em 04/11/2026, o login e o mapa funcionaram num celular de verdade.
