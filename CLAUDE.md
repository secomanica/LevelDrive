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
# roda "craft craft" e "craft --install-deps nextcloud-client".
```

## Decisões
- **Nome do produto:** Level Drive. Vendor: Level Tecnologia.
- **Instalador:** MSI (WiX v3, fontes em `admin/win/msi`). O Craft gera NSIS por padrão. O MSI é feito com `BUILD_WIN_MSI=ON` + `make-msi.bat`.
- **Logos:** mantêm as cores dos próprios SVGs. Os tokens do design system valem só para a interface (ver o HANDOFF em `level-brand`).
- **Fontes:** Aptos/Century Schoolbook pelo nome de família, com fallback. Nenhum arquivo de fonte é empacotado.
- **Mecanismo de tema:** `OEM_THEME_DIR` **não existe** na v35.0.3 (ver `level-theme/docs/fase1-mapa-branding.md`). Abordagem proposta em revisão (Fase 2).

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
- **`APPLICATION_WIZARD_USE_CUSTOM_LOGO`:** não desligar. O ramo `#else` tem erro de sintaxe (`theme.cpp:853`).

## Pendências / placeholders
- `<<PREENCHER: SHORTNAME/EXECUTABLE>>` (sugestão: `leveldrive`)
- `<<PREENCHER: APPLICATION_DOMAIN / REV_DOMAIN>>`
- `<<PREENCHER: APPLICATION_SERVER_URL>>` (fixo ou não)
- `<<PREENCHER: URL de update>>` ou desabilitar o updater
- `<<PREENCHER: site/suporte (HELP_URL, ARP)>>`
- `<<PREENCHER: URL de homologação>>`
- `<<PREENCHER: certificado de assinatura de código>>`
- `<<PREENCHER: URL pública do código-fonte do fork>>` (GPL; usada no "Sobre")
- **DECISÃO:** manter ou trocar o esquema de URI `nc://`.

## Status das fases
| Fase | Status |
|---|---|
| 0 Ambiente | Concluída (2026-11-11) |
| 1 Clone e análise | Concluída (2026-11-11) |
| 2–7 | Não iniciadas |
