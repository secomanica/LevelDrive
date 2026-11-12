# Fase 5 — Textos, localização e créditos

Base: tag `v35.0.3`. Resolve o inventário de `fase1-inventario-nextcloud.md`. Validado com compilação completa via Craft em 2026-11-11.

## Situação de cada item do inventário

### A. Variáveis (resolvidas na Fase 2, `level-theme/NEXTCLOUD.cmake`)
- **Nomes e marca:** nome, shortname, executável, vendor, domínios e sufixo VFS são da Level. O esquema de URI é `leveldrive`.
- **URLs:** o help aponta para o site da Level (provisório). O updater está desligado.
- **Assistente:** o tema `Theme` remove a dica try.nextcloud. Os botões Sign up e Self-host estão escondidos.
- **Cores e GUIDs:** cores da Level e GUIDs próprios.

### B. Textos e URLs fixos no código
| # | Item | Resolução |
|---|---|---|
| B1 | link `github.com/nextcloud/desktop/commit` no "Sobre" | **0007**: aponta para `APPLICATION_SOURCE_URL` (<<PREENCHER>>). Vazio = revisão sem link |
| B2 | copyright Nextcloud/ownCloud no aviso legal | **Mantido** (GPL). **0007** acrescenta "Personalizações do Level Drive: Copyright 2026 Level Tecnologia" |
| — | crédito exigido pelo briefing | **0007**: "Baseado no Nextcloud Desktop Client, licenciado sob GPLv2." no painel Sobre e no aviso legal |
| B3 | link `notify_push` (Configurações › Avançado) | **0008**: texto sem link |
| B4 | "Start a conversation with Nextcloud Assistant." | **0008**: "…with the assistant." / pt-BR "Inicie uma conversa com o assistente." |
| B5 | prompt de sistema da IA "you, Nextcloud Assistant" | **0008**: "you, the assistant" |
| B6 | `--help` "Nextcloud logging categories" | **0008**: "the client logging categories" |
| B7 | `leveldrivecmd --help` (URL do servidor, issue do GitHub) | **0008** |
| B8 | mensagem "must use the nc://login" | **0008**: usa `APPLICATION_URI_HANDLER_SCHEME` (`leveldrive://`) |
| B9 | arquivo de log `nextcloud.log` | **0008**: `leveldrive.log` (5 pontos) |
| B10 | `nextcloud-debug-archive-temp.zip` | **0008**: `leveldrive-debug-archive-temp.zip` |
| B11 | `.nextcloudsync.log` / `.nextcloudpermissions.log` | **Não alterado.** São arquivos temporários ocultos, criados por instantes na pasta sincronizada para testar escrita, e estão na lista de exclusão. Renomeá-los mexe em lógica de sincronização e exclusão. |
| B12 | `O=Nextcloud` no CSR do certificado E2EE | **Não alterado.** Faz parte do protocolo de criptografia com o servidor e só é visível nos detalhes técnicos do certificado. |

### C. Metadados de binários
| Item | Resolução |
|---|---|
| NCContextMenu, NCOverlays, NCUtil, CfApiShellExtensions (`.rc`) | **0009**: CompanyName "Level Tecnologia", Product/FileDescription "Level Drive shell extension". **LegalCopyright "Nextcloud GmbH" mantido**, porque é o autor do código (aviso de copyright exigido pela GPL). |
| nomes `NC*.dll` | Mantidos (baixo risco; renomear mexe em CMake + WiX) |

### D. Imagens — resolvidas na Fase 3 (overlay)

### E. Traduções
- O patch **0010** cobre o pt-BR (`translations/client_pt_BR.ts`):
  - 2 textos-fonte alterados, com a tradução ajustada;
  - 3 textos novos traduzidos.
  - XML validado. As strings foram conferidas dentro do `client_pt_BR.qm` compilado.
- Outros idiomas: os 2 textos alterados e os 3 novos aparecem em inglês até serem traduzidos. Nenhum deles contém "Nextcloud", exceto o crédito, que é intencional.
- O build só roda o `lrelease` (`qt_add_translation`, `src/gui/CMakeLists.txt:480`). As edições nos `.ts` não são sobrescritas.

## Ocultado
- Opção "Usar ícones monocromáticos": escondida no Windows (**0003**, `Theme::monoIconsAvailable()`), porque a bandeja já segue o tema da barra.

## Textos "Nextcloud" ainda presentes nos binários, mas inalcançáveis
Conferido por varredura ASCII/UTF-16 nos `.exe`/`.dll` do build:

| Texto | Origem | Por que não aparece |
|---|---|---|
| `docs.nextcloud.com/.../installation` | `accountwizardcontroller.cpp:1020` | só via botão Self-host, escondido |
| `nextcloud.com/sign-up` | `theme.cpp` (fallback de `wizardSignupUrl`) | botão Sign up escondido |
| `try.nextcloud.com` | `nextcloudtheme.cpp:30` | classe compilada mas não usada (`THEME_CLASS = Theme`) |
| `nextcloud.log` | `logger.cpp:69` | categoria de log interna `nextcloud.log.permanent` |

Na Fase 7, conferir na interface real (inglês e pt-BR) que nada disso aparece.

## Consequências a acompanhar
- **Página de conflitos:** `Theme::conflictHelpUrl()` (`APPLICATION_HELP_URL + "conflicts.html"`) existe, mas nenhuma tela a usa em v35 (revisto em 2026-11-12). Não é preciso publicar `conflicts.html`. Conferir de novo a cada atualização do upstream.
- **Instalador MSI:** os textos do instalador e a tradução pt-BR ficam para a Fase 6. O upstream só tem en/de/fr/it/es.
