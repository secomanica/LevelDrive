# Fase 1 — Mapa do branding (Nextcloud Desktop v35.0.3)

Análise feita em 2026-11-11 sobre a tag `v35.0.3` (commit `809fadb791`). Caminhos relativos à raiz do repositório.

## Conclusões principais

1. **Não existe mecanismo `OEM_THEME_DIR` nesta versão.**
   - O nome aparece só em comentário (`NEXTCLOUD.cmake:102-103`).
   - `NEXTCLOUD.cmake` é incluído direto por `CMakeLists.txt:30`, `NextcloudCPack.cmake:8` e `CPackOptions.cmake.in:17`.
   - `theme_dir` está fixo em `src/gui/CMakeLists.txt:36` e em `src/libsync/vfs/cfapi/shellext/CMakeLists.txt:8`.
   - A seção `[Custom_Variables_for_Brander]` do `craftmaster.ini:67-69` serve à ferramenta "Brander" do Nextcloud, que fica fora do repositório e roda em Linux/Docker. Ela sobrescreve `NEXTCLOUD.cmake` e `theme/`.
2. **Não dá para fazer o branding só com `-D`.** `APPLICATION_NAME`, `SHORTNAME`, `EXECUTABLE`, `VENDOR`, `DOMAIN`, `REV_DOMAIN`, os GUIDs e `THEME_CLASS` são definidos com `set()` simples, que sobrescreve qualquer `-D`. Só alguns são `CACHE`: `UPDATE_URL`, `HELP_URL`, `SERVER_URL`, `VIRTUALFILE_SUFFIX`, as cores e as `option()`.
3. **`THEME_CLASS`/`THEME_INCLUDE` quase não servem.** Em `theme.h` só `wizardUrlHint()` é virtual (`theme.h:487`). Mudar outro comportamento exige patch em `theme.cpp`.
4. **Pegadinha do `#cmakedefine`.** Variável vazia vira macro indefinida (`config.h.in`). Efeitos:
   - `APPLICATION_HELP_URL=""` cai no fallback docs.nextcloud.com (`theme.cpp:495-499`).
   - `APPLICATION_UPDATE_URL` vazio **não compila** (`theme.cpp:610`, `updater.cpp:54`).
5. **Não desligar `APPLICATION_WIZARD_USE_CUSTOM_LOGO`.** O ramo `#else` tem erro de sintaxe (`theme.cpp:853`: `isHidpi() ?: 200 : 100`).

## Variáveis de NEXTCLOUD.cmake e para onde vão

| Variável | Linha | Tipo | Efeito no Windows |
|---|---|---|---|
| APPLICATION_NAME | 13 | set | `appNameGUI()` (`theme.cpp:152`); ProductName/FileDescription do exe (`src/gui/version.rc.in:9`); nome do sync root CfApi (`folder.cpp:604`, `cfapiwrapper.cpp:812`); servidor IPC CfApi (`shellextensionutils.cpp:21`); painel de navegação; nomes CfApi (`CMakeLists.txt:39-47`); MSI `AppName`; `INSTALLDIR` |
| APPLICATION_SHORTNAME | 14 | set | `appName()` → `setApplicationName` (`application.cpp:274`) → `%APPDATA%\<SHORTNAME>`; prefixo do keychain; valor da chave Run (`utility_win.cpp:286`); nome do MSI; nomes de overlay e menu de contexto |
| APPLICATION_EXECUTABLE | 15 | set | `<exe>.exe`, `<exe>cmd.exe`, DLLs `<exe>sync`/`_csync`/`sync_vfs_*`; named pipe `\\.\pipe\<exe>-<user>` (`socketapi.cpp:261`); manifest `theme/<exe>.VisualElementsManifest.xml` |
| APPLICATION_CONFIG_NAME | 19 | set (= EXECUTABLE) | `<x>.cfg` (`theme.cpp:273`) |
| APPLICATION_ICON_NAME | 16 | set | `theme/colored/<ICON>-icon.svg`, `-w10startmenu.svg`, `icons/<ICON>-icon-win-folder.svg`, `<ICON>.ico` |
| APPLICATION_VENDOR | 21 | set | CompanyName do exe; `HKLM\Software\<Vendor>\<Name>` e políticas (`configfile.cpp:1009`, `devicesources.cpp:26-36`); Manufacturer do MSI; "This release was supplied by" (`theme.cpp:707`) |
| APPLICATION_DOMAIN | 20 | set | Links de Ajuda/Info em Adicionar/Remover Programas (`OEM.wxi.in:18`) |
| APPLICATION_REV_DOMAIN / _DBUS | 84-85 | set | `setOrganizationDomain`; não afeta caminhos no Windows |
| APPLICATION_UPDATE_URL | 22 | CACHE | updater (`updater.cpp:47-77`); não pode ficar vazio |
| APPLICATION_HELP_URL | 23 | CACHE | Ajuda e conflitos (`theme.cpp:493-510`); vazio vaza docs.nextcloud.com |
| APPLICATION_SERVER_URL | 82 | CACHE | URL do servidor pré-preenchida (`theme.cpp:461-466`) |
| APPLICATION_SERVER_URL_ENFORCE | 83 | set ON | com SERVER_URL definido, só conecta àquela URL |
| APPLICATION_VIRTUALFILE_SUFFIX | 87 | CACHE | extensão `.nextcloud` dos arquivos virtuais no modo sufixo |
| THEME_CLASS | 97 | set | `NextcloudTheme` → placeholder `try.nextcloud.com` (`nextcloudtheme.cpp:30`) |
| NEXTCLOUD_BACKGROUND_COLOR | 120 | CACHE | `#0082c9`; `Theme::defaultColor()` (`theme.cpp:1101`) |
| APPLICATION_WIZARD_HEADER_BACKGROUND/TITLE_COLOR | 121-122 | CACHE | `Style.qml:14-15` (`ncBlue`, `ncHeaderTextColor`) |
| WIN_SHELLEXT_* GUIDs, WIN_MSI_UPGRADE_CODE | 130-140 | set | Overlays e menu de contexto legados; UpgradeCode do MSI. O próprio arquivo pede GUIDs novos. |
| BUILD_UPDATER | 106 | option ON | updater (`NSISUpdater`, também serve para o MSI) |
| BUILD_WIN_MSI | 143 | option OFF | gera os fontes WiX e o `make-msi.bat`; não gera o `.msi` sozinho |

