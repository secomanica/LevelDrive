# CLAUDE.md — Level Drive (white-label do Nextcloud Desktop)

Fork do `nextcloud/desktop` para a Level Tecnologia. Produto: **Level Drive**. Alvo: Windows x64, instalador MSI.
Licença: GPLv2. Manter todos os avisos de copyright do Nextcloud/ownCloud e acrescentar o crédito da Level.

## Layout
```
C:\suporte\level-brand\     logos oficiais (NUNCA editar; hashes em SOURCE.md)
C:\suporte\level-desktop\   este repositório (branch level/branding sobre a tag v35.0.3)
  level-theme\              toda a customização Level (docs, tema, scripts)
  level-theme\docs\         análises (fase1-mapa-branding.md, fase1-inventario-nextcloud.md)
  level-theme\tools\        scripts reprodutíveis
C:\CraftRoot\               KDE Craft (dependências, Qt 6.11.2, build)
C:\build-tools\downloads\   instaladores das ferramentas
```

## Base upstream
- Tag **v35.0.3** (commit `809fadb791`), conferida em 2026-11-11 como a última estável.
- Qt mínimo 6.10.0 (`CMakeLists.txt:33`). O Craft usa Qt 6.11.2 (`craftmaster.ini`).

## Ambiente (Fase 0 — Windows Server 2019, sem winget)
Instalados a partir dos instaladores oficiais (assinaturas conferidas):
- Git 2.56.1
- Python 3.12.10 em `C:\Python312-x64` (o mesmo caminho do `craftmaster.ini`)
- VS 2022 Build Tools com o workload VCTools (MSVC 14.44, SDK 10.0.26100)
- .NET 3.5 (`Install-WindowsFeature NET-Framework-Core`)
- WiX 3.14
- Inkscape 1.4.2
- ImageMagick 7.1.2-35

CMake, Ninja e Qt vêm do Craft.

## Comandos que funcionaram
```powershell
# Bootstrap do Craft (reproduz o CI windows-build-and-test.yml); usa o cache binário do Nextcloud
powershell -ExecutionPolicy Bypass -File level-theme\tools\craft-bootstrap.ps1
# Copia craftmaster.ini para C:\CraftRoot, clona o CraftMaster, adiciona os blueprints stable-35.0,
# roda "craft craft" e "craft --install-deps nextcloud-client". Concluiu em ~25 min (2026-11-11), cache binário.

# Tema
powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1 [-Check | -Revert]

# Validar valores do CMake sem build completo (feito na Fase 2): cmake -P carregando o NEXTCLOUD.cmake aplicado
# cmake do Craft: C:\CraftRoot\windows-msvc2022_64-cl\build\dev-utils\cmake\image-RelWithDebInfo-latest\dev-utils\bin\cmake.exe

# Ícones (Fase 3): gera level-theme\overlay\ a partir de ..\level-brand\ (Inkscape + ImageMagick)
powershell -ExecutionPolicy Bypass -File level-theme\tools\build-icons.ps1

# Configure completo via Craft com o tema aplicado (passou em 2026-11-11, ~3 min)
powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1
powershell -ExecutionPolicy Bypass -File level-theme\tools\craft-build.ps1 -Stage configure
# diretório de build do Craft: C:\_\d93c962e\build  (config.h lá confirma os valores da marca)
powershell -ExecutionPolicy Bypass -File level-theme\tools\craft-build.ps1 -Stage compile
# compilação completa OK em 2026-11-11 (~11 min, 949 etapas, 8 núcleos): C:\_\d93c962e\build\bin\leveldrive.exe
# (ProductName "Level Drive", CompanyName "Level Tecnologia", ícone Level; DLLs leveldrivesync*.dll)
```

