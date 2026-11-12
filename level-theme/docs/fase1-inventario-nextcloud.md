# Fase 1 — Inventário de "Nextcloud" visível ao usuário (build Windows)

Base: tag `v35.0.3`. O inventário cobre o que o usuário final vê. Referências técnicas internas ficam listadas no fim.

Legenda da coluna "Ação":
- **VAR** – a variável já existe.
- **PATCH** – precisa alterar código.
- **IMG** – precisa trocar o arquivo de imagem.
- **DECISÃO** – depende de uma decisão de vocês.

Fase de execução: **F2** = tema OEM, **F3** = ícones e imagens, **F5** = textos.

## A. Variáveis cujo valor padrão mostra Nextcloud

| Local | Valor atual | Onde aparece | Ação | Fase |
|---|---|---|---|---|
| `NEXTCLOUD.cmake:13-16` | NAME/SHORTNAME "Nextcloud", EXECUTABLE "nextcloud" | Toda a interface, exe/DLLs, MSI, atalhos, registro | VAR | F2 |
| `NEXTCLOUD.cmake:20` | DOMAIN "nextcloud.com" | Links em Adicionar/Remover Programas | VAR | F2 |
| `NEXTCLOUD.cmake:21` | VENDOR "Nextcloud GmbH" | CompanyName do exe, Manufacturer do MSI, "supplied by", registro | VAR | F2 |
| `NEXTCLOUD.cmake:22` | UPDATE_URL updates.nextcloud.org | Updater (ofereceria o MSI oficial) | VAR / `BUILD_UPDATER=OFF` | F2 |
| `NEXTCLOUD.cmake:23` | HELP_URL "" → fallback docs.nextcloud.com (`theme.cpp:498`) | Menu Ajuda e link de conflitos | VAR (não vazia) | F2 |
| `CMakeLists.txt:66-67` | SIGNUP_URL "" → nextcloud.com/sign-up (`theme.cpp:657`) | Botão "Sign up" do assistente | `WIZARD_HIDE_SIGNUP_BUTTON=ON` | F2 |
| `CMakeLists.txt:64` | Botão Self-host → docs.nextcloud.com (`accountwizardcontroller.cpp:1020`) | Assistente | `WIZARD_HIDE_SELF_HOST_BUTTON=ON` | F2 |
| `NEXTCLOUD.cmake:84-85` | REV_DOMAIN com.nextcloud.desktopclient | Pouco visível | VAR | F2 |
| `NEXTCLOUD.cmake:87` | VIRTUALFILE_SUFFIX "nextcloud" | Extensão `.nextcloud` (modo sufixo) | VAR | F2 |
| `NEXTCLOUD.cmake:97` | THEME_CLASS NextcloudTheme → try.nextcloud.com (`nextcloudtheme.cpp:30`) | Placeholder do campo de servidor | VAR (`Theme`) | F2 |
| `NEXTCLOUD.cmake:120` | `#0082c9` (azul Nextcloud) | Cabeçalho do assistente, cor padrão | VAR | F2 |
| `NEXTCLOUD.cmake:130-140` | GUIDs do Nextcloud | Conflito com a instalação oficial | VAR (GUIDs novos) | F2 |
| `CMakeLists.txt:50` | URI scheme "nc" | Registro `nc://`, "Abrir localmente" | PATCH + DECISÃO | F2 |

## B. Textos e URLs fixos no código

| # | Local | Literal | Onde aparece | Ação |
|---|---|---|---|---|
| 1 | `src/libsync/theme.cpp:664-665` | `github.com/nextcloud/desktop/commit/` | Sobre / Aviso legal ("Built from Git revision") | PATCH: apontar para o repositório do fork (a GPL exige disponibilizar a fonte) |
| 2 | `src/gui/legalnotice.cpp:47-48` | "Copyright 2017-2026 Nextcloud GmbH / ownCloud GmbH" | Aviso legal | **Manter** (GPL) e acrescentar o crédito da Level |
| 3 | `src/gui/advancedsettings.ui:210` | link `github.com/nextcloud/notify_push` | Configurações > Avançado | PATCH (tirar o link) |
| 4 | `src/gui/assistant/qml/AssistantMessageList.qml:50` | "Start a conversation with Nextcloud Assistant." | Janela do Assistente | PATCH |
| 5 | `src/gui/assistant/ocsassistantconnector.cpp:32` | system prompt "you, Nextcloud Assistant" | Resposta da IA | PATCH |
| 6 | `src/gui/application.cpp:97` | "--logdebug ... Nextcloud logging categories" | `--help` | PATCH (baixo) |
| 7 | `src/cmd/cmd.cpp:191,210` | "The base URL of the Nextcloud server" etc. | `--help` do cmd | PATCH (baixo) |
| 8 | `src/gui/urischemehandler.cpp:160` | "must use the nc://login/..." | Mensagem de erro | PATCH (baixo) |
| 9 | `logger.cpp:142,263`; `application.cpp:972`; `owncloudgui.cpp:294`; `logbrowser.cpp:113` | `nextcloud.log` | Nome do log no arquivo de debug | PATCH (médio-baixo) |
| 10 | `src/gui/advancedsettings.cpp:130` | `nextcloud-debug-archive-temp.zip` | `%TEMP%` | PATCH (baixo) |
| 11 | `src/gui/folder.cpp:1783-1784`; `csync_exclude.cpp:148,151` | `.nextcloudsync.log`, `.nextcloudpermissions.log` | Arquivos temporários na pasta sincronizada | PATCH (médio-baixo; mexer nos dois lugares) |
| 12 | `src/libsync/clientsideencryption.cpp:1983` | O=Nextcloud no CSR E2EE | Detalhes do certificado | PATCH (baixo) |

