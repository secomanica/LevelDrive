# Patches no código upstream

Patches aplicados por `level-theme/tools/apply-theme.ps1`, em ordem numérica, com `git apply`.
Só existe patch quando o mesmo resultado não se obtém pelo `NEXTCLOUD.cmake` nem pelo overlay.
Base: tag `v35.0.3`.

Para gerar ou atualizar um patch:
1. edite o arquivo upstream;
2. rode `git diff -- <arquivo> > level-theme\patches\NNNN-descricao.patch`;
3. restaure o original com `git checkout -- <arquivo>`;
4. teste com `apply-theme.ps1 -Check`.

## 0001-cmake-overridable-cfapi-guids-and-uri-scheme.patch
- **Arquivo:** `CMakeLists.txt`, linhas 38-50 na v35.0.3.
- **Problema:**
  - O AppID e os 2 CLSIDs das extensões CfApi do Explorer (estado e miniatura) são definidos com `set()` fixo no CMakeLists raiz, fora do `NEXTCLOUD.cmake`. O esquema de URI `nc` também.
  - Com os mesmos GUIDs, o Level Drive e o Nextcloud oficial na mesma máquina sobrescrevem o registro COM um do outro. A desinstalação de um apaga o do outro (`admin/win/msi/RegistryCleanup.vbs.in:55-79`).
  - Com o mesmo esquema, o MSI de um sobrescreve e, ao desinstalar, apaga `HKLM\Software\Classes\nc` (`admin/win/msi/Nextcloud.wxs:192-203`).
- **Mudança:** cada `set()` fica dentro de `if(NOT DEFINED ...)`. O padrão continua igual ao upstream, e os valores da Level são definidos em `level-theme/NEXTCLOUD.cmake`.
- **Risco:** nulo para builds sem tema.
- **Candidato a upstream:** sim.

## 0002-navigationpane-keep-official-nextcloud-entries.patch
- **Arquivo:** `src/gui/navigationpanehelper.cpp`, linha 71 na v35.0.3.
- **Problema:**
  - A cada inicialização, o cliente apaga as entradas do painel de navegação do Explorer cujo `ApplicationName` seja o nome do próprio app **ou "Nextcloud"** (`unbrandedApplicationName`, `navigationpanehelper.h:34`).
  - Num build com marca, isso remove as pastas do Nextcloud oficial do painel de navegação.
- **Mudança:** remove só as entradas com o nome do próprio app.
- **Efeito colateral:** a constante `unbrandedApplicationName` fica sem uso. Ela foi mantida para o patch continuar mínimo.
- **Risco:** a regra original servia a quem migrava de um Nextcloud sem marca para um build com marca. Não se aplica à Level.