## Build Release + MSI (Fase 6): passo a passo que funcionou (2026-11-12)
```powershell
cd C:\suporte\level-desktop
# 0. (uma vez por máquina) ambiente da Fase 0 + bootstrap do Craft
powershell -ExecutionPolicy Bypass -File level-theme\tools\craft-bootstrap.ps1
# 1. tema
powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1
# 2. build Release + install + qmerge + pacote portátil do Craft (~15 min do zero; incremental ~3 min)
powershell -ExecutionPolicy Bypass -File level-theme\tools\craft-build.ps1 -Stage "configure,compile,install,qmerge,package" -BuildType Release
#    -> pasta do app em C:\CraftRoot\windows-msvc2022_64-cl\build\nextcloud-client\archive
# 3. MSI (monta o HarvestAppDir plano, roda o make-msi.bat do upstream, confere erros do WiX)
powershell -ExecutionPolicy Bypass -File level-theme\tools\build-msi.ps1          # sem assinatura
powershell -ExecutionPolicy Bypass -File level-theme\tools\build-msi.ps1 -Sign    # quando houver certificado
#    -> level-theme\build\out\LevelDrive-35.0.3.0-x64.msi (71,9 MB; en-us + transforms de/fr/it/es/pt-br)
# 4. voltar a árvore upstream antes de commitar
powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1 -Revert
```
Detalhes do MSI:
- O `level-theme\craft\level-overrides.ini` (via `--config-override`) troca o pacote NSIS do blueprint pelo `PortablePackager`.
- O MSI usa o `make-msi.bat`, o `.wxs` e o `OEM.wxi` gerados pelo próprio CMake (`BUILD_WIN_MSI=ON`).
- O layout é plano: o conteúdo de `archive\bin\*` vai para a raiz, mais os exes, `i18n\` (incluindo as traduções do Qt em pt-BR), `sync-exclude.lst`, `openssl.cnf` e `LevelDrive.ico`.
- Conferido sem instalar (tabelas do MSI e transform pt-BR aplicado numa cópia):
  - ProductName "Level Drive", Manufacturer "Level Tecnologia", UpgradeCode Level, INSTALLDIR "Level Drive";
  - 2043 arquivos, nenhum com "nextcloud" no nome;
  - registro `Software\Classes\leveldrive`;
  - textos pt-BR ("Abrir o Level Drive", "Atalho no Menu Iniciar"…).
- Assinatura: `level-theme\tools\sign-level.ps1`. **Preparada, não executada**, com placeholders para certificado e carimbo de tempo. A senha vem da variável `LEVEL_SIGN_PASSWORD` e nunca fica no repositório.
  - **Certificado: SSL.com eSigner (nuvem)**, definido pelo usuário em 2026-11-12. Integração via **eSigner CKA** (Cloud Key Adapter), que expõe o certificado no repositório "Pessoal" do Windows, e `signtool /sha1 <thumbprint>`. Configuração fora do repositório: `LEVEL_SIGN_THUMBPRINT`. Carimbo de tempo: `http://ts.ssl.com`. Para build sem interação, o CKA fica em modo "Automated", com o segredo TOTP do eSigner configurado no próprio CKA.
  - Escopo: `build-msi.ps1 -Sign [-SignScope All|Level]`. **All** (padrão) assina ≈215 arquivos por build. **Level** assina ≈10: `leveldrive*.exe/.dll`, `NC*.dll`, `CfApiShellExtensions.dll`, `NCMsiHelper64.dll`. O `.msi` é sempre assinado. Use Level se o plano do eSigner tiver cota de assinaturas.
  - Armadilha corrigida: o `build-msi.ps1` chamava o `sign-level.ps1` com `powershell -File` e dois caminhos em `-Path`, que chegavam quebrados. Agora chama no mesmo processo.
  - **O que assinar** (revisto em 2026-11-12): todo `.exe`/`.dll` ainda sem assinatura válida, e não só os binários Level. O Nextcloud oficial assina os 129 do seu pacote. O pacote Level tem 202 sem assinatura (Qt, OpenSSL, KDE…) e 12 já assinados pela Microsoft (runtime VC++), que são mantidos. Também a `NCMsiHelper64.dll`, embutida no MSI, e por último o `.msi`, depois dos transforms.

