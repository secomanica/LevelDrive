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
powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1 -Revert
```

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
  - SHORTNAME `LevelDrive` e EXECUTABLE `leveldrive` (sugeridos, aguardando confirmação). Daí vêm `%APPDATA%\LevelDrive`, `leveldrive.exe` e o pipe `\\.\pipe\leveldrive-<user>`.
- **URI scheme:** `leveldrive://` (decisão de 2026-11-11). Consequência aceita: o "Abrir localmente" do servidor, que gera links `nc://`, não abre o Level Drive.
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
- **`.ico`:** só é gerado na compilação (`ecm_add_app_icon`), não no configure.
- **`APPLICATION_WIZARD_USE_CUSTOM_LOGO`:** não desligar. O ramo `#else` tem erro de sintaxe (`theme.cpp:853`).

## Pendências / placeholders
Os valores provisórios ficam em `level-theme/NEXTCLOUD.cmake`, marcados com `<<PREENCHER>>`.
- `<<PREENCHER: confirmar SHORTNAME "LevelDrive" / EXECUTABLE "leveldrive">>`. **Precisa estar fechado antes do 1º release:** o SHORTNAME vira a pasta `%APPDATA%`.
- `<<PREENCHER: confirmar APPLICATION_DOMAIN "leveltecnologia.com.br" / REV_DOMAIN "br.com.leveltecnologia.drive">>`
- `<<PREENCHER: APPLICATION_SERVER_URL>>`. Hoje está vazio: o usuário digita a URL. Se preenchido, fica fixo (ENFORCE ON).
- `<<PREENCHER: URL do servidor de atualização>>` (futuro; o updater está desligado).
- `<<PREENCHER: site/suporte da Level>>`. `APPLICATION_HELP_URL` está provisoriamente em `https://leveltecnologia.com.br/`.
- `<<PREENCHER: URL de homologação>>` (Fase 7).
- `<<PREENCHER: certificado de assinatura de código>>` (Fase 6).
- `<<PREENCHER: URL pública do código-fonte do fork>>` (GPL; usada no "Sobre", Fase 5).
- `<<PREENCHER: confirmar cores dos indicadores de estado>>`: erro #C8423B/#E0645C, aviso #E0A526, pausa/offline #5B5C5C/#B6B6B6 (`build-icons.ps1`).
- **Pendente da Fase 5/6:** o MSI do upstream só tem transforms en/de/fr/it/es. Incluir pt-BR.
- **Pendente da Fase 4/5:** a opção "ícones monocromáticos" fica sem efeito no Windows (patch 0003). Avaliar escondê-la.

## Status das fases
| Fase | Status |
|---|---|
| 0 Ambiente | Concluída (2026-11-11) |
| 1 Clone e análise | Concluída (2026-11-11) |
| 2 Tema OEM | Concluída (2026-11-11): NEXTCLOUD.cmake Level, patches 0001/0002, apply-theme.ps1 |
| 3 Ícones e imagens | Concluída (2026-11-11): build-icons.ps1, overlay (38 arquivos), patch 0003, configure completo OK |
| 4–7 | Não iniciadas |
