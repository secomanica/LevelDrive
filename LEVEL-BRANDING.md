# LEVEL-BRANDING.md — Level Drive

Cliente desktop **Level Drive**, da Level Tecnologia: white-label do [Nextcloud Desktop Client](https://github.com/nextcloud/desktop),
licenciado sob GPLv2. Alvo: Windows x64, instalador MSI.

Este documento explica como a marca é aplicada, como gerar o instalador, como atualizar para uma nova versão do Nextcloud
e o que ainda falta preencher. Detalhes técnicos, decisões e armadilhas estão em [`CLAUDE.md`](CLAUDE.md).
Os patches estão documentados um a um em [`level-theme/patches/README.md`](level-theme/patches/README.md).

## Como a marca é aplicada

A árvore do Nextcloud fica **intacta** nos commits. Toda a customização está em `level-theme/` e é aplicada só na hora do build:

| Parte | O que faz |
|---|---|
| `level-theme/NEXTCLOUD.cmake` | Substitui o `NEXTCLOUD.cmake` do upstream. Define nome, fabricante, domínio, executável, URI `leveldrive://`, lista de servidores, cores do assistente, GUIDs próprios (convivência com o Nextcloud oficial) e opções (updater desligado, sem "Sign up"/"Self-host"). |
| `level-theme/patches/0001–0013` | Patches mínimos no código, cada um justificado no README dos patches: bandeja, cores e fontes, créditos GPL, textos, pt-BR, instalador, idioma e Configurações. |
| `level-theme/overlay/` | Ícones, estados, logo do assistente e imagens do MSI, **gerados** por `build-icons.ps1` a partir dos SVGs oficiais em `..\level-brand\`. Não editar à mão. |
| `level-theme/tools/` | Scripts reprodutíveis: tema, ícones, Craft, MSI, assinatura e contraste. |

Regras de marca seguidas:
- os logos não são redesenhados nem recoloridos; os `<path>` são copiados verbatim e só redimensionados ou convertidos;
- as fontes Aptos e Century Schoolbook são usadas só pelo nome, com fallback para Segoe UI/Arial e Georgia, e **nenhum arquivo de fonte é empacotado**;
- contraste ≥ 4,5:1 conferido por `check-contrast.py`;
- texto sobre o verde `#53AE93` é sempre `#103B40`.

Obrigações legais (GPL):
- os avisos de copyright do Nextcloud e do ownCloud estão mantidos;
- o "Sobre" e o "Aviso legal" mostram "Baseado no Nextcloud Desktop Client, licenciado sob GPLv2." e "Personalizações do Level Drive: Copyright 2026 Level Tecnologia";
- o código-fonte está publicado em **https://github.com/secomanica/LevelDrive**, que o "Sobre" do app indica. A revisão Git do "Sobre" aponta para o commit exato do build, então **envie (push) o commit antes de distribuir um build**.

## Gerar o instalador

Pré-requisitos: ambiente da Fase 0 e bootstrap do Craft, descritos no `CLAUDE.md`. Na raiz do repositório:

```powershell
# 0. Commite antes: a "Git revision" mostrada no instalador e no "Sobre" é o HEAD do momento do build
powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1
powershell -ExecutionPolicy Bypass -File level-theme\tools\craft-build.ps1 -Stage "configure,compile,install,qmerge,package" -BuildType Release
powershell -ExecutionPolicy Bypass -File level-theme\tools\build-msi.ps1          # -Sign quando houver certificado
powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1 -Revert
```

Saída: `level-theme\build\out\LevelDrive-<versão>-x64.msi`, com interface em inglês e transforms embutidos para pt-BR, de, fr, it e es.
O Windows escolhe o idioma automaticamente.

Instalação silenciosa: `msiexec /i LevelDrive-<versão>-x64.msi /qn`. As propriedades do MSI upstream continuam valendo, por exemplo `LAUNCH=0` e `NO_SHELL_EXTENSIONS=1`.

## Atualizar para uma nova versão do Nextcloud

1. **Escolha a tag** estável nova (`git fetch origin --tags`; neste clone, `origin` é o github.com/nextcloud/desktop. Se o fork Level virar `origin`, adicione o Nextcloud como `upstream`) e leia o changelog. Atenção especial a mudanças em
   `NEXTCLOUD.cmake`, `src/libsync/theme.*`, `theme/Style/Style.qml`, `src/gui/wizard/`, `admin/win/msi/` e `translations/client_pt_BR.ts`.
2. **Crie a branch nova** a partir da tag e traga a pasta da Level:
   ```powershell
   git checkout -b level/branding-<versão> v<versão>
   git checkout level/branding -- level-theme LEVEL-BRANDING.md CLAUDE.md
   ```
3. **Compare o `NEXTCLOUD.cmake`** do upstream novo com o da Level: `git diff v35.0.3 v<versão> -- NEXTCLOUD.cmake`.
   Variáveis novas no upstream precisam ser acrescentadas em `level-theme/NEXTCLOUD.cmake`, com valor Level ou copiando o padrão.
4. **Confira os patches:** `apply-theme.ps1 -Check`. Para cada patch que não aplicar:
   - aplique à mão o equivalente no arquivo novo (o README dos patches diz o objetivo de cada um);
   - regenere com `git diff -- <arquivo> > level-theme\patches\NNNN-....patch`; o 0009 usa `--binary`;
   - restaure com `git checkout -- <arquivo>`.

   Se o upstream passou a oferecer o recurso de forma nativa, apague o patch e registre isso no README.
5. **Aplique o tema completo** sem `-Check`, porque patches que tocam o mesmo arquivo só são validados em sequência, e compile.
6. **Confira o que pode ter mudado de lugar:**
   - procure "Nextcloud" visível em textos novos (`level-theme/docs/fase1-inventario-nextcloud.md` tem o método);
   - confira se o `Theme::conflictHelpUrl()` passou a ser usado; se sim, publique `conflicts.html` no site de ajuda;
   - confira se o defeito de idioma do 0012 foi corrigido no upstream;
   - confira se o blueprint do Craft ainda tem os dois defeitos contornados no `craft-build.ps1` e no `build-msi.ps1` (veja Armadilhas no `CLAUDE.md`).
7. **Traduções:** strings novas ou alteradas pelos patches precisam de entrada em `client_pt_BR.ts` (patch 0010).
8. **Valide** com o checklist de `level-theme/docs/fase7-validacao.md`.
9. **Nunca mude**:
   - o `UpgradeCode` do MSI nem os GUIDs de `level-theme/NEXTCLOUD.cmake`, porque a atualização sobre a versão anterior e a convivência com o Nextcloud dependem deles;
   - o `SHORTNAME`, o `APPLICATION_REV_DOMAIN` nem o esquema `leveldrive://`, depois do primeiro release.

Para trocar logos, atualize `..\level-brand\` com os hashes do `SOURCE.md` e rode `build-icons.ps1`.

## Pendências (placeholders `<<PREENCHER>>`)

| Pendência | Onde | Impacto |
|---|---|---|
| Confirmar nomes exibidos dos servidores ("Level Drive", "Level Drive 2", "Level Drive 3") | `level-theme/NEXTCLOUD.cmake` (`APPLICATION_SERVER_URL`) | É o que o usuário vê na lista. As URLs já estão definidas. |
| Assinatura de código: instalar o **SSL.com eSigner CKA** na máquina de build e definir `LEVEL_SIGN_THUMBPRINT` | `level-theme/tools/sign-level.ps1` (carimbo `http://ts.ssl.com`) | Sem assinatura, o Windows SmartScreen alerta na instalação. `build-msi.ps1 -Sign` assina os `.exe`/`.dll` (todos, ou só os da Level com `-SignScope Level`) e o `.msi`. |
| URL do servidor de atualização | `APPLICATION_UPDATE_URL` + `BUILD_UPDATER ON` | O updater está desligado até existir o servidor. |
| Usuário de teste num servidor Level | validação | Testar login, sincronização, menu de contexto, overlays e arquivos virtuais. |
| Confirmar cores dos indicadores de estado (erro `#C8423B`/`#E0645C`, aviso `#E0A526`, pausa `#5B5C5C`/`#B6B6B6`) | `level-theme/tools/build-icons.ps1` | Cores propostas, fora da paleta oficial. |
| Testar em Windows 10 e 11 reais, com escala 150%/200% e barra clara | validação | O Server 2019 não cobre isso. |

Recomendações fora do cliente:
- nos três servidores, configurar o app **Theming** com nome "Level Drive" e cor `#103B40`; o cliente e a página de login usam esses valores;
- opcionalmente, ajustar o texto pt-BR do assistente e remover a entrada "iniciar com o Windows" na desinstalação (ver `fase7-validacao.md`).