## Decisões
- **Nome do produto:** Level Drive. Vendor: Level Tecnologia.
- **Instalador:** MSI (WiX v3, fontes em `admin/win/msi`). O Craft gera NSIS por padrão. O MSI é feito com `BUILD_WIN_MSI=ON` + `make-msi.bat`.
- **Logos:** mantêm as cores dos próprios SVGs. Os tokens do design system valem só para a interface (ver o HANDOFF em `level-brand`).
- **Fontes:** Aptos/Century Schoolbook pelo nome de família, com fallback. Nenhum arquivo de fonte é empacotado.
- **Mecanismo de tema:** o `OEM_THEME_DIR` **não existe** na v35.0.3 (ver `level-theme/docs/fase1-mapa-branding.md`). Abordagem aprovada em 2026-11-11:
  - `level-theme/` com o `NEXTCLOUD.cmake` da Level, `patches/` e `overlay/`;
  - `tools/apply-theme.ps1` aplica tudo por cima da árvore upstream, que **não é commitada** com o tema.
- **Nomes:**
  - Nome exibido: Level Drive.
  - SHORTNAME `LevelDrive` e EXECUTABLE `leveldrive` (confirmados pelo usuário em 2026-11-12; não mudar após o 1º release). Daí vêm o nome do MSI, `leveldrive.exe`, `leveldrive.cfg` e o pipe `\\.\pipe\leveldrive-<user>`.
  - A pasta de dados usa o APPLICATION_NAME, conferido na instalação (Fase 7): `%APPDATA%\Level Drive` (cfg e logs) e `%LOCALAPPDATA%\Level Drive` (cache). O Nextcloud usa `%APPDATA%\Nextcloud`, então não há conflito.
  - O texto "Git revision" do MSI e do "Sobre" é o HEAD no momento do build. Faça o commit antes do build de release.
- **URI scheme:** `leveldrive://` (decisão de 2026-11-11). Consequência aceita: o "Abrir localmente" do servidor, que gera links `nc://`, não abre o Level Drive.
- **Domínio (decisão de 2026-11-12):** o domínio do projeto é sempre `leveldrive.com.br`. `APPLICATION_DOMAIN` = `leveldrive.com.br`; `APPLICATION_REV_DOMAIN` = `br.com.leveldrive.desktopclient` (DBUS `desktopclient.leveldrive.com.br`). Vendor continua "Level Tecnologia", que é o nome da empresa. Exceção: o link de Ajuda (`APPLICATION_HELP_URL`) é `https://leveltecnologia.com.br/`, o site da empresa.
- **Servidores (decisão de 2026-11-12, opção A):** `APPLICATION_SERVER_URL` é uma lista JSON com `https://leveldrive.com.br`, `https://drv2.leveldrive.com.br` e `https://drv3.leveldrive.com.br` (nesta ordem; o primeiro vem selecionado). Com `APPLICATION_SERVER_URL_ENFORCE ON`, o assistente mostra uma lista de escolha no lugar do campo de URL. Recurso nativo do upstream, sem patch (`accountwizardcontroller.cpp:168`, `ServerPage.qml:57-80`).
  - Consequências aceitas: o usuário só conecta a esses três servidores, e links `leveldrive://login` para outros servidores são recusados.
  - A escolha do servidor no instalador MSI (opção B: tela no WiX e propriedade gravando `HKLM\Software\Policies\Level Tecnologia\Level Drive\overrideServerUrl`) ficou para depois.
  - Armadilha: é uma variável normal, sem CACHE. Com `CACHE STRING`, um `CMakeCache.txt` antigo com valor vazio venceria. Use bracket argument `[=[...]=]` por causa das aspas do JSON.
- **Updater:** DESLIGADO (`BUILD_UPDATER OFF`) até existir o servidor de atualização da Level. Para religar:
  - `APPLICATION_UPDATE_URL` = URL real;
  - `BUILD_UPDATER` = ON em `level-theme/NEXTCLOUD.cmake`.
- **Coexistência com o Nextcloud oficial:**
  - 10 GUIDs próprios: overlays, menu de contexto, UpgradeCode do MSI e CfApi. **Nunca mudar o UpgradeCode depois do 1º release.**
  - `DISABLE_ACCOUNT_MIGRATION=ON`.
  - patch 0002 (painel de navegação).
