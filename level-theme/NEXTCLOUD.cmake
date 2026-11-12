# SPDX-FileCopyrightText: 2017 Nextcloud GmbH and Nextcloud contributors
# SPDX-FileCopyrightText: 2012 ownCloud GmbH
# SPDX-FileCopyrightText: 2026 Level Tecnologia
# SPDX-License-Identifier: GPL-2.0-or-later
#
# ---------------------------------------------------------------------------
# LEVEL DRIVE — tema da Level Tecnologia.
# Este arquivo SUBSTITUI o NEXTCLOUD.cmake upstream (copiado por level-theme/tools/apply-theme.ps1).
# Base: NEXTCLOUD.cmake da tag v35.0.3. Ao atualizar o upstream, compare com o original
# (git diff <tag-antiga> <tag-nova> -- NEXTCLOUD.cmake) e traga as mudanças de lógica para cá.
# Valores marcados com <<PREENCHER: ...>> são provisórios e precisam de confirmação da Level.
# ---------------------------------------------------------------------------
#
# keep the application name and short name the same or different for dev and prod build
# or some migration logic will behave differently for each build
if(NEXTCLOUD_DEV)
    set( APPLICATION_NAME       "Level Drive Dev" )
    set( APPLICATION_SHORTNAME  "LevelDriveDev" )
    set( APPLICATION_EXECUTABLE "leveldrivedev" )
    set( APPLICATION_ICON_NAME  "LevelDrive" )
else()
    set( APPLICATION_NAME       "Level Drive" )      # nome exibido (aprovado)
    set( APPLICATION_SHORTNAME  "LevelDrive" )       # <<PREENCHER: confirmar>> %APPDATA%\LevelDrive, nome do MSI, chave Run
    set( APPLICATION_EXECUTABLE "leveldrive" )       # <<PREENCHER: confirmar>> leveldrive.exe, named pipe, DLLs
    set( APPLICATION_ICON_NAME  "${APPLICATION_SHORTNAME}" )  # theme/colored/LevelDrive-icon.svg (Fase 3)
endif()

set( APPLICATION_CONFIG_NAME "${APPLICATION_EXECUTABLE}" )
set( APPLICATION_DOMAIN     "leveltecnologia.com.br" )  # <<PREENCHER: confirmar>> links do "Adicionar/Remover Programas"
set( APPLICATION_VENDOR     "Level Tecnologia" )
# Updater DESLIGADO por enquanto (BUILD_UPDATER OFF abaixo). A URL não pode ficar vazia (theme.cpp:610
# usa a macro direto); host "." faz Updater::updateUrl() devolver URL inválida (updater.cpp:56).
# <<PREENCHER: URL do servidor de atualização da Level>> quando existir, e religar BUILD_UPDATER.
set( APPLICATION_UPDATE_URL "https://./" CACHE STRING "URL for updater" )
# URL pública do código-fonte deste fork (exigência da GPL). Vazio = o "Sobre" mostra o crédito sem link
# e a revisão Git aparece sem link (patch 0007). <<PREENCHER: URL pública do repositório do fork Level Drive>>
set( APPLICATION_SOURCE_URL "" CACHE STRING "Public URL of this client's source code (GPL)" )
# Não pode ficar vazio: vazio vira fallback para docs.nextcloud.com (theme.cpp:495-499).
set( APPLICATION_HELP_URL   "https://leveltecnologia.com.br/" CACHE STRING "URL for the help menu" )  # <<PREENCHER: site/suporte da Level>>

