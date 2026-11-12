# level-theme — tema Level Drive

Toda a customização da Level fica nesta pasta. A árvore upstream do Nextcloud não é alterada nos commits:
o tema é aplicado por cima dela antes do build e removido depois.

```
level-theme/
  NEXTCLOUD.cmake        substitui o NEXTCLOUD.cmake upstream (nomes, URLs, cores, GUIDs, opções)
  patches/               patches mínimos no código upstream (documentados em patches/README.md)
  overlay/               arquivos copiados para a raiz do repo, mesma estrutura (ícones, imagens do MSI) — Fase 3
  tools/
    apply-theme.ps1      aplica (-Check verifica, -Revert desfaz)
    craft-bootstrap.ps1  prepara o KDE Craft (dependências do build)
  docs/                  análises (mapa do branding, inventário de "Nextcloud")
```

## Uso
```powershell
powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1 -Check   # o tema aplica nesta versão?
powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1          # aplica
powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1 -Revert  # volta ao upstream
```
Não commite os arquivos upstream modificados pelo tema. Commite só o que está em `level-theme/`.