- **Assistente:** os botões "Sign up" e "Self-host" ficam escondidos (levavam a nextcloud.com). `THEME_CLASS = Theme` (sem a dica try.nextcloud.com).
- **Bandeja (opção A, aprovada em 2026-11-11):** `black/` (barra clara) usa o símbolo `-cor` e `white/` (barra escura) usa o `-cor-negativo`. O patch 0003 escolhe pelo tema da barra. `colored/` (dentro do app) usa a versão clara.
- **Ícones:** gerados por `build-icons.ps1`. Os `<path>` dos SVGs oficiais são copiados verbatim, sem recolorir, e só posicionados com `transform`. A saída é SVG Tiny, compatível com o QSvgRenderer. O `wizard_logo.svg` é a cópia byte a byte do horizontal `-cor-negativo`.
  - Estados = símbolo + indicador circular.
  - Vermelho, âmbar e cinza dos indicadores aguardam confirmação da Level.
- **Interface (Fase 4):**
  - Tokens Level no `Style.qml` (patch 0004).
  - Texto `#103B40` sobre o verde, nunca branco (patch 0005).
  - Fonte Aptos → Segoe UI → Arial pelo nome de família, sem empacotar arquivo de fonte (patch 0006).
  - Serifa Century Schoolbook → Georgia só no título "Log in to %1".
  - Links `#103B40`/`#53AE93`.
  - Contraste: `C:\Python312-x64\python.exe -I level-theme\tools\check-contrast.py` (44/44).
  - Mantido do servidor: `accentColor` e as cores de cabeçalho vêm do app Theming do servidor. Configurar `#103B40` nos servidores Level.
  - Mantido do Windows: a cor de destaque nativa (checkboxes) nos Widgets do Win11.
- **Prévia visual:** https://claude.ai/artifact/7x2iwcghTs3Nz3xECbQsPz (privada).
- **Cores CMake:**
  - fundo/cabeçalho do assistente `#103B40`;
  - título `#EFEFEF`;
  - cor padrão `#103B40`.

## Armadilhas
- **winget:** não existe no Windows Server 2019. Usar os instaladores oficiais.
- **VS Build Tools e MSI simultâneos:** instalar os VS Build Tools ao mesmo tempo que outro MSI dá exit code 1618. Instalar um de cada vez.
- **vswhere no PATH:** o `vcvarsall.bat` precisa do `vswhere.exe` no PATH (`C:\Program Files (x86)\Microsoft Visual Studio\Installer`). Sem isso, o Craft quebra com `JSONDecodeError` em `CraftSetupHelper.getMSVCEnv`. O script de bootstrap corrige isso só para o processo.
- **`core.autocrlf`:** não mudar depois do clone. O padrão do Git para Windows é `true`, igual ao CI do upstream, e os `.bat` do MSI precisam de CRLF. Forçar `false` marcou 401 arquivos como modificados (só finais de linha).
- **`Start-Process -Command` com `*>`:** não gerou log. Usar `-File` com `-RedirectStandardOutput`.
- **`#cmakedefine` vazio:** variável vazia vira macro indefinida.
  - `APPLICATION_HELP_URL` vazio volta para docs.nextcloud.com.
  - `APPLICATION_UPDATE_URL` vazio não compila.