Fora do `NEXTCLOUD.cmake`, em `CMakeLists.txt` e com `set` simples:
- GUIDs CfApi em `:38,41,45`
- `APPLICATION_URI_HANDLER_SCHEME "nc"` em `:50`
- `WIZARD_HIDE_SELF_HOST_BUTTON` e `WIZARD_HIDE_SIGNUP_BUTTON` (`:64-65`, option)
- `DISABLE_ACCOUNT_MIGRATION` e `APPLICATION_DISPLAY_LEGACY_IMPORT_DIALOG` (`:62-63`, option)
- `APPLICATION_SIGNUP_URL` (`:66-68`)

## Coexistência com o Nextcloud oficial (mesma máquina)

Mudam sozinhos quando os nomes mudam: `%APPDATA%`, keychain, chave Run, named pipe, IPC CfApi, SyncRootManager, `HKLM\Software\<Vendor>\<Name>`, `INSTALLDIR`, atalhos.

Exigem ação explícita:
1. GUIDs novos para overlays, menu de contexto e UpgradeCode (`NEXTCLOUD.cmake:130-140`).
2. GUIDs novos para o AppID e os 2 CLSIDs CfApi (`CMakeLists.txt:38,41,45`). **Patch.** Sem isso, um cliente sobrescreve o registro COM do outro, e a desinstalação de um apaga o do outro (`RegistryCleanup.vbs.in:55-79`).
3. Esquema de URI `nc` (`CMakeLists.txt:50`). O MSI grava `HKLM\Software\Classes\nc` com `ForceDeleteOnUninstall` (`Nextcloud.wxs:192-203`). Desinstalar um quebra o outro. **Decisão em aberto:** o servidor gera links `nc://` para "Abrir localmente".
4. **Patch em `src/gui/navigationpanehelper.cpp:71`.** O build com marca apaga as entradas do painel de navegação do Nextcloud oficial (compara com `unbrandedApplicationName = "Nextcloud"`, `navigationpanehelper.h:34`).
5. `-DDISABLE_ACCOUNT_MIGRATION=ON`. Sem isso, o build com marca importa as contas de `%APPDATA%\Nextcloud\nextcloud.cfg` (`migration.cpp:21-22,156-160`).
6. O nome do produto não pode conter "Nextcloud". `RegistryCleanup.vbs.in:43-45` filtra sync roots por substring do nome. "Level Drive" atende.

## Pasta theme/ — o que o build Windows consome

- **Ícone do app:** `theme/colored/<ICON>-icon.svg` gera PNGs 16, 20, 24, 32, 40, 48, 64, 128, 256, 512 e 1024 (`src/gui/CMakeLists.txt:551-561`). O `ecm_add_app_icon` monta o `<ICON>.ico` (até 256 px) e o embute no exe (`:568-577,691`).
- **Ícone de pasta (opcional):** `theme/colored/icons/<ICON>-icon-win-folder.svg` gera o segundo `.ico` (IDI_ICON2) usado no `Desktop.ini` (`:580-602`).
- **Menu Iniciar:** `theme/colored/<ICON>-w10startmenu.svg` gera os PNGs 70 e 150 (`:545-549`). O `theme/<exe>.VisualElementsManifest.xml` é obrigatório (`:686`). O manifest upstream aponta para `Nextcloud-w10starttile.png`, que não bate com o glob de instalação; o nosso deve apontar para os PNGs `70-`/`150-`.
- **Estados (bandeja):**
  - Com nome de marca, usa os SVGs da **raiz** de `colored/`, `white/` e `black/`, não a subpasta `nextcloud/` (`src/gui/CMakeLists.txt:19-23`, `theme.qrc.in:15-145`).
  - Arquivos: `state-{ok,sync,error,pause,offline,warning}.svg`, e mais `state-info.svg` em `white/` e `black/`.
  - O build gera PNGs 16/32/64/128/256 (`:520-535`).
