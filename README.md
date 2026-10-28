<p align="center">
  <img src=".github/arte/banner.svg" alt="EcoMapBrasil — os alertas de desmatamento do DETER-B desenhados como mapa, ao lado do título" width="100%">
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white">
  <img alt="Android" src="https://img.shields.io/badge/plataforma-Android-3ddc84?logo=android&logoColor=white">
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Auth_%C2%B7_Firestore-ffca28?logo=firebase&logoColor=black">
  <img alt="Supabase" src="https://img.shields.io/badge/Supabase-Storage-3ecf8e?logo=supabase&logoColor=white">
  <img alt="Licença MIT" src="https://img.shields.io/badge/licen%C3%A7a-MIT-5b6270">
</p>

O **EcoMapBrasil** reúne num lugar só o que costuma estar espalhado em relatório e
planilha: **onde** o desmatamento acontece, **quais espécies** estão ameaçadas e o que dá
para fazer a respeito. É o Projeto Interdisciplinar de um grupo de cinco da FATEC, e
este repositório é **o app Android**, em Flutter.

O projeto tem duas faces sobre o mesmo backend: o **app**, daqui, e o **site**, que volta
a ser React, agora em Next.js, no
[semestre-4-nextjs](https://github.com/ecomap-devs/semestre-4-nextjs). Uma avaliação feita no celular
aparece no site, e vice-versa.

<p align="center">
  <img src=".github/arte/numeros.svg" alt="O EcoMapBrasil em números: alertas no mapa, hectares em alerta, anos de detecção, biomas, espécies no catálogo e testes" width="100%">
</p>

## 📱 O app

| Tela | O que tem |
|---|---|
| 🏠 **Início** | Abertura em tela cheia com fotos que se alternam, números do desmatamento, **mapa dos biomas** em que dá para tocar, espécies em destaque, gráfico de barras desenhado no canvas, linha do tempo de duas décadas, soluções práticas e as avaliações da comunidade |
| 🗺️ **Mapa** | Os **6 biomas** pelo limite do IBGE e a camada de **alertas do DETER-B**, sobre mapa claro ou satélite. Painel com a lista de biomas e a linha do tempo (aba própria no celular), legenda dos alertas, e a ficha do bioma ao tocar: área, percentual desmatado e descrição |
| 🐆 **Animais** | Catálogo de **45 espécies** dos seis biomas, 27 delas na lista nacional de fauna ameaçada, com busca que ignora acento, filtros por bioma e status (inclusive "Só ameaçadas"), o status no Brasil (MMA) e no mundo (IUCN), a população onde há estimativa publicada (com a fonte) e as principais ameaças |
| 📷 **Fotos** | **Identificação de animal por foto**: tire uma foto ou escolha da galeria, e o Gemini diz qual é o animal, com o nome científico e o grau de confiança. Exige login |
| 👤 **Conta** | Cadastro e login por e-mail e senha, foto de perfil e **avaliações em estrelas**, salvas e lidas em tempo real |

O layout se adapta à largura: `NavigationBar` no celular, `NavigationRail` em tela
larga (tablet), e grades que recalculam as colunas conforme o espaço.

## 🧭 Onde este repositório entra

```mermaid
flowchart LR
    subgraph faces[Duas faces, um backend]
        direction TB
        web["🌐 Site · Next.js + TypeScript<br/>semestre-4-nextjs · no endereço principal"]
        app["📱 App Android · Flutter<br/>este repositório"]
    end
    subgraph backend[Backend]
        direction TB
        auth[🔐 Firebase Auth]
        fs[(🗄️ Firestore)]
        sb[(🖼️ Supabase Storage)]
        fn["⚡ Edge Function<br/>identificar-animal"]
    end
    web --> auth & fs & sb & fn
    app --> auth & fs & sb & fn
    fn --> gemini["✨ Gemini"]
    regras["📜 firestore.rules<br/>versionadas aqui"] -. protege .-> fs
```

**Decidido em 30/09/2026:** o site volta a ser React, em **Next.js com TypeScript**,
hospedado no **Firebase Hosting** como site estático, e fica com o endereço principal
(`ecomapbrasil-17756.web.app`), porque para site é a tecnologia mais adequada. O
Flutter fica com o que faz melhor: **o app Android**.

> [!NOTE]
> **A troca foi feita em 01/10/2026.** O endereço principal serve o site em Next.js, e
> este repositório não publica mais nada no Hosting: saíram o deploy, o preview por PR,
> o build web da CI e o check `Build web` da proteção da `main`. O código web do Flutter
> continua compilando (`flutter run -d chrome` serve para testar), só não é publicado.

**As regras do Firestore moram aqui e valem para os dois.** O banco é um só, então as
regras são uma só: duas cópias, uma em cada repositório, acabariam divergindo. Pelo
mesmo motivo a Edge Function da identificação por foto, que o site também chama, mora
aqui, em [`supabase/functions/identificar-animal`](supabase/functions/identificar-animal).

## 🛠️ Stack

| Camada | Escolha | Por quê |
|---|---|---|
| **App** | Flutter 3.47 · Dart 3.13 · Material 3 | Um código para Android, com o mesmo visual do site |
| **Fontes** | Fraunces e Source Sans 3, em `assets/fonts/` | As do site; licença OFL, junto dos arquivos |
| **Mapa** | `flutter_map` + `latlong2` | O irmão do Leaflet usado no site, com os mesmos tiles (claro e satélite) |
| **Gráficos** | `CustomPainter` puro | Sem biblioteca de gráficos, como o SVG escrito à mão do original |
| **Conta e dados** | `firebase_auth` · `cloud_firestore` | Login por e-mail e senha e avaliações em tempo real |
| **Imagens** | `supabase_flutter` | Fotos das espécies e dos avatares |
| **Identificação por foto** | `image_picker` + Edge Function do Supabase + Gemini | A chave do Gemini fica no servidor, nunca no APK |

## 🚀 Como rodar

> Pré-requisitos: Flutter 3.47+ e o Android SDK (emulador ou celular com depuração USB).

```bash
git clone https://github.com/ecomap-devs/semestre-4-flutter.git
cd semestre-4-flutter
flutter pub get

cp env.example.json env.json      # e preencha os valores
flutter run --dart-define-from-file=env.json
```

> [!IMPORTANT]
> O `--dart-define-from-file` **não é opcional**. Sem ele o app abre numa tela listando
> exatamente quais variáveis faltam, em vez de subir e quebrar lá na frente, no login.

<details>
<summary>Build, testes e o que rodar antes de abrir PR</summary>

```bash
flutter build apk --release --dart-define-from-file=env.json

dart format lib test     # o mesmo que a CI confere
flutter analyze          # tem que dar "No issues found!"
flutter test             # tem que passar inteiro
```

Use `dart format lib test`, e não `dart format .`: depois de um build Android, o `.`
entra em `build/` e tropeça em caminho longo no Windows.

</details>

## 🔑 Credenciais e segurança

O `env.json` fica fora do git, e o `env.example.json` mostra os nomes das variáveis.
Também ficam de fora, de propósito, os arquivos que as ferramentas geram **com as
chaves dentro**:

```
lib/firebase_options.dart              # o flutterfire configure gera com as chaves
android/app/google-services.json       # idem
android/key.properties                 # senha do keystore de release
android/keystore/release.jks           # o keystore de release
```

> [!WARNING]
> **Chave pública de cliente não é segredo.** A `apiKey` do Firebase e a *publishable
> key* do Supabase vão dentro do APK de qualquer jeito, e APK se descompila. Quem protege
> o dado são as **Firestore Rules** e o **RLS do Supabase**.

<details>
<summary>Uma chave do Firebase por plataforma, e os keystores</summary>

A restrição de aplicativo do Google Cloud é **exclusiva**: uma chave travada por
referenciador HTTP recusa requisição sem `Referer`, que é o caso de todo app nativo. Por
isso web e Android têm chaves diferentes.

| Variável | Restrição |
|---|---|
| `FIREBASE_API_KEY_WEB` | Referenciador HTTP (`*.web.app`, `*.firebaseapp.com`, `localhost`) + 4 APIs |
| `FIREBASE_API_KEY_ANDROID` | Package + SHA-1 dos certificados de debug **e** de release + 4 APIs |

`Env` escolhe a chave pela plataforma, e o ramo que não vale é eliminado no build.

- **Keystore de debug** compartilhado e versionado em `android/keystore/debug.jks`, para
  que os cinco assinem com o mesmo certificado e o SHA-1 cadastrado sirva para todos.
- **Keystore de release** fora do repositório. Perdê-lo significa nunca mais atualizar um
  app já instalado; e se ele for regerado, **o SHA-1 novo precisa entrar na chave
  Android**, ou o login para de funcionar no APK assinado.
- **Release sem `android/key.properties` falha de propósito.** Até 01/10/2026 ele caía
  no keystore de debug, que é público: qualquer pessoa conseguiria assinar um APK com a
  mesma identidade. Para testar sem a chave, use o build de debug.

As `anon` keys do Supabase foram **desativadas** em 08/09/2026, e o projeto usa a
`sb_publishable_...`.

A chave do **Gemini** não está no `env.json` e nunca vai para o APK: é secret do
Supabase (`GEMINI_API_KEY`), lida só pela Edge Function `identificar-animal`, que
também confere o ID token do Firebase de quem chama. Os secrets que ela usa estão no
cabeçalho de [`index.ts`](supabase/functions/identificar-animal/index.ts).

</details>

<details>
<summary>As regras do Firestore</summary>

Versionadas em [`firestore.rules`](firestore.rules), testadas no emulador em
[`firestore-testes/`](firestore-testes) e publicadas com
`firebase deploy --only firestore:rules`. Mudou como o app (ou o site) lê ou grava um
dado? A regra muda no mesmo PR, com um caso novo nos testes.

- `avaliacoes`: leitura pública. **Uma por pessoa:** a nova tem id = uid de quem avalia.
  Criação e edição seguem o mesmo esquema (nota inteira de 1 a 5, comentário de 1 a
  2.000 caracteres, nome de 1 a 200, sem campos extras), com a hora do servidor. A
  `photoURL` só pode ser vazia ou do bucket de avatares.
- `usuarios/{uid}`: só o dono lê e escreve, com esquema. **O e-mail não é gravado ali**
  desde 09/09/2026: ele já vive no Firebase Auth, e nada no app lê essa coleção.
- Qualquer outra coleção nasce fechada.

```bash
cd firestore-testes && npm install && npm test   # precisa de Java 21+
```

As políticas do bucket `avatars` do Supabase estão em [`supabase/avatars.sql`](supabase/avatars.sql).

</details>

## 🔄 CI e deploy

Tudo automático, em [`.github/workflows/`](.github/workflows/):

| Quando | O que roda |
|---|---|
| **Push ou PR** | `dart format` · `flutter analyze` · `flutter test` · build APK · testes das regras do Firestore no emulador |

O **APK debug** fica anexado à execução da CI por 14 dias: dá para baixar e instalar no
celular sem ter Flutter montado. Os secrets viram `env.json` dentro da CI e **nunca**
entram no repositório.

A `main` é protegida: PR obrigatório, **1 aprovação** e os checks `Análise e testes` e
`Build APK` passando.

## 📁 Estrutura

<details>
<summary>As pastas de <code>lib/</code> e <code>assets/</code></summary>

```
lib/
├── config/env.dart            credenciais via --dart-define, com checagem
├── data/                      dados estáticos, os mesmos do site
│   ├── animais_data.dart        catálogo de espécies
│   ├── especies_data.dart       status no MMA e na IUCN (cópia do site)
│   ├── prodes_data.dart         desmatamento do PRODES por bioma (cópia do site)
│   ├── biomas_data.dart         os 6 biomas: área e percentual do PRODES
│   ├── biomas_contornos.dart    limite do IBGE (gerado por tool/biomas/gerar.mjs)
│   ├── linha_do_tempo.dart      marcos calculados do PRODES
│   └── home_data.dart           os números, os destaques e as soluções
├── models/                    Animal · Bioma · AlertaDesmatamento · Avaliacao · Identificacao
├── services/                  Firebase · avaliações · leitura do GeoJSON · identificação por foto
├── screens/                   app_shell · home · mapa · animais · fotos
├── theme/app_theme.dart       paleta, fontes e breakpoints, iguais aos do site
└── widgets/
    ├── charts/                  barras · mapa dos biomas
    ├── abertura.dart            a abertura da Home, com as fotos que se alternam
    ├── animacao_na_tela.dart    revela ao entrar na tela, sem timer
    ├── imagem_com_reserva.dart  foto de rede que cai num placeholder se falhar
    └── auth_modal.dart · reviews_section.dart · estrelas.dart · …

assets/
├── data/alertas-desmatamento.json   GeoJSON do DETER-B/INPE
├── fonts/                           Fraunces e Source Sans 3, com as licenças OFL
└── img/logo.png
```

</details>

## 📊 Sobre os dados

A camada de alertas usa dados públicos de detecção do **DETER-B (INPE)**: bioma, estado,
município, área em hectares e data de cada polígono. O arquivo tem 6,7 MB, mas ocupa
1,48 MB dentro do APK, que é compactado.

Os contornos dos biomas são o limite oficial do **IBGE** ("Biomas do Brasil",
1:5.000.000), simplificados para o mapa por [`tool/biomas/gerar.mjs`](tool/biomas/gerar.mjs),
que diz como refazê-los. O site usa a mesma receita.

Desde 28/10/2026 os demais números são os mesmos do site, com a mesma fonte:

| No app | De onde vem |
|---|---|
| Percentual desmatado e área de cada bioma | **PRODES (INPE)**: tudo o que já foi mapeado como desmatado ÷ área do bioma no IBGE (2019) |
| Números da Home, "Área desmatada por bioma" e "Desmatado no último ano medido" | PRODES, por bioma, no período mais recente que os seis já têm consolidado |
| Linha do tempo (Home e mapa) | Calculada em `lib/data/linha_do_tempo.dart` da taxa oficial da Amazônia Legal e do acumulado por bioma. Só PPCDAm, Moratória da Soja e Código Florestal são escritos à mão, sem número |
| Status das espécies e "1.259 espécies ameaçadas" | Lista nacional do **MMA** (avaliação de 2021); fora dela, "Não ameaçada". No mundo, a Lista Vermelha da **IUCN**, pelo GBIF |
| População de uma espécie | Só onde há estimativa publicada, com a fonte na ficha |
| Fotos das espécies | As sete primeiras, no bucket `animals` do Supabase. As outras, do **Wikimedia Commons**, com autor, licença e link na ficha (`credito` em `animais_data.dart`), como as licenças Creative Commons exigem |

`prodes_data.dart` e `especies_data.dart` são **cópia** do `prodes.ts` e do `especies.ts`
que o site gera (os workflows de lá abrem PR todo mês quando o INPE ou o MMA publicam dado
novo). Quando o site atualizar, copie de novo e rode os testes: `test/dados_test.dart`
fixa os números que o site mostra, então a diferença aparece lá. Até 28/10/2026 eram
valores de referência herdados do React, e alguns muito longe do real: a Amazônia
aparecia 78% desmatada (o PRODES mede 20%) e cada espécie tinha uma série de população
inventada.

## 🤝 Contribuindo

As regras do repositório estão no **[AGENTS.md](AGENTS.md)**: convenções de código,
padrão de commit, o que roda na CI e o que nunca pode ser commitado. Valem para os cinco
do grupo e para qualquer assistente de IA.

Em resumo: branch a partir da `main` (`feat/`, `fix/`, `docs/`), formato, análise e
testes verdes, e a revisão de alguém do grupo para mergear.

## 🎨 As artes deste README

O banner e os números são gerados do próprio repositório, sem dependência nenhuma:

```bash
node .github/arte/gerar.mjs
```

O banner desenha os 18 mil alertas do GeoJSON no lugar onde cada um foi detectado, e o
cartão conta espécies, biomas e testes **nos arquivos**, sem número digitado à mão. O
gerador é determinístico: com o repositório igual, as artes saem byte a byte iguais, e
as animações respeitam `prefers-reduced-motion`.

## 👥 Equipe

**Vinicius** · **Bruno** · **Cesar** · **João Flávio** · **João Gabriel**

A versão React do semestre anterior está em
[JoaoAlane/EcoMapBrasil](https://github.com/JoaoAlane/EcoMapBrasil).

## 📄 Licença

[MIT](LICENSE). Projeto acadêmico, sem fins lucrativos.