- **`set()` simples:** `NEXTCLOUD.cmake` usa `set()` simples na maior parte das variáveis, e `-D` não sobrescreve.
- **PNGs gerados na árvore de fontes:** o build gera PNGs dentro de `theme/` e não os regenera se já existirem. Apagar os PNGs derivados ao trocar SVGs.
- **`$ErrorActionPreference = 'Stop'` no PowerShell 5.1:** qualquer stderr de um comando nativo (git) vira erro fatal, mesmo com `2>$null`. Nos scripts, usar `'Continue'` e checar `$LASTEXITCODE`.
- **Scripts `.ps1` com acentos:** salvar em UTF-8 **com BOM**. Sem o BOM, o PowerShell 5.1 lê como ANSI.
- **`option()` × `set()`:** o `option()` não sobrescreve variável normal já definida (CMP0077 NEW, `cmake_minimum_required 3.16`). Por isso o `NEXTCLOUD.cmake` da Level fixa com `set()` as opções do CMakeLists raiz: `DISABLE_ACCOUNT_MIGRATION`, `WIZARD_HIDE_*`, `BUILD_UPDATER`, `BUILD_WIN_MSI`.
- **Configure sem os ícones:** o configure completo só passa depois da Fase 3. Sem `theme/colored/LevelDrive-icon.svg`, o `ecm_add_app_icon` fica sem ícones (`src/gui/CMakeLists.txt:577`).
- **Blueprint do Craft (`nextcloud-client.py`):** na etapa `createPackage` (NSIS), o nome "nextcloud" e "Nextcloud GmbH" estão fixos. Não usar o pacote NSIS do Craft. O MSI sai do `make-msi.bat` (Fase 6).
- **Alias `R` no PowerShell:** `R` é alias de `Invoke-History`. Não nomear funções `R`, `H`, `C` etc.
- **`switch` + splatting:** um `switch` que devolve um único valor dá uma string, e `@var` a quebra em caracteres (`- - c o n f i g u r e`). Envolver com `@( switch ... )`.
- **`--src-dir` do Craft:** está obsoleto. Usar `--options nextcloud-client.srcDir=<repo>`.
- **Variável `WIX`:** sessões abertas antes da instalação do WiX não têm a variável. O `NCMsiHelper` falha no configure. O `craft-build.ps1` relê a variável do sistema.
- **ImageMagick `-splice` com `-gravity center/south`:** insere o espaçamento no meio da imagem. Isso só afetou a folha de prévia, não os ícones.
- **PNGs do upstream:** o configure gera PNGs também para `theme/*/nextcloud/state-*.svg` do upstream. Eles são ignorados pelo `.gitignore` e inofensivos.
- **`Style.qml` com EOL misto:** o `theme/Style/Style.qml` upstream tem finais de linha MISTOS no índice (`git ls-files --eol` = `i/mixed`). Editar com ferramenta que normaliza EOL gera um patch do arquivo inteiro. Editar preservando o EOL por linha (script Python lendo bytes) e conferir com `git diff --stat`.
- **`apply-theme -Check` testa patches isolados:** cada patch é checado contra o upstream sozinho. Patches que tocam o mesmo arquivo (0003 e 0006 no `theme.cpp`) só são validados de verdade aplicando em sequência (sem `-Check`).
- **Python:** não está no PATH desta sessão. Usar `C:\Python312-x64\python.exe`.
- **`.rc` das extensões de shell:** `NCContextMenu.rc`, `NCOverlay.rc` e `NCUtil.rc` são UTF-16LE com BOM e estão marcados como binários (`-text`). Edite decodificando e recodificando em UTF-16LE. O patch deve sair com `git diff --binary` (0009).
- **Buscar texto em `.qm`:** o `.qm` é UTF-16BE e as strings podem começar em offset ímpar. Uma busca de bytes com uma só alinhamento dá falso negativo; teste os dois alinhamentos.
- **Edições literais em fontes upstream:** use um script que exige exatamente 1 ocorrência e preserva BOM e EOL (padrão usado na Fase 5), em vez de ferramentas que normalizam o arquivo.
- **Regra `build*` do `.gitignore` raiz do upstream (linha 17):** ignora qualquer arquivo que comece com "build". Ela escondeu o `build-icons.ps1` (Fase 3) e o `build-msi.ps1` dos commits até a Fase 6. A exceção está em `level-theme/.gitignore` (`!/tools/build-*.ps1`). Ao criar arquivos novos, confira com `git status --ignored -- level-theme`.
- **Bug no blueprint externo:** o `craft-blueprints-nextcloud` (stable-35.0) `nextcloud-client.py:85` usa `os.path` sem `import os`, e o `craft --package` dá `NameError`. O `craft-build.ps1` acrescenta o import só durante o package e restaura o arquivo com `git checkout`.
- **Blacklist do blueprint:** `bin/(?!(nextcloud|nextcloudcmd|QtWebEngineProcess)).*\.exe` **remove o `leveldrive.exe` e o `leveldrivecmd.exe` do pacote**. O `build-msi.ps1` copia os dois do `C:\CraftRoot\windows-msvc2022_64-cl\bin`. O blacklist também remove `translations/` (traduções do Qt), e o `build-msi.ps1` copia as do pt-BR para `i18n\`.
- **`--options` do Craft:** é um valor por `--options`. Um segundo valor solto vira nome de pacote ("Craft was unable to find nextcloud-client.buildType=Release").
- **Arrays com `powershell -File`:** `-Stage a,b` chega como string única. O `craft-build.ps1` recebe texto e separa por vírgula.
- **`NoDefaultCurrentDirectoryInExePath=1`:** está definido neste ambiente. O `cmd` não executa `.bat`/`.cmd` da pasta atual pelo nome; usar caminho completo. `Push-Location` também não muda o diretório do processo filho; usar `Start-Process -WorkingDirectory`.
- **`light` do WiX v3:** junta todos os `-loc` cujas culturas casam. Passe um `.wxl` por link, senão dá `LGHT0100` (ver patch 0011).
- **`make-msi.bat` do upstream:** não para em erro dentro dos laços e termina com "Done". Sempre conferir o log (o `build-msi.ps1` faz isso).
- **Ler tabelas de MSI:** no PowerShell 5.1, o COM do Windows Installer exige índices `[int]`. É mais simples usar `msilib` do Python 3.12 ou VBScript (`cscript`). `Key` é palavra reservada no SQL do MSI e vai entre crases.
- **Hook de pre-commit:** o configure instala um hook de pre-commit do KDE (`CMakeLists.txt:101`, clang-format). Para commitar, coloque `C:\CraftRoot\windows-msvc2022_64-cl\bin` **no fim** do PATH (traz o `git-clang-format`). Não usar `--no-verify`. O hook só atua em `.cpp`/`.h` staged. Como os patches da Level são arquivos `.patch` e o código upstream nunca é commitado, ele não bloqueia. Ressalva: o clang-format do Craft (LLVM 20) não entende `EnumTrailingComma` do `.clang-format` da v35 (precisa do clang-format 21+). Por isso não dá para checar a formatação dos patches localmente.
- **`.ico`:** só é gerado na compilação (`ecm_add_app_icon`), não no configure.
- **`APPLICATION_WIZARD_USE_CUSTOM_LOGO`:** não desligar. O ramo `#else` tem erro de sintaxe (`theme.cpp:853`).

