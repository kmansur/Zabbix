# Testes

Execute:

```bash
./tests/test_parsers.sh
```

Os testes atuais validam parsers com comandos simulados para:

- APT;
- DNF5;
- escape básico de JSON.

Os testes não substituem validação em distribuições reais.

Antes de uma release estável, o projeto deverá incluir cenários adicionais para DNF, YUM, erros de repositório, timeouts, locks e retornos incompletos.
