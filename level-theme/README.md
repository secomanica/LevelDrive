# level-theme — tema Level Drive

Toda a customização da Level fica nesta pasta. A árvore upstream do Nextcloud não é alterada nos commits:
o tema é aplicado por cima dela antes do build e removido depois.

```
level-theme/
  NEXTCLOUD.cmake        substitui o NEXTCLOUD.cmake upstream (nomes, URLs, cores, GUIDs, opções)
  patches/               patches mínimos no código upstream (documentados em patches/README.md)
  overlay/               GERADO por build-icons.ps1 (não editar à mão): ícones, estados, logo do assistente,
                         imagens do MSI, VisualElementsManifest — copiado para a raiz do repo
  tools/
    build-icons.ps1      gera overlay/ a partir de ..\level-brand\ (confere os hashes do SOURCE.md antes)
    apply-theme.ps1      aplica (-Check verifica, -Revert desfaz)
    craft-bootstrap.ps1  prepara o KDE Craft (dependências do build)
    craft-build.ps1      roda etapas do Craft sobre este repo (-Stage "configure,compile,install,qmerge,package")
    build-msi.ps1        monta a pasta do app e gera o MSI (make-msi.bat do upstream); -Sign assina
    sign-level.ps1       assinatura Authenticode (preparada; requer certificado <<PREENCHER>>)
    check-contrast.py    confere o contraste WCAG dos pares de cor do tema
  craft/level-overrides.ini  override do craftmaster.ini (pacote portátil em vez de NSIS)
  docs/                  análises (mapa do branding, inventário de "Nextcloud")
```

## Uso
```powershell
powershell -ExecutionPolicy Bypass -File level-theme\tools\build-icons.ps1          # (re)gera overlay/ após mudar logos
powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1 -Check   # o tema aplica nesta versão?
powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1          # aplica
powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1 -Revert  # volta ao upstream
```
Não commite os arquivos upstream modificados pelo tema. Commite só o que está em `level-theme/`.