## Pendências / placeholders
Os valores provisórios ficam em `level-theme/NEXTCLOUD.cmake`, marcados com `<<PREENCHER>>`.
- `<<PREENCHER: confirmar nomes exibidos dos servidores>>`. Hoje: "Level Drive", "Level Drive 2" e "Level Drive 3". As URLs já foram definidas.
- `<<PREENCHER: URL do servidor de atualização>>` (futuro; o updater está desligado).
- Ajuda: `APPLICATION_HELP_URL` = `https://leveltecnologia.com.br/`, o site da empresa (decisão de 2026-11-12). É aberto pelo menu "Ajuda" (`owncloudgui.cpp:774`) e por Configurações > Info (`infosettings.cpp:66`).
  - `Theme::conflictHelpUrl()` (`<help>/conflicts.html`, `theme.cpp:504`) existe, mas **nenhuma tela o usa em v35** (conferido com grep em cpp/qml/ui), então não há 404. Conferir de novo ao atualizar a versão do upstream.
- `<<PREENCHER: usuário de teste num servidor Level>>`: login, sincronização, menu de contexto, overlays e arquivos virtuais ainda não foram testados (Fase 7).
- `<<PREENCHER: certificado de assinatura de código>>`, em `level-theme/tools/sign-level.ps1`:
  - `.pfx` ou thumbprint/token;
  - URL de carimbo de tempo RFC 3161 da CA;
  - URL de descrição.
  - Senha via `LEVEL_SIGN_PASSWORD`.
