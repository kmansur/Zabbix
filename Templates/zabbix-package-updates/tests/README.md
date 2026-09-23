# Testes

Execute:

```bash
./tests/test_core.sh
```

Os testes atuais validam:

- sintaxe Bash do coletor;
- escape básico de JSON;
- normalização de valores booleanos;
- ausência de `eval`, `sh -c` e `bash -c`;
- ausência de `system.run`;
- ausência de comandos de instalação, remoção ou upgrade no coletor de monitoramento.

Os testes automatizados não substituem a validação em distribuições reais.

Antes de uma release estável, o projeto deverá ampliar a cobertura com fixtures e ambientes reais para APT, DNF/DNF5, erros de repositório, timeouts, locks e diferentes formatos de saída dos gerenciadores de pacotes.