## 0003-tray-icon-follows-taskbar-theme.patch
- **Arquivo:** `src/libsync/theme.cpp`, `Theme::systrayIconFlavor()`, linhas 580-589 na v35.0.3.
- **Problema:**
  - No Windows, a bandeja usa por padrão um único conjunto `colored/` para os dois temas.
  - A camada superior do símbolo `-cor` (#173439) some na barra de tarefas escura.
  - A marca proíbe recolorir. A solução é usar `-cor` na barra clara e `-cor-negativo` na escura (opção A, aprovada em 2026-11-11).
- **Mudança:**
  - No Windows, a bandeja escolhe sempre `white/` (barra escura) ou `black/` (barra clara) por `Utility::hasDarkSystray()`, a mesma regra que o upstream já aplica no modo monocromático.
  - Os conjuntos `white/` e `black/` da Level são gerados por `build-icons.ps1`, com o símbolo colorido correto para cada fundo.
- **Efeitos colaterais:**
  - A opção "ícones monocromáticos" das configurações passa a não ter efeito no Windows. Avaliar escondê-la na Fase 4/5.
  - A troca de tema da barra com o app aberto só aparece na próxima atualização de status da bandeja, porque o cache de ícones usa a variante como chave.
- **Risco:** baixo. Afeta só o Windows. Outros sistemas mantêm o código original (`#else`).

> **0003, atualização da Fase 5:** `Theme::monoIconsAvailable()` devolve `false` no Windows. A interface já esconde a opção "Usar ícones monocromáticos" nesse caso (`generalsettings.cpp:72-76`), então a opção sem efeito some.

## 0004-style-qml-level-design-tokens.patch
- **Arquivo:** `theme/Style/Style.qml`, singleton de estilo de toda a interface QML.
- **Problema:** a paleta do assistente e dos diálogos está fixa no código, em azuis e cinzas do Nextcloud (`#2b659a`, `#0076b5`, InfoBox `rgba(0,.51,.79)`, gradiente roxo do "Nextcloud Assistant").
- **Mudança:**
  - Acrescenta os tokens da Level (`levelSurface`, `levelInk`, `levelInkMuted`, `levelInkHeading`, `levelAccent`, `levelOnAccent`, `levelFocus`…) e remapeia as propriedades `wizard*`, `infoBox*`, `assistantSelection*`, `listItemHoverBackground`.
  - `ncBlue` (foco/seleção) passa a ser `#103B40` no tema claro e `#83C8B4` no escuro.
  - O texto sobre seleção (`wizardSelectedText`) passa a ser branco no claro e `#103B40` no escuro.
  - Nova propriedade `wizardPrimaryButtonText` (`#103B40`) para o texto sobre o verde.
  - `levelSerifFamily` usa Century Schoolbook se estiver instalada; senão, Georgia.
- **Contraste:** todos os pares conferidos por `tools/check-contrast.py`, com 44/44 ≥ 4,5:1 (texto) ou ≥ 3:1 (bordas e foco).
- **Armadilha:** o `Style.qml` upstream tem finais de linha **mistos** (CRLF e LF no índice). Editar com uma ferramenta que normaliza EOL gera um diff do arquivo inteiro. Edite preservando o EOL de cada linha.
- **Não muda:**
  - `accentColor` e `currentUserHeader*` continuam vindo do **theming do servidor** (app Theming do Nextcloud). Recomendação: configurar a cor primária `#103B40` nos servidores da Level.
  - `ErrorBox` continua vermelho (semântico).

## 0005-qml-primary-text-on-accent-and-serif-welcome.patch
- **Arquivos:**
  - `src/gui/wizard/qml/WizardButton.qml`
  - `src/gui/assistant/qml/AssistantMessageDelegate.qml`
  - `src/gui/search/UnifiedSearchFilterBar.qml`
  - `src/gui/wizard/qml/ServerPage.qml`
- **Problema:** no upstream, o texto sobre o botão primário reutiliza `wizardSelectedText` (branco). Branco sobre o verde `#53AE93` dá 2,7:1, o que é proibido pela marca e pela WCAG.
- **Mudança:**
  - Texto e ícones sobre o fundo primário (botão primário do assistente, balão de mensagem do usuário no assistente, chips de filtro ativos da busca) passam a usar `Style.wizardPrimaryButtonText` (`#103B40`, 4,56:1).
  - O título de boas-vindas "Log in to %1" usa a serifa da marca (`Style.levelSerifFamily`) com a cor de título (`levelInkHeading`).
- **Risco:** baixo. São trocas de propriedade de cor ou fonte, sem lógica.

## 0006-brand-font-links-and-dark-palette.patch
- **Arquivos:** `src/gui/main.cpp`, `src/libsync/theme.cpp`.
- **Mudanças:**
  - `main.cpp`: a fonte da aplicação usa `setFamilies({"Aptos", "Segoe UI", "Arial"})`, pelo nome de família do sistema, **sem empacotar arquivos de fonte** (Aptos e Century Schoolbook são proprietárias da Microsoft). Vale para Widgets e QML.
  - `theme.cpp` `getBackgroundAwareLinkColor()`: links em `#103B40` sobre fundo claro e `#53AE93` sobre fundo escuro, no lugar do azul do sistema e de `#6193dc`.
  - `theme.cpp` `reserveDarkPalette` (paleta escura própria usada no Windows 10):
    - Highlight `#83C8B4` com texto `#103B40`;
    - Link e Accent `#53AE93`;
    - **correção de um defeito do upstream:** o PlaceholderText `(44,44,44)` sobre Base `(42,42,42)` era invisível e passa a `#B6B6B6`.
- **Não muda (decisão):** a paleta global do Windows 11. Caixas de seleção e realces nativos da janela de configurações seguem a cor de destaque escolhida pelo usuário no Windows. Sobrescrever isso exigiria reaplicar a paleta a cada troca de tema. Fica como melhoria opcional.
- **Risco:** baixo.

## 0007-about-and-legal-credits.patch
- **Arquivos:** `config.h.in`, `src/libsync/theme.cpp`, `src/gui/legalnotice.cpp`.
- **Mudanças:**
  - `config.h.in`: nova macro `APPLICATION_SOURCE_URL`, definida em `level-theme/NEXTCLOUD.cmake` (<<PREENCHER>>; vazio = sem link).
  - `theme.cpp`:
    - nova função `levelCreditString()` com "Based on the Nextcloud Desktop Client, licensed under GPLv2." e, se houver URL, "Source code: <url>". Ela entra em `about()` (painel Sobre) e em `aboutDetails()` (aviso legal);
    - `gitSHA1()` aponta para o fork em vez de github.com/nextcloud. Sem URL configurada, mostra a revisão sem link.
  - `legalnotice.cpp`: acrescenta "%1 customizations: Copyright 2026 %2" (Level Drive / Level Tecnologia) **sem remover** os avisos de copyright do Nextcloud e do ownCloud.
- **Por quê:** é exigência legal (GPL e crédito ao upstream) e pedido do briefing.

## 0008-user-visible-strings.patch
- **Arquivos:**
  - `AssistantMessageList.qml`, `ocsassistantconnector.cpp` ("Nextcloud Assistant");
  - `urischemehandler.cpp` (mensagem com `nc://`);
  - `application.cpp` (`--help`, nome do log);
  - `cmd/cmd.cpp` (`--help`);
  - `logger.cpp`, `logbrowser.cpp`, `owncloudgui.cpp` (nome do arquivo de log);
  - `advancedsettings.cpp` (zip temporário), `advancedsettings.ui` (link notify_push).
- **Mudanças:**
  - Textos sem "Nextcloud".
  - O nome do log e do zip deriva de `APPLICATION_EXECUTABLE` (`leveldrive.log`).
  - A mensagem de URI usa `APPLICATION_URI_HANDLER_SCHEME`.
  - `#include "config.h"` explícito onde as macros passaram a ser usadas.
- **Traduções:** os textos-fonte alterados perdem a tradução antiga. O pt-BR é refeito no patch 0010.

## 0009-shell-extension-version-info.patch (patch BINÁRIO)
- **Arquivos:** `NCContextMenu.rc`, `NCOverlay.rc`, `NCUtil.rc` (UTF-16LE, marcados `-text` no upstream) e `CfApiShellIntegration.rc`.
- **Mudança:** CompanyName "Level Tecnologia"; FileDescription e ProductName "Level Drive shell extension". **LegalCopyright mantido** ("Nextcloud GmbH" é o autor do código).
- **Armadilha:**
  - Gerado com `git diff --binary`. Para regenerar, edite preservando o UTF-16LE com BOM.
  - Patch binário só aplica sobre o blob exato. Se o upstream mudar esses `.rc`, refaça o patch.

## 0010-pt-br-translations.patch
- **Arquivo:** `translations/client_pt_BR.ts`.
- **Mudanças:**
  - Atualiza 2 mensagens cujo texto-fonte mudou no 0008: assistente e Client Push.
  - Acrescenta 3 traduções novas: o crédito GPL e o código-fonte (`OCC::Theme`) e o copyright da Level (`OCC::LegalNotice`).
  - Crédito em pt-BR, exato como no briefing: "Baseado no Nextcloud Desktop Client, licenciado sob GPLv2."
- **Outros idiomas:** caem no texto em inglês até serem traduzidos.