- `<<PREENCHER: confirmar cores dos indicadores de estado>>`: erro #C8423B/#E0645C, aviso #E0A526, pausa/offline #5B5C5C/#B6B6B6 (`build-icons.ps1`).
- **Repositório público (GPL), definido em 2026-11-12:** https://github.com/secomanica/LevelDrive (remote `level`; branches `main` e `level/branding`, mesmo commit). `APPLICATION_SOURCE_URL` aponta para ele: o "Sobre" mostra "Código-fonte: <url>" e a revisão Git aponta para `<url>/commit/<sha>`. Por isso **todo commit usado num build distribuído precisa estar enviado (push)**.
  - Licença: GPLv2 (`COPYING` do upstream). O `LICENSE` GPLv3 que o GitHub criou no commit inicial foi removido no merge `bdc2dd5879`.
  - Envio: o ambiente das ferramentas do Claude tem `GCM_INTERACTIVE=never`. O primeiro login foi feito numa janela PowerShell separada, com token clássico (`repo` + `workflow`). O token fica salvo no Gerenciador de Credenciais do Windows. O escopo `workflow` é obrigatório porque o upstream tem `.github/workflows/`.
  - Efeito colateral: as GitHub Actions e o Dependabot do upstream disparam no repositório (93 execuções e 4 PRs no 1º envio). Desligar Actions nas configurações do repositório.
- **Outros idiomas:** 2 textos alterados e 3 novos ficam em inglês fora do pt-BR até serem traduzidos.
- **Validar numa estação Windows 10/11 real** (o Server 2019 não cobre):
  - se o estilo FluentWinUI3 (Win11) respeita a fonte Aptos nos controles QML;
  - a barra de tarefas clara (ícones `black/`);
  - a escala de 150%/200%;
  - as Configurações no Win11 escuro: lá a paleta reserva do patch 0006 não é aplicada, e o ícone da página selecionada segue o `HighlightedText` do sistema.
- **Opcional:** aplicar a cor de destaque Level à paleta global (checkboxes e realces nativos dos Widgets).
- **Opcional:** remover `HKCU\...\Run\LevelDrive` na desinstalação (`RegistryCleanup.vbs.in`). O Nextcloud oficial também deixa essa entrada.
- **Opcional:** corrigir o texto pt-BR do assistente ("Insira o link para o sua interface web…").
- **Servidores Level:** configurar o app Theming (cor primária `#103B40`), porque o cliente usa essa cor em atividades e cabeçalhos.

## Status das fases
| Fase | Status |
|---|---|
| 0 Ambiente | Concluída (2026-11-11) |
| 1 Clone e análise | Concluída (2026-11-11) |
| 2 Tema OEM | Concluída (2026-11-11): NEXTCLOUD.cmake Level, patches 0001/0002, apply-theme.ps1 |
| 3 Ícones e imagens | Concluída (2026-11-11): build-icons.ps1, overlay (38 arquivos), patch 0003, configure completo OK |
| 4 Cores e fontes | Concluída (2026-11-11): patches 0004–0006, contraste 44/44, compilação completa OK |
| 5 Textos e localização | Concluída (2026-11-11): patches 0007–0010 + 0003 estendido, pt-BR, créditos GPL, compilação OK (ver `level-theme/docs/fase5-textos.md`) |
| 6 Build e instalador | Concluída (2026-11-12): Release via Craft, patch 0011, `build-msi.ps1` → `LevelDrive-35.0.3.0-x64.msi` com pt-BR; assinatura preparada (`sign-level.ps1`), não executada |
| 7 Validação | Concluída neste servidor (2026-11-12): checklist em `level-theme/docs/fase7-validacao.md`; patches 0012 (idioma pt-BR) e 0013 (cores das Configurações); `LEVEL-BRANDING.md` entregue. Pendentes: login/sync com usuário de teste e Win10/11 reais |