## C. Metadados de binários e instalador

| Local | Literal | Onde aparece | Ação |
|---|---|---|---|
| `shell_integration/windows/NCContextMenu/NCContextMenu.rc:70-77` | CompanyName/Copyright "Nextcloud GmbH" | Propriedades da DLL | PATCH |
| `shell_integration/windows/NCOverlays/NCOverlay.rc:83-89` | idem + "Nextcloud shell extension" | Propriedades da DLL | PATCH |
| `src/libsync/vfs/cfapi/shellext/CfApiShellIntegration.rc:37-43` | idem + "Nextcloud CfApi shell extension" | Propriedades da DLL | PATCH |
| `shell_integration/windows/NCUtil/NCUtil.rc:70-76` | idem (lib estática) | Provavelmente não chega ao binário | PATCH (precaução) |
| Nomes `NCContextMenu.dll`, `NCOverlays.dll`, `NCMsiHelper64.dll`, `NCNavRemove` | prefixo "NC" | Pasta de instalação | Manter (baixo risco; renomear mexe em CMake e WiX) |
| `admin/win/msi/*.wxs`, `OEM.wxi.in` | tudo via `$(var.App*)` | Telas do MSI e ARP | Derivado; nada a fazer |

## D. Imagens

| Local | Conteúdo | Onde aparece | Ação | Fase |
|---|---|---|---|---|
| `theme/colored/wizard_logo.{svg,png,@2x.png}` | **Logo Nextcloud** | Assistente (builds com marca) | IMG — **alto** | F3 |
| `admin/win/msi/gui/banner.bmp`, `dialog.bmp` | Logo Nextcloud | Telas do MSI | IMG — **alto** | F3 |
| `theme/colored/<ICON>-icon.svg` | precisa existir | Ícone do exe/.ico, atalhos, ARP | IMG (novo arquivo) | F3 |
| `theme/colored/icons/<ICON>-icon-win-folder.svg` | logo sobre pasta | Ícone da pasta sincronizada | IMG (novo) | F3 |
| `theme/colored/<ICON>-w10startmenu.svg` + `theme/<exe>.VisualElementsManifest.xml` | logo | Bloco do Menu Iniciar | IMG + arquivo novo | F3 |
| `theme/{colored,white,black}/state-*.svg` | estados neutros | Bandeja | IMG (símbolo Level + indicador) | F3 |
| `theme/{colored,black,white}/wizard-nextcloud.*` | Logo Nextcloud | Não exibido em builds com marca, mas embutido no binário (qrc) | IMG (substituir) | F3 |
| `theme/*/wizard-talk.*`, `talk-app.svg` | pictograma do Talk | Notificação de chamada, busca | Avaliar (opcional) | F3 |
| `admin/win/nsi/*` | bitmaps NSIS | Não usados no MSI | Ignorar | — |

## E. Traduções

- São 64 arquivos `.ts`. Só **4 textos-fonte** têm "Nextcloud" fixo: B2, B3, B4 e um obsoleto. Os demais usam `%1`.
- O `pt_BR` tem 4 ocorrências (`translations/client_pt_BR.ts:278,348,1832,4325`).
- Se o texto-fonte mudar, a tradução antiga deixa de casar e o texto volta ao inglês. Ao fazer o patch, ajustar fonte e tradução juntos.

## F. Somente interno (não trocar)

- Avisos SPDX/copyright em comentários (exigência da GPL).
- Categorias de log `nextcloud.*`.
- Namespace WebDAV `http://nextcloud.org/ns` (é protocolo).
- URI QML `com.nextcloud.desktopclient`.
- Classes e alvos CMake (`NextcloudTheme`, `nextcloudsync`…).
- Variáveis de ambiente `NEXTCLOUD_*`.
- Lógica de migração (`isBranded`, `migration.cpp`), exceto o `DISABLE_ACCOUNT_MIGRATION`.
