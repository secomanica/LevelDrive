# Fase 7 — Validação (2026-11-12)

Ambiente: Windows Server 2019 (build 17763, aparência equivalente ao Windows 10 1809), sessão RDP em 1920×1080 a 100%,
idioma pt-BR. MSI testado: `LevelDrive-35.0.3.0-x64.msi`, build do commit `4e69d42644`, não assinado.
Nextcloud oficial 35.0.3 (MSI do GitHub, assinatura válida da Nextcloud GmbH) instalado ao lado.

## Resultado do checklist

| Item | Resultado | Como foi verificado |
|---|---|---|
| Instala ao lado do Nextcloud oficial | OK | Nextcloud instalado primeiro, depois o Level Drive (com interface e em modo silencioso). Pastas, chaves de registro, CLSIDs, overlays e URI schemes (`nc://` × `leveldrive://`) são distintos (diff de retratos do registro e das pastas). |
| Desinstalar um não quebra o outro | OK | Após desinstalar o Level Drive, `C:\Program Files\Nextcloud\nextcloud.exe` e o `nc://` continuam intactos. |
| Desinstalação limpa | OK, com ressalva | Saem os arquivos, o registro HKLM, os CLSIDs, os atalhos e o `leveldrive://`. Ficam: `%APPDATA%\Level Drive` e `%LOCALAPPDATA%\Level Drive` (dados do usuário, igual ao Nextcloud) e o valor `HKCU\...\Run\LevelDrive`, criado pelo app e não pelo MSI. O instalador do Nextcloud também não remove esse valor. Ver melhoria opcional abaixo. |
| Instalador em pt-BR e com a marca | OK | Telas de boas-vindas, instalação personalizada, pronto e concluído em pt-BR, com as imagens da Level e "Abrir o Level Drive". |
| Nenhum "Nextcloud" visível como produto | OK | Assistente, menu da bandeja, Configurações, Informação e instalador. "Nextcloud" aparece só onde deve: crédito GPL ("Baseado no Nextcloud Desktop Client…") e copyright no Aviso legal. |
| Lista de servidores | OK | O assistente mostra "Level Drive", "Level Drive 2" e "Level Drive 3", sem campo de URL livre. Os três servidores respondem ao `status.php` (Nextcloud 30.0.15, 32.0.15 e 34.0.4; o cliente aceita a partir do 20). |
| Contraste e cores | OK (após 0013) | Botão primário: texto `#103B40` sobre `#53AE93` (amostrado em pixel). A seleção da lista de servidores usa `#103B40`. Nas Configurações, o azul do Windows foi trocado pelas cores da marca (patch 0013). |
| Modo escuro | OK | Assistente com fundo `#222323`, título `#83C8B4` e botão verde com texto `#103B40`. Nas Configurações, o item selecionado era ilegível no escuro, corrigido no 0013: fundo menta e texto/ícone `#103B40`. **A correção foi compilada e instalada, mas não fotografada no modo escuro.** |
| Bandeja legível | OK na barra escura | O Server 2019 só tem barra escura, então o app usa o conjunto `white/` (camada de cima clara). A barra clara (`black/`) não dá para testar aqui, porque o `SystemUsesLightTheme` só existe a partir do Windows 10 1903. |
| Ícones nítidos | OK em 100% | As camadas do `.ico` (16/24/32/48/64/128 + 1024 PNG) estão nítidas e proporcionais, com a mesma estrutura do `.ico` oficial do Nextcloud. Escala real de 150%/200% não foi testada (exige logoff/DPI por sessão RDP). |
| Fonte e serifa | Parcial | Sem Aptos no Server 2019, o fallback Segoe UI funciona. A serifa do título usa Georgia, porque Century Schoolbook não está instalada; o título aparece com serifa. A Aptos de verdade só no Windows 11 / Office. |
| pt-BR no app | OK (após 0012) | Antes do 0012 o app carregava `client_pt.qm` (Portugal) por causa do `pt_Latn_BR` do Qt 6.11. Agora o log mostra `selected application language: "pt_BR"` e o crédito aparece em pt-BR. |
| Sobre / Aviso legal | OK | "Versão do cliente de desktop Level Drive 35.0.3", "Baseado no Nextcloud Desktop Client, licenciado sob GPLv2.", "Personalizações do Level Drive: Copyright 2026 Level Tecnologia", com os copyrights do Nextcloud GmbH e do ownCloud GmbH mantidos. |
| Login e sincronização num servidor Level | OK (usuário, 2026-11-12) | O usuário conectou uma conta em `https://leveldrive.com.br`, escolhida na lista. Com a conta: ícone da bandeja sem o selo de desconectado; menu da bandeja "Abrir Level Drive Desktop / Pausar sincronização / Configurações / Ajuda / Sair do Level Drive"; pasta `C:\Users\<usuário>\LevelDrive`; entrada **"Level Drive" com o ícone da Level no painel de navegação do Explorer**; arquivos com os ícones de status da nuvem (arquivos virtuais / CfApi). Não verificados à parte: o menu de contexto do Explorer e os servidores drv2/drv3. |
| Windows 10/11 reais, escala 150/200% | **Pendente** | Testar numa estação. |

## Defeitos encontrados e corrigidos nesta fase
- **0012:** o idioma pt-BR carregava a tradução de Portugal (defeito do upstream com Qt 6.11; afeta também o cliente oficial).
- **0013:** as Configurações usavam o azul do Windows e, no modo escuro, a engrenagem ficava ilegível.

## Observações para a Level
- **Texto do assistente:** "Insira o link para o sua interface web…" é a tradução pt-BR do upstream, com erro de concordância. Com a lista fixa, o texto também fala de "link" sem haver campo para digitar. Pode ser ajustado num patch de tradução, se a Level quiser.
- **Servidores:** o `status.php` dos três responde `productname=Nextcloud`. O nome e a cor que aparecem na página de login no navegador vêm do app **Theming** de cada servidor. Configure nome "Level Drive" e cor `#103B40` nos três.
- **Melhoria opcional:** remover o `HKCU\...\Run\LevelDrive` na desinstalação. Seria um patch no `RegistryCleanup.vbs.in`, e só vale para o usuário que desinstala.
- **Opção B (servidor escolhido no instalador):** ficou para depois, conforme a decisão do usuário.
