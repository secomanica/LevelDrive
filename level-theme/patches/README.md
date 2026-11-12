# Patches no código upstream

Patches aplicados por `level-theme/tools/apply-theme.ps1`, em ordem numérica, com `git apply`.
Só existe patch quando o mesmo resultado não se obtém pelo `NEXTCLOUD.cmake` nem pelo overlay.
Base: tag `v35.0.3`.

Para gerar ou atualizar um patch:
1. edite o arquivo upstream;
2. rode `git diff -- <arquivo> > level-theme\patches\NNNN-descricao.patch`;
3. restaure o original com `git checkout -- <arquivo>`;
4. teste com `apply-theme.ps1 -Check`.

## 0001-cmake-overridable-cfapi-guids-and-uri-scheme.patch
- **Arquivo:** `CMakeLists.txt`, linhas 38-50 na v35.0.3.
- **Problema:**
  - O AppID e os 2 CLSIDs das extensões CfApi do Explorer (estado e miniatura) são definidos com `set()` fixo no CMakeLists raiz, fora do `NEXTCLOUD.cmake`. O esquema de URI `nc` também.
  - Com os mesmos GUIDs, o Level Drive e o Nextcloud oficial na mesma máquina sobrescrevem o registro COM um do outro. A desinstalação de um apaga o do outro (`admin/win/msi/RegistryCleanup.vbs.in:55-79`).
  - Com o mesmo esquema, o MSI de um sobrescreve e, ao desinstalar, apaga `HKLM\Software\Classes\nc` (`admin/win/msi/Nextcloud.wxs:192-203`).
- **Mudança:** cada `set()` fica dentro de `if(NOT DEFINED ...)`. O padrão continua igual ao upstream, e os valores da Level são definidos em `level-theme/NEXTCLOUD.cmake`.
- **Risco:** nulo para builds sem tema.
- **Candidato a upstream:** sim.

## 0002-navigationpane-keep-official-nextcloud-entries.patch
- **Arquivo:** `src/gui/navigationpanehelper.cpp`, linha 71 na v35.0.3.
- **Problema:**
  - A cada inicialização, o cliente apaga as entradas do painel de navegação do Explorer cujo `ApplicationName` seja o nome do próprio app **ou "Nextcloud"** (`unbrandedApplicationName`, `navigationpanehelper.h:34`).
  - Num build com marca, isso remove as pastas do Nextcloud oficial do painel de navegação.
- **Mudança:** remove só as entradas com o nome do próprio app.
- **Efeito colateral:** a constante `unbrandedApplicationName` fica sem uso. Ela foi mantida para o patch continuar mínimo.
- **Risco:** a regra original servia a quem migrava de um Nextcloud sem marca para um build com marca. Não se aplica à Level.