- **Regras da bandeja:**
  - O padrão no Windows é colorido (`_mono=false`, `configfile.cpp:1270-1278`).
  - Com o modo monocromático ligado nas configurações, usa `white` se a barra de tarefas for escura (`utility_win.cpp:303-313`) e `black` se for clara (`theme.cpp:580-589`).
  - Em runtime renderiza o SVG (`APPLICATION_ICON_SET=SVG`, `theme.cpp:60-63,324-340`).
- **Assistente:** `theme/colored/wizard_logo.{svg,png,@2x.png}` é obrigatório no qrc (`theme.qrc.in:150-152`). **Hoje é o logo Nextcloud.**
- **Armadilha:** o gerador de PNG escreve **dentro da árvore de fontes** e **não regenera** se o PNG já existe (`cmake/modules/GenerateIconsUtils.cmake:41-43`). Ao trocar um SVG, apague os PNGs derivados.
- **Extensão CfApi:** `theme/cfapishellext_custom_states/{0-locked,1-shared}.svg`, ícones neutros.

## Estilo (QML / Widgets)

- **`theme/Style/Style.qml`** é um singleton:
  - `ncBlue` e `ncHeaderTextColor` vêm do CMake (`:14-15`);
  - `accentColor` e as cores de cabeçalho de usuário vêm do theming do **servidor**, com fallback para `ncBlue` (`:16-21`);
  - a paleta do assistente é fixa no código (`:24-52`, por exemplo `wizardPrimaryButtonBackground "#2b659a"` em `:44`);
  - ErrorBox e InfoBox estão em `:55-61`.
- **Fontes:** não há `font.family` em lugar nenhum. Os tamanhos vêm de `FontMetrics{}` (`Style.qml:10,63-70`).
- **Tema escuro:** `Theme::darkMode()` (`theme.cpp:1152-1179`) e `reserveDarkPalette` no Windows abaixo do 11 (`theme.cpp:423-457`).
- **Estilos Qt:** FluentWinUI3 (QML) e windows11 (Widgets) no Windows 11; Universal e Fusion no Windows 10 (`src/gui/main.cpp:74-108`).
- **Widgets:** `SettingsDialog::customizeStyle()` (`settingsdialog.cpp:545-584`), `Theme::settingsPanelColor`, `getBackgroundAwareLinkColor` (`theme.cpp:977-1003`).

## Updater

- `BUILD_UPDATER=ON` cria o `NSISUpdater`, que baixa e roda o MSI via msiexec (`ocupdater.cpp:211-231`). A URL leva `msi=true&oem=<appName>`.
- **Para desligar:** `-DBUILD_UPDATER=OFF`, mantendo `APPLICATION_UPDATE_URL` não vazio. Alternativa: apontar para um servidor próprio.

## Instalador MSI

- `-DBUILD_WIN_MSI=ON` faz o `cmake --install` colocar em `msi/`:
  - `Nextcloud.wxs`, `OEM.wxi`, `Platform.wxi`, `collect-transform.xsl`, `make-msi.bat`, `RegistryCleanup*`;
  - `gui/banner.bmp` (493×58) e `gui/dialog.bmp` (493×314);
  - `NCMsiHelper64.dll` e `WinShellExt.wxs` (`admin/win/msi/CMakeLists.txt:22-39`).
- `make-msi.bat <HarvestAppDir>` roda heat → candle → light, mais os transforms de idioma.
  - Saída: `<SHORTNAME>-<ver>-x64.msi`.
  - O `<ICON>.ico` precisa estar no HarvestAppDir (`Nextcloud.wxs:97`); nenhuma regra de install o copia.
- **Licença no MSI:** o diálogo está desabilitado (`Nextcloud.wxs:112-124`, `OEM.wxi.in:23-26`).
- **Craft:** gera NSIS por padrão (`craftmaster.ini:48`). O empacotamento MSI de release do Nextcloud fica no blueprint externo, não no repo. O CI não gera MSI.

## Recursos do executável

- `src/gui/version.rc.in`: ProductName/FileDescription = `APPLICATION_NAME`, CompanyName = `APPLICATION_VENDOR`, LegalCopyright = "(c) ano".
- Ícones IDI_ICON1 e IDI_ICON2 vêm do `ecm_add_app_icon`.
- **Fixo "Nextcloud GmbH"** nos `.rc` das DLLs de shell: `NCContextMenu.rc:70-77`, `NCOverlay.rc:83-89`, `NCUtil.rc:70-76`, `CfApiShellIntegration.rc:37-43`.