# Bloco macOS simplificado (o upstream escolhe o ícone "Nextcloud-macOS"/Icon Composer só para builds
# "Nextcloud"; em builds de marca cai sempre no pipeline legado .icns). Não afeta o Windows.
if(APPLE)
    execute_process(COMMAND sw_vers -productVersion
        OUTPUT_VARIABLE _macos_product_version RESULT_VARIABLE _macos_ver_result
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
    execute_process(COMMAND xcodebuild -version
        OUTPUT_VARIABLE _xcodebuild_version_raw RESULT_VARIABLE _xcode_ver_result
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

    set(MACOS_ICON_COMPOSER_TOOLCHAIN_SUPPORTED OFF)
    if(_macos_ver_result EQUAL 0 AND _xcode_ver_result EQUAL 0)
        string(REGEX MATCH "Xcode ([0-9]+\\.[0-9]+)" _ "${_xcodebuild_version_raw}")
        set(_xcode_version "${CMAKE_MATCH_1}")
        if(_macos_product_version VERSION_GREATER_EQUAL "26.5"
           AND _xcode_version VERSION_GREATER_EQUAL "26.5")
            set(MACOS_ICON_COMPOSER_TOOLCHAIN_SUPPORTED ON)
        endif()
    endif()
    if(NOT DEFINED MACOS_USE_ICON_COMPOSER)
        set(MACOS_USE_ICON_COMPOSER OFF)
    endif()
endif()

set( APPLICATION_ICON_SET   "SVG" )
# <<PREENCHER: URL do servidor Level>>. Vazio = usuário digita a URL no assistente.
# Se preenchido, com ENFORCE ON o cliente só conecta nesse servidor.
set( APPLICATION_SERVER_URL "" CACHE STRING "URL for the server to use. If entered, the UI field will be pre-filled with it" )
set( APPLICATION_SERVER_URL_ENFORCE ON ) # If set and APPLICATION_SERVER_URL is defined, the server can only connect to the pre-defined URL
set( APPLICATION_REV_DOMAIN "br.com.leveltecnologia.drive" )       # <<PREENCHER: confirmar>>
set( APPLICATION_REV_DOMAIN_DBUS "drive.leveltecnologia.com.br" )  # <<PREENCHER: confirmar>> (só Linux)
set( DEVELOPMENT_TEAM "" CACHE STRING "Apple Development Team ID" )  # só macOS; Team ID do Nextcloud removido
set( APPLICATION_VIRTUALFILE_SUFFIX "leveldrive" CACHE STRING "Virtual file suffix (not including the .)")
set( APPLICATION_OCSP_STAPLING_ENABLED OFF )
set( APPLICATION_FORBID_BAD_SSL OFF )

# Esquema de URI próprio (decisão aprovada: trocar o "nc://" para não conflitar com o Nextcloud oficial).
# Consequência: o "Abrir localmente" do servidor Nextcloud (que gera links nc://) não abre o Level Drive.
# Requer o patch 0001 (CMakeLists.txt passa a respeitar valores definidos aqui).
set( APPLICATION_URI_HANDLER_SCHEME "leveldrive" )

set( LINUX_PACKAGE_SHORTNAME "leveldrive" )
set( LINUX_APPLICATION_ID "${APPLICATION_REV_DOMAIN}.${LINUX_PACKAGE_SHORTNAME}")
if(LINUX)
    set( APPLICATION_ICON_NAME "${LINUX_APPLICATION_ID}" )
endif()

# Classe base: sem a dica "try.nextcloud.com" do NextcloudTheme (nextcloudtheme.cpp:30).
set( THEME_CLASS            "Theme" )
set( WIN_SETUP_BITMAP_PATH  "${CMAKE_SOURCE_DIR}/admin/win/nsi" )

set( MAC_INSTALLER_BACKGROUND_FILE "${CMAKE_SOURCE_DIR}/admin/osx/installer-background.png" CACHE STRING "The MacOSX installer background image")

## Updater options — DESLIGADO até a Level ter servidor de atualização (decisão de 2026-11-11)
set( BUILD_UPDATER OFF )

option( WITH_PROVIDERS "Build with providers list" ON )

option( ENFORCE_VIRTUAL_FILES_SYNC_FOLDER "Enforce use of virtual files sync folder when available" OFF )
option( DISABLE_VIRTUAL_FILES_SYNC_FOLDER "Disable use of virtual files sync folder even when available" OFF )

option(ENFORCE_SINGLE_ACCOUNT "Enforce use of a single account in desktop client" OFF)

option( DO_NOT_USE_PROXY "Do not use system wide proxy, instead always do a direct connection to server" OFF )

option( WIN_DISABLE_USERNAME_PREFILL "Do not prefill the Windows user name when creating a new account" OFF )

## Opções do CMakeLists.txt raiz, fixadas aqui (este arquivo é incluído antes delas, CMakeLists.txt:30;
## com a policy CMP0077 NEW, option() não sobrescreve variável já definida)
# Não importar contas/configuração de um Nextcloud oficial instalado (migration.cpp:21-22,156-160)
set( DISABLE_ACCOUNT_MIGRATION ON )
set( APPLICATION_DISPLAY_LEGACY_IMPORT_DIALOG OFF )
# Botões do assistente que levam a nextcloud.com / docs.nextcloud.com
set( WIZARD_HIDE_SELF_HOST_BUTTON ON )
set( WIZARD_HIDE_SIGNUP_BUTTON ON )

## Theming options — tokens do design system Level
set( NEXTCLOUD_BACKGROUND_COLOR "#103B40" CACHE STRING "Default background color (Level brand-teal)")
set( APPLICATION_WIZARD_HEADER_BACKGROUND_COLOR ${NEXTCLOUD_BACKGROUND_COLOR} CACHE STRING "Hex color of the wizard header background")
set( APPLICATION_WIZARD_HEADER_TITLE_COLOR "#EFEFEF" CACHE STRING "Hex color of the text in the wizard header")
# Manter ON: o ramo OFF tem erro de sintaxe no upstream (theme.cpp:853)
option( APPLICATION_WIZARD_USE_CUSTOM_LOGO "Use the logo from ':/client/theme/colored/wizard_logo.(png|svg)' else the default application icon is used" ON )

#
## Windows Shell Extensions & MSI — GUIDs PRÓPRIOS da Level (gerados em 2026-11-11).
## NUNCA reutilizar os do Nextcloud: colidiriam com o cliente oficial na mesma máquina.
## NUNCA mudar depois do primeiro release: o UpgradeCode identifica o produto para upgrades do MSI.
#
if(WIN32)
    # Context Menu
    set( WIN_SHELLEXT_CONTEXT_MENU_GUID      "{5BAA57AE-0497-4C4F-B697-FB9668C4E8D3}" )

    # Overlays
    set( WIN_SHELLEXT_OVERLAY_GUID_ERROR     "{DA2E67B5-070E-46BA-B323-F3BB54CD2D1B}" )
    set( WIN_SHELLEXT_OVERLAY_GUID_OK        "{DFD9B021-4ACB-453F-A111-9B203FBED8E6}" )
    set( WIN_SHELLEXT_OVERLAY_GUID_OK_SHARED "{72C429FE-A5E2-4D46-9FD5-84B7348837DD}" )
    set( WIN_SHELLEXT_OVERLAY_GUID_SYNC      "{EC893666-DBE0-436E-A28E-9D6FBA16571F}" )
    set( WIN_SHELLEXT_OVERLAY_GUID_WARNING   "{E81733FA-6185-41CB-A6C8-C92F6042256B}" )

    # MSI Upgrade Code (without brackets)
    set( WIN_MSI_UPGRADE_CODE                "8D1FD560-ACD1-42EE-A9B9-A01BDAB7F3DA" )

    # CfApi Shell Extensions (usados pelo CMakeLists.txt raiz via patch 0001)
    set( CFAPI_SHELLEXT_APPID_REG "{48459866-343A-4A4D-875B-2A5CC3027E8D}" )
    set( CFAPI_SHELLEXT_CUSTOM_STATE_HANDLER_CLASS_ID "0C2AC5BF-D36E-4784-A99B-91150C46B1C3" )
    set( CFAPI_SHELLEXT_THUMBNAIL_HANDLER_CLASS_ID "69EEA980-DD83-4E51-A108-88739291B077" )

    # Windows build options — MSI ligado (instalador final da Level é MSI)
    set( BUILD_WIN_MSI ON )
    option( BUILD_WIN_TOOLS "Build Win32 migration tools" OFF )
endif()

if (APPLE AND CMAKE_OSX_DEPLOYMENT_TARGET VERSION_GREATER_EQUAL 11.0)
    option( BUILD_FILE_PROVIDER_MODULE "Build the macOS virtual files File Provider module" OFF )
endif()
